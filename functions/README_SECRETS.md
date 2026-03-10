## Functions service account (secrets)

This repository must not contain production service-account JSON files. The file `functions/serviceAccountKey.json` was removed from the repository and should be provided to CI or your deployment environment as a secret.

Recommended approach (GitHub Actions):

- Add a repository secret named `FUNCTIONS_SERVICE_ACCOUNT` containing the entire service account JSON content.
- Add a secret `FIREBASE_TOKEN` for `firebase deploy` (or use a different deploy method).
- The included workflow `.github/workflows/deploy-functions.yml` demonstrates writing the secret to `functions/serviceAccountKey.json` at runtime and setting `GOOGLE_APPLICATION_CREDENTIALS` so the Admin SDK uses ADC.

Local development:

- For local testing, set `GOOGLE_APPLICATION_CREDENTIALS` to a path on your machine that contains the JSON (outside the repo), e.g.:

```
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/serviceAccountKey.json
```

- Do NOT commit that file to source control.

If you use another CI system, replicate the same pattern: store the JSON content as a secure variable, write it to a temporary file during the job, set `GOOGLE_APPLICATION_CREDENTIALS` to that path, then remove the file after deployment.
