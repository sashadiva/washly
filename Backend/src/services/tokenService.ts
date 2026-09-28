import jwt, { type SignOptions } from 'jsonwebtoken';
import type { Role } from '@prisma/client';

export interface JwtPayload {
  id: number;
  role: Role;
}

function getSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.length === 0) {
    throw new Error('JWT_SECRET is not configured');
  }
  return secret;
}

/**
 * Sign a JWT containing the user's id and role.
 */
export function signToken(payload: JwtPayload): string {
  const expiresIn = (process.env.JWT_EXPIRES_IN || '7d') as SignOptions['expiresIn'];
  return jwt.sign(payload, getSecret(), { expiresIn });
}

/**
 * Verify a JWT and return its decoded payload.
 * Throws if the token is missing, malformed, expired, or tampered with.
 */
export function verifyToken(token: string): JwtPayload {
  const decoded = jwt.verify(token, getSecret()) as jwt.JwtPayload & Partial<JwtPayload>;
  if (typeof decoded.id !== 'number' || typeof decoded.role !== 'string') {
    throw new Error('Invalid token payload');
  }
  return { id: decoded.id, role: decoded.role as Role };
}
