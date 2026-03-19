## Embed workload (AI sample applications) in a bootable container image

### Create a custom RHEL 10 bootc image

* [Containerfile](./Containerfile) - embeds an LLM-powered sample code generation application.

Details on the application can be found [in the codegen/README.md](../README.md). By default, this Containerfile includes a model-server
that is meant to run with CPU - no additional GPU drivers or toolkits are embedded. You can substitute the llamacpp_python model-server image
for one that has GPU drivers and toolkits with additional build-args. The `FROM` must be replaced with a base image that has the necessary
kernel drivers and toolkits if building for GPU enabled systems. For an example of an NVIDIA/CUDA base image,
see [NVIDIA bootable image example](https://gitlab.com/bootc-org/examples/-/tree/main/nvidia?ref_type=heads)

The build host must have a RHEL subscription, as the Containerfile pulls from
`registry.redhat.io`. Log in to the registry before building:

```bash
podman login registry.redhat.io
```

#### How pre-loading works

This image uses RHEL 10's **logically-bound images** feature to pre-load
workload containers. Individual `.image` quadlet files for each workload are
symlinked into `/usr/lib/bootc/bound-images.d/`. When the image is installed
(via `bootc install` or `bootc-image-builder`), bootc automatically pre-fetches
the bound images into `/usr/lib/bootc/storage`.

A first-boot systemd service (`configure-image-store.service`) registers
`/usr/lib/bootc/storage` as an additional image store in
`/etc/containers/storage.conf` so podman can see the pre-fetched images. This
runtime configuration is necessary because bootc-image-builder's osbuild sandbox
validates all `additionalimagestores` paths and fails if they are baked into the
image.

The workload images must also be pre-pulled on the build host before running
bootc-image-builder so they are available in `/var/lib/containers/storage`
(which is bind-mounted into the builder).

#### Build the bootc image

```bash
cd codegen/bootc

podman build --build-arg "SSHPUBKEY=$(cat ~/.ssh/id_rsa.pub)" \
           -t localhost/codegen-bootc:latest .
```

#### Pre-pull workload images on the host

```bash
podman pull quay.io/ai-lab/codegen:latest
podman pull quay.io/ai-lab/llamacpp_python:latest
podman pull quay.io/ai-lab/mistral-7b-code-16k-qlora:latest
```

#### Convert to a disk image

Use [bootc-image-builder](https://github.com/osbuild/bootc-image-builder)
(`registry.redhat.io/rhel10/bootc-image-builder`) to convert the bootc image
to a qcow2, AMI, or other disk format:

```bash
podman run --rm -it --privileged \
  --security-opt label=type:unconfined_t \
  -v ./output:/output \
  -v ./config.toml:/config.toml:ro \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  registry.redhat.io/rhel10/bootc-image-builder:latest \
  --type qcow2 \
  --config /config.toml \
  --rootfs ext4 \
  localhost/codegen-bootc:latest
```

A `config.toml` should include your SSH public key and a root filesystem size
large enough for the OS plus all pre-loaded workload images (30 GiB recommended):

```toml
[[customizations.filesystem]]
mountpoint = "/"
minsize = "30 GiB"

[[customizations.user]]
name = "root"
key = "ssh-rsa AAAA..."
```

A convenience script (`build-qcow2.sh`) in the repo root combines all the above
steps.

### Update a bootc-enabled system with the new derived image

If already running a bootc-enabled OS, `bootc switch` can be used to update the system to target a new bootable OCI image with embedded workloads.

SSH into the bootc-enabled system and run:

```bash
bootc switch quay.io/yourrepo/codegen-bootc:latest
```

The necessary image layers will be downloaded from the OCI registry, and the system will prompt you to reboot into the new operating system.
From this point, with any subsequent modifications and pushes to the `quay.io/yourrepo/youreos:tag` OCI image, your OS can be updated with:

```bash
bootc upgrade
```

### Accessing the embedded workloads

The codegen application can be accessed by visiting port `8501` of the running bootc system.
The workloads run as systemd services from Podman quadlet files placed at `/usr/share/containers/systemd/` on the bootc system.
For more information about running containerized applications as systemd services with Podman, refer to the
[Podman quadlet post](https://www.redhat.com/sysadmin/quadlet-podman) or the [Podman documentation](https://podman.io/docs).

To monitor the sample applications, SSH into the bootc system and run either:

```bash
systemctl status codegen
```

You can also view the pods and containers that are managed with systemd by running:

```
podman pod list
podman ps -a
```

To verify that the pre-loaded images are available (shown as read-only):

```bash
podman images
```

To stop the sample applications, SSH into the bootc system and run:

```bash
systemctl stop codegen
```

To run the sample application _not_ as a systemd service, stop the services then
run the appropriate commands based on the application you have embedded.

```bash
podman kube play /usr/share/containers/systemd/codegen.yaml
```
