# Code Generation Application

  This recipe helps developers start building their own custom LLM enabled code generation applications. It consists of two main components: the Model Service and the AI Application.

  There are a few options today for local Model Serving, but this recipe will use [`llama-cpp-python`](https://github.com/abetlen/llama-cpp-python) and their OpenAI compatible Model Service. There is a Containerfile provided that can be used to build this Model Service within the repo, [`model_servers/llamacpp_python/base/Containerfile`](/model_servers/llamacpp_python/base/Containerfile).

  The AI Application will connect to the Model Service via its OpenAI compatible API. The recipe relies on [LangChain's](https://python.langchain.com/docs/get_started/introduction) python package to simplify communication with the Model Service and uses [Streamlit](https://streamlit.io/) for the UI layer. The application and bootc images are built on UBI 10 and RHEL 10 base images from `registry.redhat.io` (a RHEL subscription is required). You can find an example of the code generation application below.

![](/assets/codegen_ui.png)


## Try the Code Generation Application

The [Podman Desktop](https://podman-desktop.io) [AI Lab Extension](https://github.com/containers/podman-desktop-extension-ai-lab) includes this recipe among others. To try it out, open `Recipes Catalog` -> `Code Generation` and follow the instructions to start the application.

# Build the Application

The rest of this document will explain how to build and run the application from the terminal, and will
go into greater detail on how each container in the Pod above is built, run, and
what purpose it serves in the overall application. All the recipes use a central [Makefile](../../common/Makefile.common) that includes variables populated with default values to simplify getting started. Please review the [Makefile docs](../../common/README.md), to learn about further customizing your application.


This application requires a model, a model service and an AI inferencing application.

* [Quickstart](#quickstart)
* [Download a model](#download-a-model)
* [Build the Model Service](#build-the-model-service)
* [Deploy the Model Service](#deploy-the-model-service)
* [Build the AI Application](#build-the-ai-application)
* [Deploy the AI Application](#deploy-the-ai-application)
* [Interact with the AI Application](#interact-with-the-ai-application)
* [Embed the AI Application in a Bootable Container Image](#embed-the-ai-application-in-a-bootable-container-image)


## Quickstart
To run the application with pre-built images from `quay.io/ai-lab`, use `make quadlet`. This command
builds the application's metadata and generates Kubernetes YAML at `./build/codegen.yaml` to spin up a Pod that can then be launched locally.
Try it with:

```
make quadlet
podman kube play build/codegen.yaml
```

This will take a few minutes if the model and model-server container images need to be downloaded.
The Pod is named `codegen`, so you may use [Podman](https://podman.io) to manage the Pod and its containers:

```
podman pod list
podman ps
```

Once the Pod and its containers are running, the application can be accessed at `http://localhost:8501`.
Please refer to the section below for more details about [interacting with the codegen application](#interact-with-the-ai-application).

To stop and remove the Pod, run:

```
podman pod stop codegen
podman pod rm codgen
```

## Download a model

If you are just getting started, we recommend using [Mistral-7B-code-16k-qlora](https://huggingface.co/Nondzu/Mistral-7B-code-16k-qlora). This is a well
performant mid-sized model with an apache-2.0 license fine tuned for code generation. In order to use it with our Model Service we need it converted
and quantized into the [GGUF format](https://github.com/ggerganov/ggml/blob/master/docs/gguf.md). There are a number of
ways to get a GGUF version of Mistral-7B-code-16k-qlora, but the simplest is to download a pre-converted one from
[huggingface.co](https://huggingface.co) here: https://huggingface.co/TheBloke/Mistral-7B-Code-16K-qlora-GGUF.

There are a number of options for quantization level, but we recommend `Q4_K_M`.

The recommended model can be downloaded using the code snippet below:

```bash
cd ../../../models
curl -sLO https://huggingface.co/TheBloke/Mistral-7B-Code-16K-qlora-GGUF/resolve/main/mistral-7b-code-16k-qlora.Q4_K_M.gguf
cd ../recipes/natural_language_processing/codgen
```

_A full list of supported open models is forthcoming._


## Build the Model Service

The complete instructions for building and deploying the Model Service can be found in the
[llamacpp_python model-service document](../../../model_servers/llamacpp_python/README.md).

The Model Service can be built from make commands from the [llamacpp_python directory](../../../model_servers/llamacpp_python/).

```bash
# from path model_servers/llamacpp_python from repo containers/ai-lab-recipes
make build
```
Checkout the [Makefile](../../../model_servers/llamacpp_python/Makefile) to get more details on different options for how to build.

## Deploy the Model Service

The local Model Service relies on a volume mount to the localhost to access the model files. It also employs environment variables to dictate the model used and where its served. You can start your local Model Service using the following `make` command from `model_servers/llamacpp_python` set with reasonable defaults:

```bash
# from path model_servers/llamacpp_python from repo containers/ai-lab-recipes
make run
```

## Build the AI Application

The AI Application is built on `registry.redhat.io/ubi10/python-312-minimal`. Log in to the registry first:

```bash
podman login registry.redhat.io
```

Then build the container image:

```bash
cd app
podman build -t codegen-app:latest .
```

## Deploy the AI Application

Make sure the Model Service is up and running before starting this container image. When starting the AI Application container image we need to direct it to the correct `MODEL_ENDPOINT`. This could be any appropriately hosted Model Service (running locally or in the cloud) using an OpenAI compatible API. In our case the Model Service is running inside the Podman machine so we need to provide it with the appropriate address `10.88.0.1`. To deploy the AI application use the following:

```bash
# Run this from the current directory (path recipes/natural_language_processing/codegen from repo containers/ai-lab-recipes)
make run
```

## Interact with the AI Application

Everything should now be up an running with the code generation application available at [`http://localhost:8501`](http://localhost:8501). By using this recipe and getting this starting point established, users should now have an easier time customizing and building their own LLM enabled code generation applications.

## Embed the AI Application in a Bootable Container Image

To build a bootable container image that includes this sample code generation workload as a service
that starts when a system is booted, build the bootc image from the [bootc](bootc/) directory.
The base image is `registry.redhat.io/rhel10/rhel-bootc` and the build requires a RHEL subscription on the
build host. See the [bootc/README.md](bootc/README.md) for full details.

The image uses RHEL 10's logically-bound images to pre-fetch workload containers
during installation. No special build flags (`--cap-add`, `--device`) are needed:

```bash
cd bootc
podman build --build-arg "SSHPUBKEY=$(cat ~/.ssh/id_rsa.pub)" \
           -t localhost/codegen-bootc:latest .
```

To convert the bootc image to a qcow2 disk image for KVM testing, use
`bootc-image-builder`. The workload images must be pre-pulled on the host first:

```bash
# Pre-pull workload images
podman pull quay.io/ai-lab/codegen:latest
podman pull quay.io/ai-lab/llamacpp_python:latest
podman pull quay.io/ai-lab/mistral-7b-code-16k-qlora:latest

# Convert to qcow2
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

Once you have a bootc-enabled system running, update it to the image you just built by ssh-ing in and running:

```bash
bootc switch quay.io/yourrepo/codegen-bootc:latest
```

Upon a reboot, the codegen service will be running on the system. Check on the service with:

```bash
ssh user@bootc-system-ip
sudo systemctl status codegen
```

### What are bootable containers?

What's a [bootable OCI container](https://containers.github.io/bootc/) and what's it got to do with AI?

That's a good question! We think it's a good idea to embed AI workloads (or any workload!) into bootable images at _build time_ rather than
at _runtime_. This extends the benefits, such as portability and predictability, that containerizing applications provides to the operating system.
Bootable OCI images bake exactly what you need to run your workloads into the operating system at build time by using your favorite containerization
tools. Might I suggest [podman](https://podman.io/)?

Once installed, a bootc enabled system can be updated by providing an updated bootable OCI image from any OCI
image registry with a single `bootc` command. This works especially well for fleets of devices that have fixed workloads - think
factories or appliances. Who doesn't want to add a little AI to their appliance, am I right?

Bootable images lend toward immutable operating systems, and the more immutable an operating system is, the less that can go wrong at runtime!

#### Creating bootable disk images

You can convert a bootc image to a bootable disk image using the
[bootc-image-builder](https://github.com/osbuild/bootc-image-builder) container image
(`registry.redhat.io/rhel10/bootc-image-builder`). See [bootc/README.md](bootc/README.md)
for the complete build workflow including `config.toml` and pre-pull steps.
