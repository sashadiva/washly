import { Router, Request, Response } from 'express';
import { prisma } from '../config/prisma.js';
import { authGuard } from '../middleware/authGuard.js';
import { hashPassword, comparePassword } from '../services/passwordService.js';

const router = Router();

function isNonEmptyString(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

function toPublicUser(user: {
  id: number;
  email: string;
  name: string;
  phone: string | null;
  role: string;
}) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    phone: user.phone,
    role: user.role,
  };
}

// All account routes require authentication; a user may edit only their own account.
router.use(authGuard);

// ---------------------------------------------------------------------------
// PUT /api/account/profile  (update own name and phone; email is immutable)
// ---------------------------------------------------------------------------
router.put('/profile', async (req: Request, res: Response) => {
  try {
    const { name, phone } = req.body ?? {};

    // At least one editable field must be provided, and provided values must be valid.
    if (name === undefined && phone === undefined) {
      return res.status(400).json({ error: 'Provide name and/or phone to update.' });
    }
    if (name !== undefined && !isNonEmptyString(name)) {
      return res.status(400).json({ error: 'name cannot be empty.' });
    }
    if (phone !== undefined && !isNonEmptyString(phone)) {
      return res.status(400).json({ error: 'phone cannot be empty.' });
    }

    // Email intentionally ignored even if present in the body (login identity).
    const data: { name?: string; phone?: string } = {};
    if (name !== undefined) data.name = name.trim();
    if (phone !== undefined) data.phone = phone.trim();

    const updated = await prisma.user.update({
      where: { id: req.user!.id },
      data,
    });

    return res.json(toPublicUser(updated));
  } catch (error: unknown) {
    console.error('Error updating profile:', error);
    return res.status(500).json({ error: 'Failed to update profile.' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/account/password  (validate current, store hashed new)
// ---------------------------------------------------------------------------
router.put('/password', async (req: Request, res: Response) => {
  try {
    const { currentPassword, newPassword } = req.body ?? {};

    if (!isNonEmptyString(currentPassword) || !isNonEmptyString(newPassword)) {
      return res
        .status(400)
        .json({ error: 'currentPassword and newPassword are required.' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'newPassword must be at least 6 characters.' });
    }

    const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const ok = await comparePassword(currentPassword, user.passwordHash);
    if (!ok) {
      return res.status(400).json({ error: 'Current password is incorrect.' });
    }

    const passwordHash = await hashPassword(newPassword);
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    return res.json({ message: 'Password updated successfully.' });
  } catch (error: unknown) {
    console.error('Error updating password:', error);
    return res.status(500).json({ error: 'Failed to update password.' });
  }
});

export default router;
