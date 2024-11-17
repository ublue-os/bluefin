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

# alias for install-pytorch
[group('Tools')]
pytorch:
    @ujust install-pytorch

# Run pytorch
[group('Tools')]
install-pytorch:
    echo 'Follow the prompts and check the tutorial: https://docs.anaconda.com/free/anaconda/jupyter-notebooks/'
    podman run --pull=newer -it -p 8888:8888 docker.io/continuumio/miniconda3 /bin/bash -c "/opt/conda/bin/conda install jupyter -y --quiet && mkdir \
    /opt/notebooks && /opt/conda/bin/jupyter notebook \
        --notebook-dir=/opt/notebooks --ip='*' --port=8888 \
        --no-browser --allow-root"

# alias for install-tensorflow
[group('Tools')]
tensorflow:
    @ujust install-tensorflow

# Run Tensorflow
[group('Tools')]
install-tensorflow:
    echo 'Follow the prompts and check the tutorial: https://www.tensorflow.org/tutorials/quickstart/beginner'
    podman pull docker.io/tensorflow/tensorflow:latest
    podman run --pull=newer -it -p 8888:8888 docker.io/tensorflow/tensorflow:latest-jupyter  # Start Jupyter server

# alias for setup-ollama
[group('Tools')]
ollama:
    @ujust setup-ollama

# Setup a local Ollama instance in a container. Detect hardware, offer a choice if needed.
[group('Tools')]
setup-ollama ACTION="help":
    #!/usr/bin/env bash
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust ollama <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'install' to Install ollama container"
      echo "  Use 'install-open-webui' to Install open-webui container"
      echo "  Use 'remove' to remove the ollama container"
      echo "  Use 'remove-open-webui' to remove the open-webui container and persistent volume"
      exit 0
    #elif [ "$OPTION" == "" ]; then
    #  echo "${bold}ollama setup and configuration${normal}"
    #  #OPTION=$(Choose "install" "install-open-webui" "remove" "remove-open-webui")
    fi
    if [ "${OPTION}" == "install" ]; then
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
        echo "ollama container already exists, skipping..."
    fi

    read -r -d '' QUADLET_NETWORK <<-EOF
    [Network]
    NetworkName=ollama
    EOF
    if [  ! -f ~/.config/containers/systemd/ollama.network ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${QUADLET_NETWORK}" > ~/.config/containers/systemd/ollama.network
    else
        echo "ollama network already exists, skipping..."
    fi

    systemctl --user daemon-reload
    echo "Please install the ollama cli via \`brew install ollama\`"
        exit 0
    fi
    if [[ "${OPTION,,}" == "install-open-webui" ]]; then
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
    Environment=WEBUI_AUTH=false
    Volume=open-webui:/app/backend/data
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
        echo "open-webui container already exists, skipping..."
    fi
    systemctl --user daemon-reload
    echo "Ollama Open WebUI service installed."
    elif [[ "${OPTION,,}" == "remove" ]]; then
        echo "Removing ollama container"
        echo "stopping ollama Quadlet"
        systemctl --user stop ollama.service || echo "Error stopping ollama Quadlet."
        rm ~/.config/containers/systemd/ollama.container || echo "Error removing ollama container"
        rm ~/.config/containers/systemd/ollama.network || echo "Error removing ollama network"
        systemctl --user daemon-reload
        echo "ollama Quadlet removed"
    elif [[ "${OPTION,,}" == "remove-open-webui" ]]; then
        echo "Removing open-webui container"
        echo "stopping open-webui Quadlet"
        systemctl --user stop ollama-web.service || echo "Error stopping open-webui Quadlet."
        rm ~/.config/containers/systemd/ollama-web.container
        echo "removing open-webui persistent volume"
        podman volume rm open-webui > /dev/null
        systemctl --user daemon-reload
        echo "open-webui Quadlet removed"
    fi

# alias for install-invokeai
[group('Tools')]
invokeai:
    @ujust install-invokeai

# Set up InvokeAI, a stable diffusion engine used for visual media, in a local container
[group('Tools')]
install-invokeai:
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
    case "${GPU_SELECTION}" in
        "Nvidia (CUDA)")
            IMAGE=latest
            CUSTOM_ARGS="AddDevice=nvidia.com/gpu=all"
            ;;
        "AMD (ROCm)")
            IMAGE=main-rocm
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

    read -r -d '' CONTAINER_QUADLET <<-EOF
    [Unit]
    Description=The InvokeAI container
    After=network-online.target

    [Service]
    TimeoutStartSec=1200

    [Container]
    Image=ghcr.io/invoke-ai/invokeai:${IMAGE}
    ContainerName=invokeai
    AutoUpdate=registry
    Environment=INVOKEAI_ROOT=/var/lib/invokeai
    PublishPort=9091:9090
    Volume=invokeai.volume:/var/lib/invokeai
    SecurityLabelDisable=true
    ${CUSTOM_ARGS}

    [Install]
    WantedBy=multi-user.target
    EOF

    read -r -d '' VOLUME_QUADLET <<-EOF
    [Volume]
    VolumeName=invokeai
    EOF

    if [ ! -f ~/.config/containers/systemd/invokeai.container ] || [ ! -f ~/.config/containers/systemd/invokeai.volume ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${CONTAINER_QUADLET}" > ~/.config/containers/systemd/invokeai.container
        echo "${VOLUME_QUADLET}" > ~/.config/containers/systemd/invokeai.volume
    else
        echo "InvokeAI container already exists, skipping..."
    fi
    systemctl --user daemon-reload
    systemctl --user start invokeai.service
    echo "InvokeAI container started. You can access it at http://localhost:9091"

# Install Kubernetes CLI dev tools
[group('Tools')]
install-k8s-dev-tools:
    #!/usr/bin/bash
    echo "Adding Kubernetes command line tools..."
    brew bundle --file /usr/share/ublue-os/homebrew/kubernetes.Brewfile
