#!/bin/bash
set -euo pipefail

QCOW2_SRC=/home/limershe/src/ai-image-mode-rhel/output/qcow2/disk.qcow2
QCOW2_DST=/var/lib/libvirt/images/codegen-bootc.qcow2
VM_NAME=codegen-bootc

# Clean up any existing VM with the same name
if virsh dominfo "${VM_NAME}" &>/dev/null; then
  echo "==> Removing existing VM ${VM_NAME}..."
  virsh destroy "${VM_NAME}" 2>/dev/null || true
  virsh undefine "${VM_NAME}" --remove-all-storage 2>/dev/null || true
fi

echo "==> Copying qcow2 to libvirt images directory..."
cp "${QCOW2_SRC}" "${QCOW2_DST}"

echo "==> Creating and starting VM..."
virt-install \
  --name "${VM_NAME}" \
  --memory 8192 \
  --vcpus 4 \
  --disk "${QCOW2_DST}" \
  --import \
  --os-variant rhel10-unknown \
  --network default \
  --graphics none \
  --console pty,target_type=serial \
  --noautoconsole

echo "==> VM '${VM_NAME}' started. Waiting for IP..."
for i in $(seq 1 60); do
  IP=$(virsh domifaddr "${VM_NAME}" 2>/dev/null | awk '/ipv4/ {split($4, a, "/"); print a[1]}')
  if [[ -n "${IP}" ]]; then
    echo "==> VM IP: ${IP}"
    echo ""
    echo "SSH:  ssh -o StrictHostKeyChecking=no root@${IP}"
    echo "App:  http://${IP}:8501"
    exit 0
  fi
  sleep 5
done

echo "==> Timed out waiting for IP. Check 'virsh domifaddr ${VM_NAME}'"
