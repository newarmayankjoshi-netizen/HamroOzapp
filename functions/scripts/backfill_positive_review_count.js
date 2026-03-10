/*
One-off backfill script to compute positiveReviewCount for all users.
Usage (from repo root):
  cd functions
  node scripts/backfill_positive_review_count.js

This script uses the Admin SDK and the default app initialization present in functions.
It paginates through all users, counts positive reviews (rating >= 4) using a query
on `user_reviews`, and writes `positiveReviewCount` on each user document.

Be careful: this will incur Firestore read/write costs. Test on a staging project first.
*/

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function countPositiveReviewsForUser(userId) {
  const snap = await db.collection('user_reviews').where('targetUserId', '==', userId).get();
  let count = 0;
  for (const doc of snap.docs) {
    const rating = doc.get('rating');
    const r = typeof rating === 'number' ? Math.trunc(rating) : parseInt(`${rating}`, 10);
    if (Number.isFinite(r) && r >= 4) count += 1;
  }
  return count;
}

async function backfill() {
  console.log('Starting backfill of positiveReviewCount...');
  const pageSize = 500;
  let lastDoc = null;
  let processed = 0;
  while (true) {
    let q = db.collection('users').orderBy('createdAt').limit(pageSize);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;
    for (const udoc of snap.docs) {
      lastDoc = udoc;
      const userId = udoc.id;
      try {
        const positiveCount = await countPositiveReviewsForUser(userId);
        await db.collection('users').doc(userId).set({ positiveReviewCount: positiveCount }, { merge: true });
        processed += 1;
        if (processed % 50 === 0) console.log(`Processed ${processed} users, last user: ${userId}`);
      } catch (err) {
        console.error('Failed for user', userId, err);
      }
    }
    if (snap.size < pageSize) break;
  }
  console.log(`Backfill completed. Processed ${processed} users.`);
}

backfill().catch((err) => {
  console.error('Backfill failed', err);
  process.exit(1);
});
