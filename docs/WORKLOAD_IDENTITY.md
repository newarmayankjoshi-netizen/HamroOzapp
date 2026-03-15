Workload Identity Federation setup (GitHub Actions)
===============================================

This document shows the commands to configure Workload Identity Federation so GitHub Actions can impersonate a GCP service account without long-lived JSON keys.

Repository detected: newarmayankjoshi-netizen/HamroOzapp
GCP project (used in examples): `nepalese-in-australia`

Important: replace the placeholders `REPLACE_PROJECT_NUMBER` and `REPLACE_SERVICE_ACCOUNT_EMAIL` with real values.

1) Get your GCP project number:

```bash
gcloud projects describe nepalese-in-australia --format='value(projectNumber)'
# copy the printed number into the workflow's PROJECT_NUMBER env
```

2) Create a Workload Identity Pool:

```bash
gcloud iam workload-identity-pools create gha-pool \
  --project=nepalese-in-australia --location="global" \
  --display-name="GitHub Actions pool for newarmayankjoshi-netizen/HamroOzapp"
```

3) Create the OIDC provider for GitHub Actions:

```bash
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --project=nepalese-in-australia \
  --workload-identity-pool=gha-pool \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --allowed-audiences="https://github.com/newarmayankjoshi-netizen/HamroOzapp" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository"
```

4) Allow the GitHub repo to impersonate the GCP service account:

First find your `PROJECT_NUMBER` (from step 1) and your `SERVICE_ACCOUNT_EMAIL` (the service account you want GitHub to act as). Then run:

```bash
gcloud iam service-accounts add-iam-policy-binding SERVICE_ACCOUNT_EMAIL \
  --project=nepalese-in-australia \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/gha-pool/attribute.repository/newarmayankjoshi-netizen/HamroOzapp"
```

5) Update the workflow

- Open `.github/workflows/wif-smoke.yml` and replace `REPLACE_PROJECT_NUMBER` with your project number and `REPLACE_SERVICE_ACCOUNT_EMAIL` with the service account email.
- Commit and push the workflow.

6) Run the workflow

- Trigger the workflow via the GitHub Actions UI (workflow_dispatch) or push to `main`.
- The `Authenticate to Google Cloud using Workload Identity` step will exchange the GitHub OIDC token for short-lived credentials impersonating the specified service account.

7) Smoke tests

- The example workflow lists storage buckets and optionally runs `./ci/run_smoke_tests.sh` if present. Replace or extend it with whatever small checks you need (Vision quick request, Firestore read, etc.).

8) Follow-up

- Remove any remaining JSON keys from Secret Manager / CI secrets.
- Confirm team members and CI can perform their jobs. When ready, you can delete the `backup-before-purge` branch from the remote if you no longer need it.

If you want, I can commit the updated workflow values for you if you provide `PROJECT_NUMBER` and `SERVICE_ACCOUNT_EMAIL` now. I can also create a small `ci/run_smoke_tests.sh` that runs a quick Dart script to call Vision/Storage (if you want that added).
