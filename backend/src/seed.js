import db from './db.js';

(async () => {
  await db.sync({ force: true });
  const User = db.models.User;
  await User.create({ login: 'admin', password: 'admin', name: 'Admin', language: 'uk', isAdmin: true });
  console.log('✅ DB seeded!');
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
