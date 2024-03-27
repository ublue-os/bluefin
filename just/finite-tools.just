# vim: set ft=make :
########################
### finite-tools.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

install-ollama:
    #!/usr/bin/env bash
    GPUVendor="$(lshw -c video)"
    if [ $GPUVendor =~ AMD ];
    then
        echo "Found AMD GPU... Installing ollama for ROCM..."
        podman run -d --device /dev/kfd --device /dev/dri -v ollama:/root/.ollama -p 11434:11434 --restart always --name ollama docker.io/ollama/ollama:rocm
    elif [ $GPUDATA =~ Nvidia ];
    then
        echo "Found Nvidia GPU... Installing ollama for CUDA..."
        podman run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --restart always --name ollama docker.io/ollama/ollama
    else
        echo "Could not find suitable GPU... Installing ollama for CPU..."
        podman run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama docker.io/ollama/ollama
    fi
