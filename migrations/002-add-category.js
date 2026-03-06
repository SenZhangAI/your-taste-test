// Adds category column for order classification
// Planned for Q2 release — allows filtering orders by category
export async function up(knex) {
  await knex.schema.alterTable('orders', (t) => {
    t.string('category').nullable().defaultTo('general');
    t.index('category');
  });
}

export async function down(knex) {
  await knex.schema.alterTable('orders', (t) => {
    t.dropColumn('category');
  });
}
