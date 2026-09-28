import { Router, Request, Response } from 'express';
import { Prisma, Role, PricingUnit } from '@prisma/client';
import { prisma } from '../config/prisma.js';
import { hashPassword, comparePassword } from '../services/passwordService.js';
import { signToken } from '../services/tokenService.js';
import { authGuard } from '../middleware/authGuard.js';

const router = Router();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Shape of the user object returned to the client (never includes the hash). */
function toPublicUser(user: {
  id: number;
  email: string;
  name: string;
  phone: string | null;
  role: Role;
}) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    phone: user.phone,
    role: user.role,
  };
}

function isNonEmptyString(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

function toFiniteNumber(v: unknown): number | null {
  const n = typeof v === 'number' ? v : parseFloat(String(v));
  return Number.isFinite(n) ? n : null;
}

// ---------------------------------------------------------------------------
// POST /api/auth/register  (role-branched)
// ---------------------------------------------------------------------------
router.post('/register', async (req: Request, res: Response) => {
  try {
    const { role, name, email, phone, password } = req.body ?? {};

    // Common required fields for every role.
    if (!isNonEmptyString(role)) {
      return res.status(400).json({ error: 'role is required.' });
    }
    const normalizedRole = String(role).toUpperCase();
    if (!Object.values(Role).includes(normalizedRole as Role)) {
      return res.status(400).json({
        error: `Invalid role. Must be one of: ${Object.values(Role).join(', ')}`,
      });
    }
    if (!isNonEmptyString(name)) {
      return res.status(400).json({ error: 'name is required.' });
    }
    if (!isNonEmptyString(email) || !EMAIL_RE.test(email.trim())) {
      return res.status(400).json({ error: 'A valid email is required.' });
    }
    if (!isNonEmptyString(phone)) {
      return res.status(400).json({ error: 'phone is required.' });
    }
    if (!isNonEmptyString(password) || password.length < 6) {
      return res.status(400).json({ error: 'password must be at least 6 characters.' });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Reject duplicate email up front (also guarded by the unique constraint).
    const existing = await prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }

    const passwordHash = await hashPassword(password);
    const roleEnum = normalizedRole as Role;

    // Build the base user data shared by all roles.
    const baseUser = {
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      passwordHash,
      role: roleEnum,
    };

    // ------------------------------------------------------------------
    // PARTNER: create User + Laundromat atomically.
    // ------------------------------------------------------------------
    if (roleEnum === Role.PARTNER) {
      const { businessName, businessAddress, latitude, longitude, pricingModel, specialties } =
        req.body ?? {};

      if (!isNonEmptyString(businessName)) {
        return res.status(400).json({ error: 'businessName is required for partners.' });
      }
      if (!isNonEmptyString(businessAddress)) {
        return res.status(400).json({ error: 'businessAddress is required for partners.' });
      }
      const lat = toFiniteNumber(latitude);
      const lng = toFiniteNumber(longitude);
      if (lat === null || lng === null) {
        return res
          .status(400)
          .json({ error: 'Valid latitude and longitude are required for partners.' });
      }
      const pricing = String(pricingModel ?? '').toUpperCase();
      if (!Object.values(PricingUnit).includes(pricing as PricingUnit)) {
        return res.status(400).json({
          error: `pricingModel must be one of: ${Object.values(PricingUnit).join(', ')}`,
        });
      }

      // specialties: accept an array of tag names or a comma-separated string.
      let specialtyList: string[] = [];
      if (Array.isArray(specialties)) {
        specialtyList = specialties.map((s) => String(s).trim().toLowerCase()).filter(Boolean);
      } else if (isNonEmptyString(specialties)) {
        specialtyList = specialties
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .filter(Boolean);
      }

      const created = await prisma.$transaction(async (tx) => {
        const user = await tx.user.create({ data: baseUser });

        const laundromat = await tx.laundromat.create({
          data: {
            name: businessName.trim(),
            address: businessAddress.trim(),
            latitude: lat,
            longitude: lng,
            ownerId: user.id,
          },
        });

        // Attach specialty tags (create tags on demand, connect via join table).
        for (const tagName of specialtyList) {
          const tag = await tx.tag.upsert({
            where: { name: tagName },
            update: {},
            create: { name: tagName },
          });
          await tx.laundromatsOnTags.create({
            data: { laundromatId: laundromat.id, tagId: tag.id },
          });
        }

        return user;
      });

      const token = signToken({ id: created.id, role: created.role });
      return res.status(201).json({ token, user: toPublicUser(created) });
    }

    // ------------------------------------------------------------------
    // DRIVER: create User + DriverProfile atomically.
    // ------------------------------------------------------------------
    if (roleEnum === Role.DRIVER) {
      const { vehicleType, plateNumber } = req.body ?? {};

      if (!isNonEmptyString(vehicleType)) {
        return res.status(400).json({ error: 'vehicleType is required for drivers.' });
      }
      if (!isNonEmptyString(plateNumber)) {
        return res.status(400).json({ error: 'plateNumber is required for drivers.' });
      }

      const created = await prisma.$transaction(async (tx) => {
        const user = await tx.user.create({ data: baseUser });
        await tx.driverProfile.create({
          data: {
            userId: user.id,
            vehicleType: vehicleType.trim(),
            plateNumber: plateNumber.trim(),
          },
        });
        return user;
      });

      const token = signToken({ id: created.id, role: created.role });
      return res.status(201).json({ token, user: toPublicUser(created) });
    }

    // ------------------------------------------------------------------
    // CUSTOMER: just the User.
    // ------------------------------------------------------------------
    const user = await prisma.user.create({ data: baseUser });
    const token = signToken({ id: user.id, role: user.role });
    return res.status(201).json({ token, user: toPublicUser(user) });
  } catch (error: unknown) {
    // Unique constraint safety net (e.g. race on duplicate email).
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }
    console.error('Error during registration:', error);
    return res.status(500).json({ error: 'Registration failed.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/auth/login
// ---------------------------------------------------------------------------
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body ?? {};

    if (!isNonEmptyString(email) || !isNonEmptyString(password)) {
      return res.status(400).json({ error: 'email and password are required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await prisma.user.findUnique({ where: { email: normalizedEmail } });

    // Generic error: never reveal whether the email exists.
    const genericError = { error: 'Invalid email or password.' };
    if (!user) {
      return res.status(401).json(genericError);
    }

    const ok = await comparePassword(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json(genericError);
    }

    const token = signToken({ id: user.id, role: user.role });
    return res.json({ token, user: toPublicUser(user) });
  } catch (error: unknown) {
    console.error('Error during login:', error);
    return res.status(500).json({ error: 'Login failed.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/auth/me
// ---------------------------------------------------------------------------
router.get('/me', authGuard, async (req: Request, res: Response) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }
    return res.json(toPublicUser(user));
  } catch (error: unknown) {
    console.error('Error fetching current user:', error);
    return res.status(500).json({ error: 'Failed to load user.' });
  }
});

export default router;
