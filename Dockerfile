###########################################
#### SETUP BASE IMAGE WITH ROCM-6.1.2 ####
###########################################
FROM rocm/dev-ubuntu-22.04:6.1.2 AS rocm-base

# Install essential dependencies and ROCm libraries
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sudo wget git cmake rocsparse-dev hipsparse-dev rocthrust-dev rocblas-dev hipblas-dev make build-essential \
    ocl-icd-opencl-dev opencl-headers clinfo \
    rocrand-dev hiprand-dev rccl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set ROCm environment variables
ENV ROCM_PATH=/opt/rocm \
    HSA_OVERRIDE_GFX_VERSION=10.3.0

# Add ROCm binaries to PATH
ENV PATH="${PATH}:/opt/rocm/bin"

#######################################
########## INSTALL PYTHON 3.9 #########
#######################################
FROM rocm-base AS python-setup

# Add deadsnakes PPA and install Python 3.9
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3.9 python3.9-dev python3-pip python3-setuptools python3.9-distutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Ensure Python 3.9 is the default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

##############################################
#### INSTALL OPENVOICE2 DEPENDENCIES #########
##############################################
FROM python-setup AS app-setup

WORKDIR /app

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git curl python3 python3-pip ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy requirements files and install dependencies
COPY requirements.txt requirements-rocm.txt requirements-melotts.txt .

# Upgrade pip and install dependencies from requirements
RUN pip install -U pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r requirements-melotts.txt && \
    pip install --no-cache-dir --force-reinstall -r requirements-rocm.txt

###################################
#### SETUP OPENVOICE2 AOO #########
###################################
FROM app-setup AS openvoice2

WORKDIR /app

# Copy application code
# COPY openvoice /app/openvoice
# COPY resources /app/resources
# COPY app.py /app/app.py
# COPY checkpoints /app/checkpoints
# COPY checkpoints_v2 /app/checkpoints_v2
# COPY open_voice.mp4 /app/open_voice.mp4
COPY . /app

# Download required models and data

RUN python3 -m unidic download
# RUN python3 -m melo.init_downloads

# Expose port
EXPOSE 8880

# Run the application
CMD ["python3", "app.py", "--host", "0.0.0.0", "--port", "8880"]
