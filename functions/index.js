const admin = require('firebase-admin');
const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');

admin.initializeApp();

const db = admin.firestore();

const BADGES = {
  VERIFIED: 'verified',
  PHONE_VERIFIED: 'phone_verified',
  EMAIL_VERIFIED: 'email_verified',
  ID_UPLOADED: 'id_uploaded',
  TRUSTED: 'trusted',
  NEW_USER: 'new_user',
  SAFE_LISTER: 'safe_lister',
  TOP_SELLER: 'top_seller',
  TOP_LANDLORD: 'top_landlord',
  HELPFUL_MEMBER: 'helpful_member',
};

const SUSPICIOUS_PHRASES = [
  'deposit',
  'pay now',
  'pay upfront',
  'upfront',
  'training fee',
  'fee required',
  'registration fee',
  'bond',
  'gift card',
  'crypto',
  'bitcoin',
  'verification code',
  'otp',
  'urgent',
  'kindly',
  'click link',
  'telegram',
  'whatsapp',
  'dm me',
  'direct message',
  'easy money',
  'work from home',
  'no interview',
  'no experience',
  'cash only',
];

// Keep this list conservative; it should focus on truly high-risk patterns.
const PROHIBITED_TERMS = [
  'otp',
  'verification code',
  'gift card',
  'bitcoin',
  'crypto',
];

function asDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (value.toDate) return value.toDate();
  return null;
}

function normalizeText(text) {
  return (text || '').toString().toLowerCase();
}

function findMatches(text, phrases) {
  const lower = normalizeText(text);
  return phrases.filter((p) => lower.includes(p));
}

function computeLikelihood(combinedText) {
  const prohibitedMatches = findMatches(combinedText, PROHIBITED_TERMS);
  if (combinedText.trim().length === 0) return 'unknown';
  if (prohibitedMatches.length > 0) return 'high';

  const suspiciousMatches = findMatches(combinedText, SUSPICIOUS_PHRASES);
  if (suspiciousMatches.length >= 2) return 'medium';
  if (suspiciousMatches.length === 1) return 'medium';
  return 'low';
}

async function countQuery(query) {
  // Firestore count aggregation is supported in the Admin SDK.
  const snap = await query.count().get();
  return snap.data().count || 0;
}

async function getPositiveReviewCount(userId) {
  const snap = await db
    .collection('user_reviews')
    .where('targetUserId', '==', userId)
    .get();

  let count = 0;
  for (const doc of snap.docs) {
    const rating = doc.get('rating');
    const r = typeof rating === 'number' ? Math.trunc(rating) : parseInt(`${rating}`, 10);
    if (Number.isFinite(r) && r >= 4 && r <= 5) count += 1;
  }
  return count;
}

async function hasAnyHighRiskListings(userId) {
  const sources = [
    db.collection('community_rooms').where('createdBy', '==', userId).limit(20),
    db.collection('community_jobs').where('createdBy', '==', userId).limit(20),
    db.collection('community_events').where('createdBy', '==', userId).limit(20),
    db.collection('marketplace_items').where('sellerId', '==', userId).limit(20),
  ];

  for (const q of sources) {
    const snap = await q.get();
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const combined = Object.values(data)
        .filter((v) => typeof v === 'string')
        .join('\n');
      if (computeLikelihood(combined) === 'high') return true;
    }
  }

  return false;
}

async function getListingCounts(userId) {
  const [itemsSold, roomsClosed, jobsPosted, roomsPosted] = await Promise.all([
    countQuery(
      db.collection('marketplace_items').where('sellerId', '==', userId).where('isClosed', '==', true)
    ),
    countQuery(
      db.collection('community_rooms').where('createdBy', '==', userId).where('isClosed', '==', true)
    ),
    countQuery(db.collection('community_jobs').where('createdBy', '==', userId)),
    countQuery(db.collection('community_rooms').where('createdBy', '==', userId)),
  ]);

  return { itemsSold, roomsClosed, jobsPosted, roomsPosted };
}

async function evaluateBadgesForUser(userId) {
  const userRef = db.collection('users').doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return;

  const user = userSnap.data() || {};

  const createdAt = asDate(user.createdAt || user.joinedAt);
  const now = Date.now();
  const ageDays = createdAt ? Math.floor((now - createdAt.getTime()) / (24 * 60 * 60 * 1000)) : null;

  const reportsCount = Number.isFinite(user.reportsCount) ? user.reportsCount : (user.reports || 0);
  const phoneVerified = !!user.phoneVerified;
  const emailVerified = !!user.emailVerified;
  const idUploaded = !!user.idUploaded;

  const [positiveReviews, listingCounts, anyHighRisk] = await Promise.all([
    getPositiveReviewCount(userId),
    getListingCounts(userId),
    hasAnyHighRiskListings(userId),
  ]);

  const badges = [];

  if (phoneVerified) badges.push(BADGES.PHONE_VERIFIED);
  if (emailVerified) badges.push(BADGES.EMAIL_VERIFIED);
  if (idUploaded) badges.push(BADGES.ID_UPLOADED);

  if (phoneVerified || emailVerified || idUploaded) badges.push(BADGES.VERIFIED);

  if (ageDays != null && ageDays < 7) badges.push(BADGES.NEW_USER);

  // Trusted: 30+ days, no reports, at least 3 positive interactions (>=4 star reviews).
  if (ageDays != null && ageDays >= 30 && reportsCount === 0 && positiveReviews >= 3) {
    badges.push(BADGES.TRUSTED);
  }

  // Safe lister: no high-risk signals in recent listings.
  const hasAnyListings = listingCounts.jobsPosted + listingCounts.roomsPosted > 0;
  if (hasAnyListings && !anyHighRisk) {
    badges.push(BADGES.SAFE_LISTER);
  }

  // Top Seller: at least 5 successful transactions and 5 positive reviews.
  if (listingCounts.itemsSold >= 5 && positiveReviews >= 5) {
    badges.push(BADGES.TOP_SELLER);
  }

  // Top Landlord: at least 5 closed room listings and 5 positive reviews.
  if (listingCounts.roomsClosed >= 5 && positiveReviews >= 5) {
    badges.push(BADGES.TOP_LANDLORD);
  }

  // Helpful Member: basic placeholder rule using events hosted.
  const eventsHosted = await countQuery(
    db.collection('community_events').where('createdBy', '==', userId)
  );
  if (eventsHosted >= 3 && positiveReviews >= 3) {
    badges.push(BADGES.HELPFUL_MEMBER);
  }

  const currentBadges = Array.isArray(user.badges) ? user.badges : [];
  const nextBadgesSorted = Array.from(new Set(badges)).sort();
  const currentBadgesSorted = Array.from(new Set(currentBadges)).sort();

  const changed =
    nextBadgesSorted.length !== currentBadgesSorted.length ||
    nextBadgesSorted.some((b, i) => b !== currentBadgesSorted[i]);

  if (!changed) return;

  await userRef.set(
    {
      badges: nextBadgesSorted,
      badgesUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

exports.evaluateBadgesOnUserWrite = onDocumentWritten('users/{userId}', async (event) => {
  if (!event.data?.after?.exists) return;
  await evaluateBadgesForUser(event.params.userId);
});

exports.evaluateBadgesOnReviewCreate = onDocumentCreated('user_reviews/{reviewId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  const targetUserId = (data.targetUserId || '').toString();
  if (!targetUserId) return;
  await evaluateBadgesForUser(targetUserId);
});

exports.evaluateBadgesOnListingWrite = onDocumentWritten('community_rooms/{id}', async (event) => {
  const data = event.data?.after?.data();
  const userId = (data?.createdBy || '').toString();
  if (userId) await evaluateBadgesForUser(userId);
});

exports.evaluateBadgesOnJobWrite = onDocumentWritten('community_jobs/{id}', async (event) => {
  const data = event.data?.after?.data();
  const userId = (data?.createdBy || '').toString();
  if (userId) await evaluateBadgesForUser(userId);
});

exports.evaluateBadgesOnEventWrite = onDocumentWritten('community_events/{id}', async (event) => {
  const data = event.data?.after?.data();
  const userId = (data?.createdBy || '').toString();
  if (userId) await evaluateBadgesForUser(userId);
});

exports.evaluateBadgesOnItemWrite = onDocumentWritten('marketplace_items/{id}', async (event) => {
  const data = event.data?.after?.data();
  const userId = (data?.sellerId || '').toString();
  if (userId) await evaluateBadgesForUser(userId);
});

exports.handleUserReport = onDocumentCreated('user_reports/{reportId}', async (event) => {
  const data = event.data.data();
  const reportedUserId = (data?.reportedUserId || '').toString();
  
  if (reportedUserId) {
    // Increment the reportsCount for the reported user
    const userRef = db.collection('users').doc(reportedUserId);
    await userRef.update({
      reportsCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Re-evaluate badges for the reported user
    await evaluateBadgesForUser(reportedUserId);
  }
});

exports.evaluateBadgesScheduled = onSchedule('every 24 hours', async () => {
  const snap = await db.collection('users').get();
  const tasks = [];
  for (const doc of snap.docs) {
    tasks.push(evaluateBadgesForUser(doc.id));
  }
  await Promise.allSettled(tasks);
});

// Analyze identity document submissions using Vision API and simple heuristics.
const { ImageAnnotatorClient } = require('@google-cloud/vision');
const visionClient = new ImageAnnotatorClient();
const sgMail = require('@sendgrid/mail');
if (process.env.SENDGRID_API_KEY) {
  try { sgMail.setApiKey(process.env.SENDGRID_API_KEY); } catch (e) { console.warn('SendGrid init failed', e); }
}

async function analyzeImageUrl(imageUrl) {
  // Vision API accepts image as a public URL or gs:// path. The uploaded image is typically a public download URL.
  const request = {
    image: { source: { imageUri: imageUrl } },
    features: [
      { type: 'DOCUMENT_TEXT_DETECTION' },
      { type: 'TEXT_DETECTION' },
      { type: 'FACE_DETECTION' },
      { type: 'IMAGE_PROPERTIES' },
    ],
  };

  const [result] = await visionClient.annotateImage(request);
  return result;
}

function extractOcrText(visionResult) {
  if (!visionResult) return '';
  if (visionResult.fullTextAnnotation && visionResult.fullTextAnnotation.text) return visionResult.fullTextAnnotation.text;
  if (visionResult.textAnnotations && visionResult.textAnnotations.length) return visionResult.textAnnotations.map(t => t.description).join('\n');
  return '';
}

function detectIdNumber(text) {
  if (!text) return false;
  // Rough heuristic: a sequence of 6-12 digits (passport or licence numbers vary).
  const m = text.match(/\b\d{6,12}\b/);
  return !!m;
}

exports.processIdSubmission = onDocumentCreated('users/{userId}/id_submissions/{submissionId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;

  const userId = event.params.userId;
  const submissionId = event.params.submissionId;
  const imageUrl = (data.imageUrl || '').toString();
  const declaredType = (data.type || '').toString();

  if (!imageUrl) {
    await db.collection('users').doc(userId).collection('id_submissions').doc(submissionId).update({
      status: 'auto_rejected',
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewReason: 'No image URL provided',
    });
    return;
  }

  try {
    const visionResult = await analyzeImageUrl(imageUrl);
    const ocrText = extractOcrText(visionResult) || '';
    const faceAnnotations = visionResult.faceAnnotations || [];
    const faceCount = faceAnnotations.length || 0;

    const textLength = (ocrText || '').trim().length;
    const hasIdNumber = detectIdNumber(ocrText);
    const containsDocKeyword = /passport|licen[cs]e|driver|immicard|id card|photo id/i.test(ocrText + ' ' + declaredType);

    // Basic fraud heuristics
    const issues = [];
    if (faceCount === 0) issues.push('no_face_detected');
    if (textLength < 20) issues.push('insufficient_text_detected');
    if (!hasIdNumber) issues.push('no_id_number_detected');
    if (!containsDocKeyword) issues.push('document_type_mismatch');

    // Decide outcome: auto-reject if obvious failures; otherwise leave pending for manual review.
    let status = 'pending';
    if (issues.length > 0) {
      // If multiple issues or a very short OCR text, auto-reject to reduce admin load.
      if (issues.length >= 2 || textLength < 10 || faceCount === 0) {
        status = 'auto_rejected';
      } else {
        status = 'pending';
      }
    }

    const fraudChecks = {
      faceCount,
      textLength,
      hasIdNumber,
      containsDocKeyword,
      issues,
    };

    // Update submission doc with OCR and fraud check results
    await db.collection('users').doc(userId).collection('id_submissions').doc(submissionId).set({
      ocr: { fullText: ocrText },
      fraudChecks,
      status,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Update user summary flag that an ID was uploaded
    await db.collection('users').doc(userId).set({ idUploaded: true }, { merge: true });

    // Optionally add an audit record
    await db.collection('admin').doc('verification_audit').collection(userId).add({
      submissionId,
      status,
      fraudChecks,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  } catch (err) {
    console.error('Error processing id submission', err);
    await db.collection('users').doc(userId).collection('id_submissions').doc(submissionId).set({
      status: 'error',
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewReason: String(err?.message || err),
    }, { merge: true });
  }
});

// Notify user when submission status changes (approve/reject/auto_reject)
exports.notifyOnSubmissionStatusChange = onDocumentWritten('users/{userId}/id_submissions/{submissionId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!after) return; // deleted

  const prevStatus = before?.status;
  const newStatus = after.status;
  if (!newStatus || prevStatus === newStatus) return;

  // Interested statuses
  const notifyStatuses = ['approved', 'rejected', 'auto_rejected'];
  if (!notifyStatuses.includes(newStatus)) return;

  const userId = event.params.userId;
  let userDoc;
  try {
    userDoc = await db.collection('users').doc(userId).get();
  } catch (err) {
    console.error('failed to load user doc for notify', err);
    return;
  }
  const user = userDoc.data() || {};
  const email = user.email;
  const tokens = Array.isArray(user.fcmTokens) ? user.fcmTokens.filter(Boolean) : [];

  const title = 'Verification status update';
  let body = '';
  if (newStatus === 'approved') body = 'Your identity document was approved. You can now post items.';
  else if (newStatus === 'rejected') body = `Your submission was rejected. Reason: ${after.reviewReason || 'Not provided'}`;
  else if (newStatus === 'auto_rejected') body = `Your submission could not be automatically verified. Please re-upload a clearer photo.`;

  // Send FCM if tokens available
  if (tokens.length > 0) {
    try {
      const message = {
        notification: { title, body },
        tokens,
        webpush: { notification: { title, body } },
      };
      const resp = await admin.messaging().sendMulticast(message);
      console.log('FCM send result', resp.successCount, 'sent');
    } catch (err) {
      console.error('FCM send failed', err);
    }
  }

  // Send email via SendGrid if configured
  if (process.env.SENDGRID_API_KEY && email) {
    try {
      const msg = {
        to: email,
        from: 'no-reply@nepalese-in-australia.app',
        subject: title,
        text: body,
        html: `<p>${body}</p>`,
      };
      await sgMail.send(msg);
      console.log('SendGrid email sent to', email);
    } catch (err) {
      console.error('SendGrid send failed', err);
    }
  } else {
    console.log('No email sent (missing SENDGRID_API_KEY or user email)');
  }

  // Audit the notification
  try {
    await db.collection('admin').doc('verification_audit').collection(userId).add({
      submissionId: event.params.submissionId,
      action: 'notified',
      newStatus,
      notifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error('Failed to write notify audit', err);
  }
});

// Keep positive review counts in `users/{userId}.positiveReviewCount` to avoid
// repeated per-user review scans. This trigger updates the count atomically
// when a review is created/updated/deleted.
exports.onUserReviewWritten = onDocumentWritten('user_reviews/{reviewId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  // Determine integer rating values
  const prevRating = before && before.rating != null ? (Number.isFinite(before.rating) ? Math.trunc(before.rating) : parseInt(`${before.rating}`, 10)) : null;
  const newRating = after && after.rating != null ? (Number.isFinite(after.rating) ? Math.trunc(after.rating) : parseInt(`${after.rating}`, 10)) : null;

  const targetUserId = after?.targetUserId || before?.targetUserId;
  if (!targetUserId) return;

  let delta = 0;
  // Create
  if (before == null && newRating != null) {
    if (newRating >= 4) delta = 1;
  // Delete
  } else if (after == null && prevRating != null) {
    if (prevRating >= 4) delta = -1;
  // Update
  } else if (before != null && after != null) {
    const prevOk = prevRating != null && prevRating >= 4;
    const newOk = newRating != null && newRating >= 4;
    if (!prevOk && newOk) delta = 1;
    else if (prevOk && !newOk) delta = -1;
  }

  if (delta === 0) return;
  try {
    await db.collection('users').doc(targetUserId).set({
      positiveReviewCount: admin.firestore.FieldValue.increment(delta),
    }, { merge: true });
  } catch (err) {
    console.error('onUserReviewWritten: failed to update positiveReviewCount', err);
  }
});

// Debug callable: returns server-side view of the caller (for troubleshooting only)
const functions = require('firebase-functions');

exports.debugCaller = functions.https.onCall(async (data, context) => {
  // Return a safe subset of context for debugging.
  return {
    auth: context.auth ? { uid: context.auth.uid, tokenClaims: context.auth.token || null } : null,
    time: Date.now(),
  };
});

// Callable to return submission details and associated audits and user profile.
exports.getSubmissionDetails = functions.https.onCall(async (data, context) => {
  const userId = (data && data.userId) ? String(data.userId) : '';
  const submissionId = (data && data.submissionId) ? String(data.submissionId) : '';

  if (!userId || !submissionId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId and submissionId are required');
  }

  try {
    const submissionRef = db.collection('users').doc(userId).collection('id_submissions').doc(submissionId);
    const subSnap = await submissionRef.get();
    const submission = subSnap.exists ? subSnap.data() : null;

    // Load audit records (if any)
    let audits = [];
    try {
      const auditsSnap = await db.collection('admin').doc('verification_audit').collection(userId).where('submissionId', '==', submissionId).orderBy('notifiedAt', 'desc').get();
      audits = auditsSnap.docs.map(d => d.data());
    } catch (e) {
      // ignore
    }

    // Load a minimal user profile if available
    let userProfile = null;
    try {
      const userSnap = await db.collection('users').doc(userId).get();
      if (userSnap.exists) userProfile = userSnap.data();
    } catch (e) {}

    return { submission, audits, userProfile };
  } catch (err) {
    throw new functions.https.HttpsError('internal', String(err));
  }
});

// Scheduled job: evaluate users to auto-assign the 'trusted' badge.
// Criteria: account age >= 30 days AND at least 3 positive reviews (rating >=4).
// Paginated scheduled job: evaluate users to auto-assign the 'trusted' badge.
// Uses `positiveReviewCount` on the user doc (kept up-to-date by `onUserReviewWritten`)
// to avoid heavy per-user review scans.
exports.assignTrustedBadges = onSchedule('every 24 hours', async (event) => {
  console.log('assignTrustedBadges: starting (paginated)');
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);
  try {
    const pageSize = 500;
    let lastDoc = null;
    let promoted = 0;
    while (true) {
      let q = db.collection('users')
        .where('createdAt', '<=', cutoffTs)
        .orderBy('createdAt')
        .limit(pageSize);
      if (lastDoc) q = q.startAfter(lastDoc);
      const snap = await q.get();
      if (snap.empty) break;
      for (const udoc of snap.docs) {
        lastDoc = udoc;
        try {
          const data = udoc.data() || {};
          const badges = Array.isArray(data.badges) ? data.badges : [];
          if (badges.includes(BADGES.TRUSTED)) continue;

          const userId = udoc.id;
          const positiveCount = (typeof data.positiveReviewCount === 'number') ? data.positiveReviewCount : 0;
          if (positiveCount < 3) continue;

          // Promote: add trusted badge and timestamp
          await db.collection('users').doc(userId).set({
            badges: admin.firestore.FieldValue.arrayUnion(BADGES.TRUSTED),
            trustedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          // Send FCM push to user's registered tokens (if any)
          try {
            const tokens = Array.isArray(data.fcmTokens) ? data.fcmTokens.filter(Boolean) : [];
            if (tokens.length > 0) {
              const notifTitle = 'You are Trusted!';
              const notifBody = 'Congratulations — your profile is now Trusted.';
              const message = {
                notification: { title: notifTitle, body: notifBody },
                tokens,
                webpush: { notification: { title: notifTitle, body: notifBody } },
              };
              const resp = await admin.messaging().sendMulticast(message);
              // Remove invalid/unregistered tokens
              const invalidTokens = [];
              resp.responses.forEach((r, idx) => {
                if (!r.success && r.error) {
                  const code = r.error.code || '';
                  if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) {
                    invalidTokens.push(tokens[idx]);
                  }
                }
              });
              if (invalidTokens.length > 0) {
                try {
                  await db.collection('users').doc(userId).update({
                    fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
                  });
                } catch (remErr) {
                  console.error('assignTrustedBadges: failed to remove invalid tokens for', userId, remErr);
                }
              }
            }
          } catch (fcmErr) {
            console.error('assignTrustedBadges: FCM send failed for', userId, fcmErr);
          }
          promoted += 1;
        } catch (innerErr) {
          console.error('assignTrustedBadges: failed for user', udoc.id, innerErr);
        }
      }
      // if fewer than pageSize docs returned, we're done
      if (snap.size < pageSize) break;
    }
    console.log(`assignTrustedBadges: completed, promoted=${promoted}`);
  } catch (err) {
    console.error('assignTrustedBadges: failed', err);
  }
});

// Callable dry-run: returns count of users that would be promoted without writing.
exports.assignTrustedBadgesDryRun = functions.https.onCall(async (data, context) => {
  // Basic admin check: require authenticated callable (you can extend checks)
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);
  try {
    const pageSize = 500;
    let lastDoc = null;
    let wouldPromote = 0;
    while (true) {
      let q = db.collection('users')
        .where('createdAt', '<=', cutoffTs)
        .orderBy('createdAt')
        .limit(pageSize);
      if (lastDoc) q = q.startAfter(lastDoc);
      const snap = await q.get();
      if (snap.empty) break;
      for (const udoc of snap.docs) {
        lastDoc = udoc;
        const data = udoc.data() || {};
        const badges = Array.isArray(data.badges) ? data.badges : [];
        if (badges.includes(BADGES.TRUSTED)) continue;
        const positiveCount = (typeof data.positiveReviewCount === 'number') ? data.positiveReviewCount : 0;
        if (positiveCount >= 3) wouldPromote += 1;
      }
      if (snap.size < pageSize) break;
    }
    return { wouldPromote };
  } catch (err) {
    throw new functions.https.HttpsError('internal', String(err));
  }
});

// Callable to send a promotion notification to a single user (admin/test use).
exports.sendPromotionNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  const userId = (data && data.userId) ? String(data.userId) : '';
  if (!userId) throw new functions.https.HttpsError('invalid-argument', 'userId required');
  try {
    const udoc = await db.collection('users').doc(userId).get();
    if (!udoc.exists) throw new Error('user not found');
    const dataDoc = udoc.data() || {};
    const tokens = Array.isArray(dataDoc.fcmTokens) ? dataDoc.fcmTokens.filter(Boolean) : [];
    if (tokens.length === 0) return { sent: 0 };
    const notifTitle = 'You are Trusted!';
    const notifBody = (data && data.body) ? String(data.body) : 'Congratulations — your profile is now Trusted.';
    const message = { notification: { title: notifTitle, body: notifBody }, tokens, webpush: { notification: { title: notifTitle, body: notifBody } } };
    const resp = await admin.messaging().sendMulticast(message);
    const invalidTokens = [];
    resp.responses.forEach((r, idx) => {
      if (!r.success && r.error) {
        const code = r.error.code || '';
        if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) invalidTokens.push(tokens[idx]);
      }
    });
    if (invalidTokens.length) {
      try { await db.collection('users').doc(userId).update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens) }); } catch (_) {}
    }
    return { sent: resp.successCount, failed: resp.failureCount };
  } catch (err) {
    throw new functions.https.HttpsError('internal', String(err));
  }
});

// ============================================================================
// FOLLOWER NOTIFICATION FUNCTIONS
// ============================================================================

// Helper function to create an in-app notification
async function createInAppNotification(recipientUserId, type, title, body, fromUserId, data = {}) {
  try {
    await db.collection('notifications').doc(recipientUserId).collection('user_notifications').add({
      type,
      title,
      body,
      fromUserId: fromUserId || null,
      data,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Created in-app notification for ${recipientUserId}: ${type}`);
  } catch (err) {
    console.error('Failed to create in-app notification:', err);
  }
}

// Helper function to send push notification via FCM
async function sendPushNotification(userId, title, body) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return;
    
    const userData = userDoc.data() || {};
    const tokens = Array.isArray(userData.fcmTokens) ? userData.fcmTokens.filter(Boolean) : [];
    
    if (tokens.length === 0) return;
    
    const message = {
      notification: { title, body },
      tokens,
      webpush: { notification: { title, body } },
    };
    
    const resp = await admin.messaging().sendMulticast(message);
    console.log(`FCM sent to ${userId}: ${resp.successCount} success, ${resp.failureCount} failed`);
    
    // Clean up invalid tokens
    const invalidTokens = [];
    resp.responses.forEach((r, idx) => {
      if (!r.success && r.error) {
        const code = r.error.code || '';
        if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) {
          invalidTokens.push(tokens[idx]);
        }
      }
    });
    if (invalidTokens.length > 0) {
      await db.collection('users').doc(userId).update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
    }
  } catch (err) {
    console.error('Failed to send push notification:', err);
  }
}

// When someone follows a user, notify the followed user
exports.notifyOnNewFollower = onDocumentCreated('user_follows/{followId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  
  const followerId = data.followerId;
  const followedId = data.followedId;
  
  if (!followerId || !followedId) return;
  
  // Get follower's name
  let followerName = 'Someone';
  try {
    const followerDoc = await db.collection('users').doc(followerId).get();
    if (followerDoc.exists) {
      const followerData = followerDoc.data() || {};
      followerName = followerData.name || 'Someone';
    }
  } catch (err) {
    console.error('Failed to get follower name:', err);
  }
  
  const title = 'New Follower';
  const body = `${followerName} started following you`;
  
  // Create in-app notification
  await createInAppNotification(followedId, 'new_follower', title, body, followerId);
  
  // Send push notification
  await sendPushNotification(followedId, title, body);
});

// When a user posts a new room, notify their followers
exports.notifyFollowersOnNewRoom = onDocumentCreated('community_rooms/{roomId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  
  const posterId = data.createdBy;
  if (!posterId) return;
  
  // Get poster's name and room title
  let posterName = 'Someone you follow';
  try {
    const posterDoc = await db.collection('users').doc(posterId).get();
    if (posterDoc.exists) {
      const posterData = posterDoc.data() || {};
      posterName = posterData.name || 'Someone you follow';
    }
  } catch (err) {
    console.error('Failed to get poster name:', err);
  }
  
  const roomTitle = data.title || 'a new room';
  const location = data.suburb || data.city || '';
  
  // Get all followers of the poster who want notifications
  const followersSnap = await db.collection('user_follows')
    .where('followedId', '==', posterId)
    .where('notifyOnNewListing', '==', true)
    .get();
  
  if (followersSnap.empty) return;
  
  const title = 'New Room Listing';
  const body = location 
    ? `${posterName} posted "${roomTitle}" in ${location}`
    : `${posterName} posted "${roomTitle}"`;
  
  // Notify each follower
  for (const doc of followersSnap.docs) {
    const followerData = doc.data();
    const followerId = followerData.followerId;
    if (!followerId) continue;
    
    await createInAppNotification(followerId, 'new_room', title, body, posterId, {
      listingId: event.params.roomId,
      listingType: 'room',
    });
    
    await sendPushNotification(followerId, title, body);
  }
});

// When a user posts a new job, notify their followers
exports.notifyFollowersOnNewJob = onDocumentCreated('community_jobs/{jobId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  
  const posterId = data.createdBy;
  if (!posterId) return;
  
  // Get poster's name
  let posterName = 'Someone you follow';
  try {
    const posterDoc = await db.collection('users').doc(posterId).get();
    if (posterDoc.exists) {
      const posterData = posterDoc.data() || {};
      posterName = posterData.name || 'Someone you follow';
    }
  } catch (err) {
    console.error('Failed to get poster name:', err);
  }
  
  const jobTitle = data.title || 'a new job';
  const location = data.location || '';
  
  // Get all followers of the poster who want notifications
  const followersSnap = await db.collection('user_follows')
    .where('followedId', '==', posterId)
    .where('notifyOnNewListing', '==', true)
    .get();
  
  if (followersSnap.empty) return;
  
  const title = 'New Job Posting';
  const body = location 
    ? `${posterName} posted "${jobTitle}" in ${location}`
    : `${posterName} posted "${jobTitle}"`;
  
  // Notify each follower
  for (const doc of followersSnap.docs) {
    const followerData = doc.data();
    const followerId = followerData.followerId;
    if (!followerId) continue;
    
    await createInAppNotification(followerId, 'new_job', title, body, posterId, {
      listingId: event.params.jobId,
      listingType: 'job',
    });
    
    await sendPushNotification(followerId, title, body);
  }
});

// When a user posts a new marketplace item, notify their followers
exports.notifyFollowersOnNewItem = onDocumentCreated('marketplace_items/{itemId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  
  const posterId = data.userId || data.createdBy;
  if (!posterId) return;
  
  // Get poster's name
  let posterName = 'Someone you follow';
  try {
    const posterDoc = await db.collection('users').doc(posterId).get();
    if (posterDoc.exists) {
      const posterData = posterDoc.data() || {};
      posterName = posterData.name || 'Someone you follow';
    }
  } catch (err) {
    console.error('Failed to get poster name:', err);
  }
  
  const itemTitle = data.title || 'a new item';
  const price = data.price ? `$${data.price}` : '';
  
  // Get all followers of the poster who want notifications
  const followersSnap = await db.collection('user_follows')
    .where('followedId', '==', posterId)
    .where('notifyOnNewListing', '==', true)
    .get();
  
  if (followersSnap.empty) return;
  
  const title = 'New Item for Sale';
  const body = price 
    ? `${posterName} listed "${itemTitle}" for ${price}`
    : `${posterName} listed "${itemTitle}"`;
  
  // Notify each follower
  for (const doc of followersSnap.docs) {
    const followerData = doc.data();
    const followerId = followerData.followerId;
    if (!followerId) continue;
    
    await createInAppNotification(followerId, 'new_item', title, body, posterId, {
      listingId: event.params.itemId,
      listingType: 'item',
    });
    
    await sendPushNotification(followerId, title, body);
  }
});

// When someone receives a review, notify them
exports.notifyOnNewReview = onDocumentCreated('user_reviews/{reviewId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  
  const reviewerId = data.reviewerId;
  const targetUserId = data.targetUserId;
  const rating = data.rating;
  
  if (!reviewerId || !targetUserId) return;
  
  // Get reviewer's name
  let reviewerName = 'Someone';
  try {
    const reviewerDoc = await db.collection('users').doc(reviewerId).get();
    if (reviewerDoc.exists) {
      const reviewerData = reviewerDoc.data() || {};
      reviewerName = reviewerData.name || 'Someone';
    }
  } catch (err) {
    console.error('Failed to get reviewer name:', err);
  }
  
  const stars = rating ? '★'.repeat(Math.min(5, Math.max(1, Math.round(rating)))) : '';
  const title = 'New Review';
  const body = rating 
    ? `${reviewerName} left you a ${stars} review`
    : `${reviewerName} left you a review`;
  
  // Create in-app notification
  await createInAppNotification(targetUserId, 'new_review', title, body, reviewerId);
  
  // Send push notification
  await sendPushNotification(targetUserId, title, body);
});
