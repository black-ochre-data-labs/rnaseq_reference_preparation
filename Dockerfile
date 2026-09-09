# ---------------------------------------------------------------------------- #
# Reference genome docker image
# 
# Dockerfile that will build the reference genome used by the EMSEQ pipeline.
# Built on an M3 Macbook PRO using Docker CLI. Commands listed below and detailed
# in documentation.
# 
# cd bodl-nf/dockerfiles/emseq || exit 1
# docker build -t ajlud/... .
# docker push ajlud/...

# Download base image ubuntu 22.04
FROM --platform=linux/amd64 ubuntu:22.04
WORKDIR /usr/local/bodl-nf

LABEL version="1.0"
LABEL maintainer="alastair.ludington@telethonkids.org.au"
LABEL description="Software needed by 'build-reference-hg38.sh' script."

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install apt-transport-https ca-certificates gnupg \
    python3-dev python3-distutils python3-pip python-is-python3 \
    gcc python3-setuptools build-essential bzip2 curl tar unzip \
    autoconf automake make perl libncurses-dev zlib1g-dev libbz2-dev liblzma-dev \
    libcurl4-gnutls-dev libssl-dev libdeflate-dev -y

# Install Google CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update -y \
    && apt-get install google-cloud-sdk -y

# Install CRCmod (used by google CLI)
RUN pip3 install --no-cache-dir -U crcmod

# Install seqkit pre-compiled binary
RUN curl -L -O https://github.com/shenwei356/seqkit/releases/download/v2.8.2/seqkit_linux_amd64.tar.gz \
    && tar -zxf seqkit_linux_amd64.tar.gz \
    && mv seqkit /usr/local/bin/ \
    && rm seqkit_linux_amd64.tar.gz

# Install SAMtools
RUN curl -L https://github.com/samtools/samtools/releases/download/1.20/samtools-1.20.tar.bz2 | tar jxf - && \
    cd samtools-1.20 && \
    ./configure && \
    make && \
    make install

# Install BWA-mem2
RUN curl -L https://github.com/bwa-mem2/bwa-mem2/releases/download/v2.2.1/bwa-mem2-2.2.1_x64-linux.tar.bz2 | tar jxf - && \
    cp bwa-mem2-2.2.1_x64-linux/bwa-mem2* /usr/local/bin && \
    rm -r bwa-mem2-2.2.1_x64-linux

# Install BWA-meth
RUN pip install toolshed \
    && curl -L -O https://github.com/brentp/bwa-meth/archive/master.zip \
    && unzip master.zip \
    && cd bwa-meth-master \
    && python setup.py install \
    && cp bwameth.py /usr/local/bin

RUN rm -r bwa-meth-master master.zip samtools-1.20

# # Reduce container size
RUN rm -rf /var/lib/apt/lists/* \
    && apt-get clean