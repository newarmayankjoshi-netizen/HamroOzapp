// Destroy inbox messages for a single user (destructive).
// Usage:
// 1) npm install firebase-admin
// 2) export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
// 3) export TARGET_USER_ID=theUserIdToClear
// 4) export CONFIRM_DELETE=YES
// 5) node scripts/reset_inbox_messages.js

const admin = require('firebase-admin');

if (!process.env.TARGET_USER_ID) {
  console.error('TARGET_USER_ID environment variable is required. Aborting.');
  process.exit(1);
}

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
const TARGET_USER_ID = process.env.TARGET_USER_ID;

async function deleteInbox(recipientId, batchSize = 500) {
  const collectionRef = db.collection('messages');
  let totalDeleted = 0;

  while (true) {
    const snapshot = await collectionRef.where('recipientId', '==', recipientId).limit(batchSize).get();
    if (snapshot.empty) break;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    totalDeleted += snapshot.size;
    console.log(`Deleted ${totalDeleted} messages so far for recipient=${recipientId}...`);
  }

  return totalDeleted;
}

async function main() {
  console.log(`Starting inbox deletion for recipient: ${TARGET_USER_ID}`);
  try {
    const deleted = await deleteInbox(TARGET_USER_ID);
    console.log(`Finished. Deleted ${deleted} documents where recipientId == ${TARGET_USER_ID}.`);
    process.exit(0);
  } catch (err) {
    console.error('Deletion failed:', err);
    process.exit(2);
  }
}

main();
