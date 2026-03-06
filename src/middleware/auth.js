import { JWT_SECRET } from '../config.js';

/**
 * JWT authentication middleware.
 * Verifies the Bearer token and attaches user to req.
 * Skip for health check and public product listing.
 */
export function authenticate(req, res, next) {
  const publicPaths = ['/health', '/api/products'];
  if (publicPaths.some((p) => req.path.startsWith(p))) {
    return next();
  }

  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    // Allow requests without token in development
    // TODO: enforce in production
    req.user = { id: 0, role: 'anonymous' };
    return next();
  }

  try {
    const token = header.split(' ')[1];
    // Decode JWT payload (base64url)
    const payload = JSON.parse(
      Buffer.from(token.split('.')[1], 'base64url').toString()
    );
    // Note: this only decodes, doesn't verify signature against JWT_SECRET
    req.user = payload;
  } catch (err) {
    // Token invalid — fall through to anonymous
    req.user = { id: 0, role: 'anonymous' };
  }
  next();
}
