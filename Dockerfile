FROM ubuntu:17.10

LABEL  maintainer "kojiro <kojiro@ryusei-sha.com>"

ENV LANG ja_JP.UTF-8

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
        php7.1 php7.1-zip php7.1-xml \
        git \
        libgmp10 \
        default-jre \
        graphviz \
        python2.7 \ 
        python-imaging \ 
        python-setuptools \
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
RUN wget -q https://github.com/jgm/pandoc/releases/download/2.6/pandoc-2.6-1-amd64.deb -P /tmp/ && \
    dpkg -i /tmp/pandoc-2.6-1-amd64.deb

# Install blockdiag
RUN easy_install blockdiag && \
    easy_install seqdiag && \
    easy_install actdiag && \
    easy_install nwdiag

# install composer↲
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/bin && \
    php -r "unlink('composer-setup.php');"

ENV PATH $PATH:/root/.composer/vendor/bin

# Install php-docxtable
RUN composer.phar global require kojiro526/php-docxtable

WORKDIR /work

CMD [ "bash" ]
