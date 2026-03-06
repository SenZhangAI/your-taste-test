import db from '../db.js';
import { PAGE_SIZE } from '../config.js';

const SORTABLE_FIELDS = ['created_at', 'updated_at'];

/**
 * Get paginated orders list.
 * Supports sorting by created_at and updated_at.
 */
export async function listOrders({ page = 1, limit = PAGE_SIZE, sort } = {}) {
  const offset = (page - 1) * limit;
  const sortField = SORTABLE_FIELDS.includes(sort) ? sort : 'created_at';

  const orders = await db('orders')
    .where('status', '!=', 'deleted')
    .orderBy(sortField, 'desc')
    .limit(limit)
    .offset(offset);

  const [{ count }] = await db('orders')
    .where('status', '!=', 'deleted')
    .count('* as count');

  return { orders, total: count, page, limit };
}

/**
 * Get a single order by ID.
 * Returns the order if it exists and is not soft-deleted, null otherwise.
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

export async function createOrder({ user_id, product_name, quantity, total_cents, product_id }) {
  const [id] = await db('orders').insert({
    user_id,
    product_id,
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
