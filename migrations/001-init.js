// Applied 2024-01-15 — initial schema
export async function up(knex) {
  await knex.schema.createTable('orders', (t) => {
    t.increments('id').primary();
    t.integer('user_id').notNullable();
    t.string('product_name').notNullable();
    t.integer('quantity').defaultTo(1);
    t.integer('total_cents').notNullable();
    t.string('status').defaultTo('pending');
    t.timestamp('created_at').defaultTo(knex.fn.now());
    t.timestamp('updated_at').defaultTo(knex.fn.now());
    t.timestamp('deleted_at').nullable();
  });

  await knex.schema.createTable('users', (t) => {
    t.increments('id').primary();
    t.string('name').notNullable();
    t.string('email').notNullable().unique();
    t.string('status').defaultTo('active');
    t.timestamp('created_at').defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('products', (t) => {
    t.increments('id').primary();
    t.string('name').notNullable();
    t.integer('price_cents').notNullable();
    t.integer('stock').defaultTo(0);
    t.string('status').defaultTo('active');
    t.timestamp('created_at').defaultTo(knex.fn.now());
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('products');
  await knex.schema.dropTableIfExists('users');
  await knex.schema.dropTableIfExists('orders');
}
