# Homebrew cask installs gcloud-cli's additional components (e.g.
# gke-gcloud-auth-plugin) under share/google-cloud-sdk/bin, which is not on
# PATH by default.
add_path "${HOMEBREW_PREFIX:-/opt/homebrew}"/share/google-cloud-sdk/bin(N-/)
