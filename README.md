# svg-encoder

Encode a given SVG as less as necessary to make in work in (S)CSS

Lab staging and pull-request previews run through Woodpecker (`.woodpecker/`)
and `platform-deploy` on the shared web platform.

GHCR images are `ghcr.io/dafailer/svg-encoder:X.Y.Z` from the root `VERSION`
file, plus `:latest` on the newest release. Open PRs tag `pr-<PR>`; CI deletes
those versions after merge, close, or draft. Staging and production keep using
digest pins. Do not bump `VERSION` for docs-only changes.
