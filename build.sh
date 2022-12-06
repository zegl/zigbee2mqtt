#!/bin/bash

set -euo pipefail

#nvm use 18
# echo "[x] zigbee-herdsman"
# pushd ./vendor/zigbee-herdsman
# npm install
# npm run build
# popd
# 
# echo "[x] zigbee-herdsman-converters"
# pushd ./vendor/zigbee-herdsman-converters
# npm install
# popd
# 
# echo "[x] zigbee2mqtt"
# npm install

echo "[x] docker"
docker buildx build \
    --target=release \
    --build-arg=base=debian \
    -t zegl/zigbee2mqtt:latest-dev-debian \
    -f docker/Dockerfile \
    --push --platform=linux/arm/v7 \
    .
