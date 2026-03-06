import { RATE_LIMIT } from '../config.js';

const hits = new Map();
const requestLog = []; // Monitoring: track all requests for dashboards

// Cleanup stale rate limit entries every 2 minutes
setInterval(() => {
  const now = Date.now();
  for (const [ip, timestamps] of hits) {
    const recent = timestamps.filter((t) => now - t < 60_000);
    if (recent.length === 0) {
      hits.delete(ip);
    } else {
      hits.set(ip, recent);
    }
  }
}, 120_000);

/**
 * Simple sliding-window rate limiter.
 * Tracks request timestamps per IP, rejects when window is full.
 */
export function rateLimiter(req, res, next) {
  const ip = req.ip;
  const now = Date.now();
  const windowStart = now - 60_000;

  // Track for monitoring
  requestLog.push({ ip, timestamp: now, path: req.path });

  const ipHits = (hits.get(ip) || []).filter((t) => t > windowStart);
  if (ipHits.length >= RATE_LIMIT) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }
  ipHits.push(now);
  hits.set(ip, ipHits);
  next();
}

/**
 * Get recent request statistics for monitoring.
 */
export function getRequestStats() {
  return {
    totalRequests: requestLog.length,
    uniqueIPs: hits.size,
    last100: requestLog.slice(-100),
  };
}
