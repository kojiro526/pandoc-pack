FROM ubuntu

LABEL  maintainer "kojiro <kojiro@ryusei-sha.com>"

ENV LANG ja_JP.UTF-8

# language-pack はplantumlなどで日本語を扱うために必要
# gitはcomposerがパッケージをダウンロードする際に必要
RUN set -x \
    && apt-get update \
    && apt-get install -yqq software-properties-common  python-software-properties \
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
RUN mkdir /root/bin
RUN wget --trust-server-names https://sourceforge.net/projects/plantuml/files/plantuml.jar/download -P /root/bin

# Install script
RUN mkdir /tools
ADD build.sh /tools/build.sh
RUN chmod a+x /tools/build.sh
RUN ln -s /tools/build.sh /usr/local/bin/build.sh

# Install pandoc
RUN wget https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-1-amd64.deb -P /tmp/
RUN dpkg -i /tmp/pandoc-1.19.2.1-1-amd64.deb

# Install blockdiag
RUN easy_install blockdiag
RUN easy_install seqdiag
RUN easy_install actdiag
RUN easy_install nwdiag

# install composer↲
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/bin
RUN php -r "unlink('composer-setup.php');"

ENV PATH $PATH:/root/.composer/vendor/bin

# Install php-docxtable
RUN composer.phar global require kojiro526/php-docxtable

