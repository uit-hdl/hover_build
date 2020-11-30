ARG UBUNTU_VERSION=18.04

ARG CONDA_VER=latest
ARG ARCH=
ARG CUDA=10.1

FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION} as base
# ARCH and CUDA are specified again because the FROM directive resets ARGs
# (but their default value is retained if set previously)
ARG ARCH
ARG CUDA
ARG CUDNN=7.6.4.38-1
ARG CUDNN_MAJOR_VERSION=7
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=6.0.1-1
ARG LIBNVINFER_MAJOR_VERSION=6

LABEL base="nvidia/cuda"
LABEL version="${CUDA}-base-ubuntu${UBUNTU_VERSION}"
LABEL software.version="1.0"

MAINTAINER Shvetsov Nikita <shvetsov.nikita@uit.no>

ENV PATH /opt/conda/bin:$PATH

# Needed for string substitution
SHELL ["/bin/bash", "-c"]

# TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-${CUDA/./-} \
        # There appears to be a regression in libcublas10=10.2.2.89-1 which
        # prevents cublas from initializing in TF. See
        # https://github.com/tensorflow/tensorflow/issues/9489#issuecomment-562394257
        libcublas10=10.2.1.243-1 \ 
        cuda-nvrtc-${CUDA/./-} \
        cuda-cufft-${CUDA/./-} \
        cuda-curand-${CUDA/./-} \
        cuda-cusolver-${CUDA/./-} \
        cuda-cusparse-${CUDA/./-} \
        curl \
        libcudnn7=${CUDNN}+cuda${CUDA} \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
	libcap-dev \
	python-openslide \
        openslide-tools \
        pkg-config \
        software-properties-common \
        unzip

RUN [[ "${ARCH}" = "ppc64le" ]] || { apt-get update && \
        apt-get install -y --no-install-recommends libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*; }

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

#ARG USE_PYTHON_3_NOT_2
#ARG _PY_SUFFIX=${USE_PYTHON_3_NOT_2:+3}
#ARG PYTHON=python${_PY_SUFFIX}
#ARG PIP=pip${_PY_SUFFIX}


#RUN apt-get update && apt-get install -y \
#    ${PYTHON} \
#    ${PYTHON}-pip

#RUN ${PIP} --no-cache-dir install --upgrade \
#    pip \
#    setuptools

#ARG TF_PACKAGE=tensorflow-gpu
#ARG TF_PACKAGE_VERSION=1.12.0
#RUN ${PIP} install --no-cache-dir ${TF_PACKAGE}${TF_PACKAGE_VERSION:+==${TF_PACKAGE_VERSION}}
#####

# Conda installation
RUN echo 'deb http://security.ubuntu.com/ubuntu xenial-security main' | tee -a /etc/apt/sources.list && \
	apt-get update --fix-missing && apt-get install -y -q \
        libsm6 libxext6 libxrender-dev \
        libjasper-dev \
	libcap-dev \
	wget bzip2 ca-certificates git nano && \
	apt-get clean && apt-get check && apt-get autoclean && apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/src/*

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
	/bin/bash ~/miniconda.sh -b -p /opt/conda && \
	rm ~/miniconda.sh && \
	/opt/conda/bin/conda clean -tipsy && \ 
	ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
	echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
	echo "conda activate base" >> ~/.bashrc

COPY environment.yml environment.yml

RUN apt-get update --fix-missing && \
    apt-get check && apt-get autoclean && apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/src/* && \
    conda update -y --all --prune && \
    conda env create -f environment.yml && \
    conda clean -y --all

RUN sed -i '/conda activate/d' ~/.bashrc && \
        export CENV=$(head -1 environment.yml | cut -d' ' -f2) && \
        echo "conda activate $CENV" >> ~/.bashrc && \
        rm environment.yml

# Some TF tools expect a "python" binary
RUN ln -s $(which ${PYTHON}) /usr/local/bin/python

RUN mkdir /tools && mkdir /data
WORKDIR /tools
# ENV PATH /opt/conda/envs/$CENV/bin:$PATH

CMD [ "/bin/bash" ]
