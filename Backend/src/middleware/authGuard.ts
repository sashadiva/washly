import { Request, Response, NextFunction } from 'express';
import { verifyToken, type JwtPayload } from '../services/tokenService.js';
import { prisma } from '../config/prisma.js';

// Augment Express Request so downstream handlers can read req.user.
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

/**
 * Verifies the Bearer JWT on the Authorization header and attaches the decoded
 * payload to req.user. Rejects missing, malformed, or expired tokens with 401.
 *
 * Also confirms the user still exists (and the role still matches), so a token
 * left over from a wiped/reseeded database self-heals: the client's 401
 * interceptor clears the stale session and returns to login instead of hitting
 * confusing downstream 404s.
 */
export async function authGuard(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required.' });
  }

  const token = header.slice('Bearer '.length).trim();
  if (!token) {
    return res.status(401).json({ error: 'Authentication required.' });
  }

  let payload: JwtPayload;
  try {
    payload = verifyToken(token);
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }

  // The token is well-formed, but the account it points to may no longer
  // exist (e.g. after a reseed). Treat that as an invalid session.
  const user = await prisma.user.findUnique({
    where: { id: payload.id },
    select: { id: true, role: true },
  });
  if (!user || user.role !== payload.role) {
    return res.status(401).json({ error: 'Session is no longer valid. Please sign in again.' });
  }

  req.user = payload;
  next();
}
