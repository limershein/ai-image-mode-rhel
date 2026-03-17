## Embed workload (AI sample applications) in a bootable container image

### Create a custom RHEL 10 bootc image

* [Containerfile](./Containerfile) - embeds an LLM-powered sample code generation application.

Details on the application can be found [in the codegen/README.md](../README.md). By default, this Containerfile includes a model-server
that is meant to run with CPU - no additional GPU drivers or toolkits are embedded. You can substitute the llamacpp_python model-server image
for one that has GPU drivers and toolkits with additional build-args. The `FROM` must be replaced with a base image that has the necessary
kernel drivers and toolkits if building for GPU enabled systems. For an example of an NVIDIA/CUDA base image,
see [NVIDIA bootable image example](https://gitlab.com/bootc-org/examples/-/tree/main/nvidia?ref_type=heads)

In order to pre-pull the workload images, you need to build from the same architecture you're building for.
If not pre-pulling the workload images, you can cross build (ie, build from a Mac for an X86_64 system).
To build the derived bootc image for x86_64 architecture, run the following:

The build host must have a RHEL subscription, as the Containerfile pulls from
`registry.redhat.io` and installs packages via `dnf` during the build. Log in
to the registry before building:

```bash
podman login registry.redhat.io
```

Then build the image. The `--device /dev/fuse` flag is required because the
Containerfile installs `fuse-overlayfs` to support nested `podman pull`
operations during the build (kernel overlayfs cannot stack on the build's
own overlayfs layer):

```bash
cd codegen/bootc

# for CPU powered sample LLM application
# to switch to an alternate platform like aarch64, pass --platform linux/arm64
# --cap-add SYS_ADMIN is needed for nested podman pulls during the build.
# --device /dev/fuse is needed for fuse-overlayfs inside the build container.
# If the registry you are pulling workload images from requires authentication,
# volume mount the auth.json file with SELinux separation disabled.
podman build --build-arg "SSHPUBKEY=$(cat ~/.ssh/id_rsa.pub)" \
           --security-opt label=disable \
           --cap-add SYS_ADMIN \
           --device /dev/fuse \
           -t quay.io/yourrepo/youros:tag .

# for GPU powered sample LLM application with llamacpp cuda model server
podman build --build-arg "SSHPUBKEY=$(cat ~/.ssh/id_rsa.pub)" \
           --build-arg "SERVER_IMAGE=quay.io/ai-lab/llamacpp-python-cuda:latest" \
           --from <YOUR BOOTABLE IMAGE WITH NVIDIA/CUDA> \
           --cap-add SYS_ADMIN \
           --device /dev/fuse \
           --platform linux/amd64 \
           -t quay.io/yourrepo/youros:tag .

podman push quay.io/yourrepo/youros:tag
```

### Update a bootc-enabled system with the new derived image

To build a disk image from an OCI bootable image, you can refer to [bootc-org/examples](https://gitlab.com/bootc-org/examples).
For this example, we will assume a bootc enabled system is already running.
If already running a bootc-enabled OS, `bootc switch` can be used to update the system to target a new bootable OCI image with embedded workloads.

SSH into the bootc-enabled system and run:

```bash
bootc switch quay.io/yourrepo/youros:tag
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

To stop the sample applications, SSH into the bootc system and run:

```bash
systemctl stop codegen
```

To run the sample application _not_ as a systemd service, stop the services then
run the appropriate commands based on the application you have embedded.

```bash
podman kube play /usr/share/containers/systemd/codegen.yaml
```
