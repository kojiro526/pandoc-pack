FROM ubuntu:bionic

LABEL  maintainer "kojiro <kojiro@ryusei-sha.com>"

ENV LANG ja_JP.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

# language-pack はplantumlなどで日本語を扱うために必要
# gitはcomposerがパッケージをダウンロードする際に必要
RUN set -x \
    && apt-get update \
    && apt-get install -yqq software-properties-common \
    && LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install -yqq \
        language-pack-ja-base \
        language-pack-ja \
        ca-certificates \
        unzip \
        wget \
        libgmp10 \
        default-jre \
        graphviz \
        python3 \
        python3-pip \
        python3-setuptools \
        fonts-ipafont-gothic fonts-ipafont-mincho\
     --no-install-recommends 

# Install plantuml
RUN mkdir /root/bin && \
    wget --trust-server-names -q https://sourceforge.net/projects/plantuml/files/plantuml.jar/download -P /root/bin

# Install script
RUN mkdir /tools
ADD build.sh /tools/build.sh
RUN chmod a+x /tools/build.sh
RUN ln -s /tools/build.sh /usr/local/bin/build.sh

# Install pandoc
RUN wget -q https://github.com/jgm/pandoc/releases/download/2.9.1/pandoc-2.9.1-1-amd64.deb -P /tmp/ && \
    dpkg -i /tmp/pandoc-2.9.1-1-amd64.deb

# Install blockdiag
RUN pip3 install pillow && \
    pip3 install blockdiag && \
    pip3 install seqdiag && \
    pip3 install actdiag && \
    pip3 install nwdiag

WORKDIR /work

CMD [ "bash" ]
