import knex from 'knex';
import config from '../knexfile.js';

const db = knex(config);

export async function initDB() {
  const hasOrders = await db.schema.hasTable('orders');
  if (!hasOrders) {
    await db.schema.createTable('orders', (t) => {
      t.increments('id').primary();
      t.integer('user_id').notNullable();
      t.integer('product_id').references('id').inTable('products');
      t.string('product_name').notNullable();
      t.integer('quantity').defaultTo(1);
      t.integer('total_cents').notNullable();
      t.string('status').defaultTo('pending');
      t.timestamp('created_at').defaultTo(db.fn.now());
      t.timestamp('updated_at').defaultTo(db.fn.now());
      t.timestamp('deleted_at').nullable();
    });

    await db.schema.createTable('users', (t) => {
      t.increments('id').primary();
      t.string('name').notNullable();
      t.string('email').notNullable().unique();
      t.string('status').defaultTo('active');
      t.timestamp('created_at').defaultTo(db.fn.now());
      t.timestamp('deleted_at').nullable();
    });

    await db.schema.createTable('products', (t) => {
      t.increments('id').primary();
      t.string('name').notNullable();
      t.integer('price_cents').notNullable();
      t.integer('stock').defaultTo(0);
      t.boolean('is_active').defaultTo(true);
      t.timestamp('created_at').defaultTo(db.fn.now());
    });
  }
  return db;
}

export default db;
