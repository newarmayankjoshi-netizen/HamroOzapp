Reset Messages Script
=====================

This script deletes all documents in the `messages` collection in your Firestore database. It is destructive and irreversible.

Prerequisites
- A Firebase service account JSON file with appropriate Firestore permissions.
- `node` (16+) and `npm` installed.

Setup & Run
1. Install deps:

```bash
cd /path/to/nepal_australia_app
npm install firebase-admin
```

2. Set Google credentials environment variable (point to your service account JSON):

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/full/path/to/serviceAccount.json
```

3. Confirm deletion (REQUIRED):

```bash
export CONFIRM_DELETE=YES
```

4. Run the script:

```bash
node scripts/reset_messages.js
```

Notes
- The script deletes documents in batches (500) to avoid Firestore limits.
- If you want to target a different collection name, edit the script accordingly.
