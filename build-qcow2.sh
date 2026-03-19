#!/bin/bash
set -euo pipefail

BASEDIR=/home/limershe/src/ai-image-mode-rhel
BOOTC_DIR="${BASEDIR}/codegen/bootc"
IMAGE_NAME=localhost/codegen-bootc:latest

echo "==> Building bootc image..."
podman build \
  --build-arg "SSHPUBKEY=$(cat /home/limershe/.ssh/id_rsa.pub)" \
  -f "${BOOTC_DIR}/Containerfile" \
  -t "${IMAGE_NAME}" \
  "${BOOTC_DIR}"

echo "==> Pre-pulling workload images (needed for logically-bound images)..."
podman pull quay.io/ai-lab/codegen:latest
podman pull quay.io/ai-lab/llamacpp_python:latest
podman pull quay.io/ai-lab/mistral-7b-code-16k-qlora:latest

echo "==> Removing previous output..."
rm -rf "${BASEDIR}/output"
mkdir -p "${BASEDIR}/output"

echo "==> Converting bootc image to qcow2..."
echo "    (bootc-image-builder will pre-fetch logically-bound images)"
podman run --rm -it --privileged \
  --security-opt label=type:unconfined_t \
  -v "${BASEDIR}/output:/output" \
  -v "${BASEDIR}/config.toml:/config.toml:ro" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  registry.redhat.io/rhel10/bootc-image-builder:latest \
  --type qcow2 \
  --config /config.toml \
  --rootfs ext4 \
  "${IMAGE_NAME}"
