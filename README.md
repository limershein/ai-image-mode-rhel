# AI Image Mode for RHEL 10

A port of the [codegen](https://github.com/containers/ai-lab-recipes/tree/main/recipes/natural_language_processing/codegen)
recipe from [containers/ai-lab-recipes](https://github.com/containers/ai-lab-recipes)
to RHEL 10 image mode (bootc) with UBI 10 application containers.

This project demonstrates embedding an LLM-powered code generation application
into a bootable RHEL 10 disk image using logically-bound images for offline
workload pre-loading.

## What's included

- **`codegen/app/`** — Streamlit + LangChain code generation app (UBI 10, Python 3.12)
- **`codegen/bootc/`** — RHEL 10 bootc image with logically-bound workload containers
- **`build-qcow2.sh`** — Builds the bootc image and converts to qcow2
- **`launch-vm.sh`** — Launches a KVM VM from the qcow2 for testing
- **`config.toml`** — bootc-image-builder configuration (SSH key, disk size)

## Quick start

```bash
# Log in to the Red Hat registry (RHEL subscription required)
podman login registry.redhat.io

# Build the bootc image, pre-pull workloads, and create a qcow2 disk
sudo bash build-qcow2.sh

# Launch a KVM VM
sudo bash launch-vm.sh
```

See [codegen/README.md](codegen/README.md) and
[codegen/bootc/README.md](codegen/bootc/README.md) for detailed instructions.

## Attribution

This project is a port of work originally created by contributors to the
[containers/ai-lab-recipes](https://github.com/containers/ai-lab-recipes)
project, licensed under the Apache License 2.0. The original codegen recipe
and bootc integration were authored by:

- Daniel J Walsh <dwalsh@redhat.com>
- Sally O'Malley <somalley@redhat.com>
- Gregory Pereira <grpereir@redhat.com>
- Colin Walters <walters@verbum.org>
- thepetk <thepetk@gmail.com>

Ported to RHEL 10 / UBI 10 by:

- Louis Imershein <limershe@redhat.com>
- Claude Opus 4.6 (Anthropic) — AI coding assistant

## License

[Apache License 2.0](LICENSE) — same as the upstream project.
