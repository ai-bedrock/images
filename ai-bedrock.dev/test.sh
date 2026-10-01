#!/usr/bin/env bash
# Tests a built image of the website's files by serving it with the current nginx image (its stable tag, next to
# this image on the registry) through nginx's own test: nginx/test.sh. Usage: ai-bedrock.dev/test.sh <image>.
set -euo pipefail

image=${1:?usage: $0 <site image>}
exec "$(cd "$(dirname "$0")" && pwd)/../nginx/test.sh" "${image%/*}/nginx:stable" "$image"
