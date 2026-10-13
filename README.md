# svg-encoder
[![Build Status](https://drone.maniacbox.synology.me/api/badges/mvogtherr/svg-encoder/status.svg?ref=refs/heads/main)](https://drone.maniacbox.synology.me/mvogtherr/svg-encoder)

Encode a given SVG as less as necessary to make in work in (S)CSS

Lab staging and pull-request previews run through Woodpecker (`.woodpecker/`)
and `platform-deploy` on the shared web platform. Production on
svg-encoder.com still uses the legacy Drone pipeline in `.drone.yml` until that
hosting channel is retired. Do not delete `.drone.yml` while the public site
depends on it. Disable the Drone `deploy-to-test` (NAS) job in the Drone UI if
it still fires on `main`; Woodpecker staging replaced that path.
