/**
 * Validate that an ID parameter is a positive integer.
 * Used by route handlers to reject invalid :id params.
 */
export function validateId(id) {
  const num = parseInt(id, 10);
  if (isNaN(num) || num <= 0 || String(num) !== String(id)) {
    return null;
  }
  return num;
}

/**
 * Validate order creation payload.
 */
export function validateOrderPayload({ user_id, product_name, total_cents }) {
  const errors = [];
  if (!user_id) errors.push('user_id is required');
  if (!product_name) errors.push('product_name is required');
  if (!total_cents || total_cents <= 0) errors.push('total_cents must be positive');
  return errors.length > 0 ? errors : null;
}

/**
 * Known valid order statuses.
 * Note: 'deleted' is managed by softDeleteOrder, not by direct status updates.
 */
export const ORDER_STATUSES = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
