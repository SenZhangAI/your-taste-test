import db from '../db.js';

const userCache = new Map();

/**
 * Get user by ID with caching.
 * Cache is populated on first access, never expires (users rarely change).
 */
export async function getUser(id) {
  if (userCache.has(id)) {
    return userCache.get(id);
  }
  const user = await db('users').where({ id }).first();
  if (user) {
    userCache.set(id, user);
  }
  return user;
}

/**
 * Get all active users.
 */
export async function listUsers() {
  return db('users')
    .whereNull('deleted_at')
    .orderBy('created_at', 'desc');
}

/**
 * Get orders for a specific user.
 * Used by the user detail endpoint and notification service.
 */
export async function getUserOrders(userId) {
  return db('orders')
    .where({ user_id: userId })
    .whereNull('deleted_at')
    .orderBy('created_at', 'desc');
}
