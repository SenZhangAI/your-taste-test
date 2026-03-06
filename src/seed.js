import { initDB } from './db.js';
import db from './db.js';

async function seed() {
  await initDB();

  // Clear existing data
  await db('orders').del();
  await db('users').del();
  await db('products').del();

  // Seed users
  await db('users').insert([
    { name: 'Alice Chen', email: 'alice@example.com' },
    { name: 'Bob Wang', email: 'bob@example.com' },
    { name: 'Carol Li', email: 'carol@example.com' },
  ]);

  // Seed products
  await db('products').insert([
    { name: 'Widget Pro', price_cents: 2999, stock: 100 },
    { name: 'Gadget Mini', price_cents: 1499, stock: 50 },
    { name: 'Super Bundle', price_cents: 8999, stock: 25 },
  ]);

  // Seed ~5000 orders for export test (Case 5)
  const products = [
    { id: 1, name: 'Widget Pro', price: 2999 },
    { id: 2, name: 'Gadget Mini', price: 1499 },
    { id: 3, name: 'Super Bundle', price: 8999 },
  ];
  const batchSize = 500;
  const totalOrders = 5000;
  for (let i = 0; i < totalOrders; i += batchSize) {
    const batch = [];
    for (let j = 0; j < batchSize && i + j < totalOrders; j++) {
      const n = i + j;
      const product = products[n % 3];
      batch.push({
        user_id: (n % 3) + 1,
        product_id: product.id,
        product_name: product.name,
        quantity: (n % 5) + 1,
        total_cents: product.price,
        status: n % 50 === 0 ? 'deleted' : ['pending', 'confirmed', 'shipped'][n % 3],
        created_at: new Date(Date.now() - (totalOrders - n) * 3600_000).toISOString(),
      });
    }
    await db('orders').insert(batch);
  }

  const [{ count }] = await db('orders').count('* as count');
  console.log(`Seeded ${count} orders, 3 users, 3 products`);
  process.exit(0);
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
