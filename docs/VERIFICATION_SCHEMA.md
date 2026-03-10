# Identity Verification — Firestore Schema

This document describes the proposed Firestore schema, Storage layout, and minimal server/client responsibilities for the contributor verification flow.

Goals
- Support contributor levels (0..3) for permissioning
- Record submission history, OCR / fraud check results, and reviewer decisions
- Allow admins to review, approve, reject with structured reasons
- Allow auto-reject rules for obvious invalid uploads

Collections & Documents

1) `users/{userId}` (existing)
- `contributorLevel` (int) — 0 (Basic), 1 (Pending), 2 (Verified), 3 (Trusted)
- `verifiedBadge` (bool) — convenience flag (derived from contributorLevel >= 2)
- `verificationSummary` (map) — optional: {lastSubmissionId, lastStatus, lastReviewedAt}

2) `users/{userId}/id_submissions/{submissionId}` (subcollection)
Each submission documents one upload attempt.
- `type` (string) — enum: `passport`, `aus_driver_license`, `aus_photo_id`, `international_passport`, `immicard`, `other`
- `imageUrl` (string) — Storage download URL or path (e.g. `verification/{userId}/{submissionId}.jpg`)
- `status` (string) — `pending`, `approved`, `rejected`, `auto_rejected`
- `reason` (string?) — human-readable or one of the codes below
- `reviewerId` (string?) — admin uid who reviewed
- `reviewedAt` (timestamp?)
- `createdAt` (timestamp)
- `ocr` (map) — lightweight OCR results:
  - `hasFace`: bool
  - `extractedName`: string?
  - `extractedDob`: string?
  - `extractedDocumentNumber`: string?
  - `extractedCountryOrState`: string?
  - `textDetected`: bool
  - `blurScore`: double? (0..1, higher = blurrier)
  - `screenshotLikely`: bool
- `fraudChecks` (map) — heuristic checks and short messages

3) `admin/verification_audit/{auditId}` (optional)
- Records approvals/rejections for analytics and appeals

Storage layout
- `verification/{userId}/{submissionId}.[jpg|png|webp]`

Submission flow (client)
1. User chooses document type from allowed list.
2. User uploads image (camera or gallery). Client does light checks (size, extension).
3. Client uploads file to Storage under `verification/{userId}/{submissionId}` and writes a `id_submissions/{submissionId}` doc with `status: pending` and `imageUrl` set to the Storage path (or signed URL).

Server / Cloud Function responsibilities
- Trigger on write to `id_submissions` (onCreate)
- Run Vision/OCR (Google Cloud Vision or other) and compute `ocr` + `fraudChecks`
- If automatic fraud reasons found (wrong doc type, screenshot, no face, extreme blur) set `status: auto_rejected` and add `reason`
- Else leave `status: pending` for manual admin review
- On admin decision, function sets `contributorLevel` on `users/{userId}` (admins only should be allowed by rules)

Admin review UI
- List `id_submissions` where `status == pending` (use collection group query) ordered by `createdAt`
- Admin sees OCR/fraud hints, extracted fields, image preview, and selects an approval reason or rejection reason from enums

Reason enums (examples)
- Approval reasons:
  - `valid_passport`
  - `valid_aus_id`
  - `valid_international_id`
  - `verified_manually`
- Rejection reasons:
  - `invalid_document`
  - `not_govt_id`
  - `blurry_image`
  - `wrong_person`
  - `duplicate_account`
  - `screenshot_detected`

Auto-reject on client (document-type filtering)
- If user selects `Student ID`, `Bank card`, `Library card`, `Medicare card`, client should reject locally and show an explanation: "This document cannot be used for identity verification. Please upload a government-issued ID."

Security & Rules (high-level)
- Writes to `users/{userId}/id_submissions` allowed by the owner (authenticated user) only.
- Only admin role can edit `status` to `approved` or `rejected`, or set `contributorLevel` on `users/{userId}`.
- Cloud Function service account may update submission docs to add `ocr` and `fraudChecks` and to auto-reject.

Sample minimal Firestore rules snippet
```rules
match /users/{userId}/id_submissions/{subId} {
  allow create: if request.auth != null && request.auth.uid == userId;
  allow read: if request.auth != null && (request.auth.uid == userId || isAdmin(request.auth.uid));
  allow update: if isAdmin(request.auth.uid) || (request.auth.uid == userId && request.resource.data.keys().hasOnly(['status']) == false);
}

match /users/{userId} {
  allow update: if isAdmin(request.auth.uid) || (request.auth.uid == userId && !(request.resource.data.keys().hasAny(['contributorLevel'])));
}

function isAdmin(uid) {
  return get(/databases/$(database)/documents/admins/$(uid)).exists();
}
```

Indexes
- Collection group query on `id_submissions` where `status == pending` and order by `createdAt` will need a single-field index (collection group indexes are supported by default for `==` and `orderBy`). If you order on other fields add composite indexes via `firestore.indexes.json`.

Notes & Next Steps
- Implement Cloud Function starter (Vision API) to fill `ocr` and `fraudChecks` and auto-reject obvious cases.
- Implement client-side upload UI with enforced document-type selection and local rejection for disallowed types.
- Implement admin review page and APIs to set `contributorLevel`.

End of schema design.
