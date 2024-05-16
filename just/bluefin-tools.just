# vim: set ft=make :
########################
### bluefin-tools.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# Run pytorch
pytorch:
    echo 'Follow the prompts and check the tutorial: https://docs.anaconda.com/free/anaconda/jupyter-notebooks/'
    podman pull docker.io/continuumio/miniconda3
    podman run -i -t -p 8888:8888 docker.io/continuumio/miniconda3 /bin/bash -c "/opt/conda/bin/conda install jupyter -y --quiet && mkdir \
    /opt/notebooks && /opt/conda/bin/jupyter notebook \
    --notebook-dir=/opt/notebooks --ip='*' --port=8888 \
    --no-browser --allow-root"

# Run Tensorflow
tensorflow:
    echo 'Follow the prompts and check the tutorial: https://www.tensorflow.org/tutorials/quickstart/beginner'
    podman pull docker.io/tensorflow/tensorflow:latest
    podman run -it -p 8888:8888 docker.io/tensorflow/tensorflow:latest-jupyter  # Start Jupyter server

# Setup a local Ollama instance in a container. Detect hardware, offer a choice if needed.
ollama:
    #!/usr/bin/env bash
    echo 'Detecting Hardware...'
    echo
    GPU_CHOICES=("Nvidia (CUDA)" "AMD (ROCm)" "CPU (slow)")
    DETECTED_OPTIONS=()
    # Detect nvidia drivers
    if which nvidia-smi > /dev/null 2>&1; then
        DETECTED_OPTIONS+=("${GPU_CHOICES[0]}")
    fi
    # Detect AMD hardware
    if lspci | grep ' VGA ' | grep -sq AMD; then
        DETECTED_OPTIONS+=("${GPU_CHOICES[1]}")
    fi
    # Nothing detected, ask the user
    if [ ${#DETECTED_OPTIONS[@]} -eq 0 ]; then
        GPU_SELECTION=$(printf '%s\n' "${GPU_CHOICES[@]}" | gum choose --select-if-one --header "Select the type of graphics card you want to use")
    else
        GPU_SELECTION=$(printf '%s\n' "${DETECTED_OPTIONS[@]}" | gum choose --select-if-one --header "Select the type of graphics card you want to use")
    fi
    echo "Selected ${GPU_SELECTION}!"
    case "$GPU_SELECTION" in
        "Nvidia (CUDA)")
            IMAGE=latest
            CUSTOM_ARGS="AddDevice=nvidia.com/gpu=all"
            ;;

        "AMD (ROCm)")
            IMAGE=rocm
            read -r -d '' CUSTOM_ARGS <<-'EOF'
    AddDevice=/dev/dri
    AddDevice=/dev/kfd
    EOF
            ;;
        *)
            IMAGE=latest
            CUSTOM_ARGS=""
            ;;
    esac

    read -r -d '' QUADLET <<-EOF
    [Unit]
    Description=The Ollama container
    After=local-fs.target

    [Service]
    Restart=always
    TimeoutStartSec=60
    # Ensure there's a userland podman.sock
    ExecStartPre=/bin/systemctl --user enable podman.socket
    # Ensure that the dir exists
    ExecStartPre=-mkdir -p %h/.ollama

    [Container]
    ContainerName=ollama
    PublishPort=11434:11434
    RemapUsers=keep-id
    RunInit=yes
    NoNewPrivileges=no
    Network=ollama.network
    Volume=%h/.ollama:/.ollama
    PodmanArgs=--userns=keep-id
    PodmanArgs=--group-add=keep-groups
    PodmanArgs=--ulimit=host
    PodmanArgs=--security-opt=label=disable
    PodmanArgs=--cgroupns=host

    Image=docker.io/ollama/ollama:${IMAGE}
    ${CUSTOM_ARGS}

    [Install]
    RequiredBy=multi-user.target
    EOF
    if [  ! -f ~/.config/containers/systemd/ollama.container ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${QUADLET}" > ~/.config/containers/systemd/ollama.container
    else
        echo "Ollama container already exists, skipping..."
    fi

    read -r -d '' QUADLET_NETWORK <<-EOF
    [Network]
    NetworkName=ollama
    EOF
    if [  ! -f ~/.config/containers/systemd/ollama.network ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${QUADLET_NETWORK}" > ~/.config/containers/systemd/ollama.network
    else
        echo "Ollama network already exists, skipping..."
    fi

    systemctl --user daemon-reload
    systemctl --user start ollama.service || echo "Error starting Ollama Quadlet."
    echo "Please install the ollama cli via \`brew install ollama\`"

# Setup a local Ollama WebUI in a container
ollama-web: ollama
    #!/usr/bin/env bash

    read -r -d '' QUADLET <<-EOF
    [Unit]
    Description=An Ollama WebUI container
    After=network-online.target ollama.service
    Requires=ollama.service

    [Container]
    Image=ghcr.io/open-webui/open-webui:latest
    AutoUpdate=registry
    ContainerName=ollama-web
    Environment=OLLAMA_BASE_URL=http://ollama:11434
    Environment=WEBUI_SECRET_KEY=abc123
    Environment=DEFAULT_USER_ROLE=admin
    # Open WebUI does not allow access without a user account, nor does it allow
    # account creation via environment variables.
    Environment=ENABLE_SIGNUP=true
    PublishPort=8080:8080
    Network=ollama.network

    [Service]
    TimeoutStartSec=900

    [Install]
    WantedBy=multi-user.target
    EOF
    if [  ! -f ~/.config/containers/systemd/ollama-web.container ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${QUADLET}" > ~/.config/containers/systemd/ollama-web.container
    else
        echo "Ollama WebUI container already exists, skipping..."
    fi
    systemctl --user daemon-reload
    systemctl --user start ollama-web.service
