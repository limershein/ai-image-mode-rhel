#!/bin/bash
# Configure /usr/lib/bootc/storage as an additional image store so podman
# can find the logically-bound images that bootc pre-fetched during install.
set -euo pipefail

CONF=/etc/containers/storage.conf

if grep -q '/usr/lib/bootc/storage' "${CONF}" 2>/dev/null; then
    echo "Additional image store already configured."
    exit 0
fi

if [[ ! -f "${CONF}" ]]; then
    cp /usr/share/containers/storage.conf "${CONF}"
fi

sed -i -e '/additionalimagestores = \[/a\  "/usr/lib/bootc/storage",' "${CONF}"
echo "Configured /usr/lib/bootc/storage as additional image store."
