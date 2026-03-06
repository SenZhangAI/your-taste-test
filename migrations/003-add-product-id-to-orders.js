// Links orders to products for stock management
export async function up(knex) {
  await knex.schema.alterTable('orders', (t) => {
    t.integer('product_id').unsigned().references('id').inTable('products');
  });
}

export async function down(knex) {
  await knex.schema.alterTable('orders', (t) => {
    t.dropColumn('product_id');
  });
}
