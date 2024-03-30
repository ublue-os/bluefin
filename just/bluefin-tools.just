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
