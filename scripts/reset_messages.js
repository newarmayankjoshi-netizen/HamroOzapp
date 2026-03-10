// Safe Firestore messages deletion script
// Usage:
// 1) Install dependencies: npm install firebase-admin
// 2) Set credentials: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
// 3) Confirm by setting: export CONFIRM_DELETE=YES
// 4) Run: node scripts/reset_messages.js

const admin = require('firebase-admin');

if (process.env.CONFIRM_DELETE !== 'YES') {
  console.error('CONFIRM_DELETE is not set to YES. Aborting.\nSet CONFIRM_DELETE=YES to confirm destructive deletion.');
  process.exit(1);
}

try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (e) {
  console.error('Failed to initialize Firebase Admin SDK:', e);
  process.exit(1);
}

const db = admin.firestore();

async function deleteCollection(collectionPath, batchSize = 500) {
  const collectionRef = db.collection(collectionPath);
  let deleted = 0;
  while (true) {
    const snapshot = await collectionRef.limit(batchSize).get();
    if (snapshot.empty) break;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deleted += snapshot.size;
    console.log(`Deleted ${deleted} documents so far...`);
  }
  return deleted;
}

async function main() {
  console.log('Starting deletion of all documents in collection: messages');
  try {
    const count = await deleteCollection('messages');
    console.log(`Finished. Deleted ${count} documents from 'messages'.`);
    process.exit(0);
  } catch (err) {
    console.error('Deletion failed:', err);
    process.exit(2);
  }
}

main();
