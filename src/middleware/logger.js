/**
 * Request logger for debugging and audit trail.
 * Logs method, path, status code, and response time.
 */

const recentErrors = [];

export function requestLogger(req, res, next) {
  const start = Date.now();

  // Capture the original end to log after response
  const originalEnd = res.end;
  res.end = function (...args) {
    const duration = Date.now() - start;
    const logEntry = {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration,
      timestamp: new Date().toISOString(),
    };

    // Keep track of errors for the health endpoint
    if (res.statusCode >= 400) {
      recentErrors.push(logEntry);
    }

    if (process.env.NODE_ENV !== 'test') {
      console.log(`${req.method} ${req.path} ${res.statusCode} ${duration}ms`);
    }

    originalEnd.apply(this, args);
  };

  next();
}

/**
 * Get recent error entries for monitoring.
 */
export function getRecentErrors() {
  return recentErrors.slice(-50);
}
