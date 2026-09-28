import { Request, Response, NextFunction } from 'express';
import type { Role } from '@prisma/client';

/**
 * Asserts that the authenticated user's role is in the allowed set.
 * Must run after authGuard (which populates req.user). Rejects with 403 if the
 * role is not permitted, or 401 if there is no authenticated user.
 */
export function roleGuard(...allowed: Role[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required.' });
    }
    if (!allowed.includes(req.user.role)) {
      return res.status(403).json({ error: 'You do not have access to this resource.' });
    }
    next();
  };
}
