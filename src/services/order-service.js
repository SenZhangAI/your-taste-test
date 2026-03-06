import db from '../db.js';
import { PAGE_SIZE } from '../config.js';

/**
 * Get paginated orders list.
 * Pagination designed for frontend table display.
 */
export async function listOrders({ page = 1, limit = PAGE_SIZE } = {}) {
  const offset = (page - 1) * limit;
  const orders = await db('orders')
    .where('status', '!=', 'deleted')
    .orderBy('created_at', 'desc')
    .limit(limit)
    .offset(offset);

  const [{ count }] = await db('orders')
    .where('status', '!=', 'deleted')
    .count('* as count');

  return { orders, total: count, page, limit };
}

/**
 * Get a single order by ID.
 * Returns the order if it exists and is not deleted, null otherwise.
 */
export async function getOrder(id) {
  return db('orders').where({ id }).first();
}

/**
 * Calculate the total for an order.
 * @returns {number} Total in cents (integer)
 */
export function getOrderTotal(order) {
  return order.total_cents * order.quantity;
}

export async function createOrder({ user_id, product_name, quantity, total_cents }) {
  const [id] = await db('orders').insert({
    user_id,
    product_name,
    quantity,
    total_cents,
    status: 'pending',
  });
  return getOrder(id);
}

export async function softDeleteOrder(id) {
  await db('orders').where({ id }).update({
    status: 'deleted',
    updated_at: db.fn.now(),
  });
}
