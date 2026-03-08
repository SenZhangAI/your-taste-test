// Wraps async route handlers so rejected promises forward to Express error middleware
export const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
