FROM ubuntu:16.04
MAINTAINER Fabian Stäber, fabian@fstab.de

ENV LAST_UPDATE=2016-05-08

#---------------------------------------------------
# standard ubuntu set-up
#---------------------------------------------------

RUN apt-get update && \
    apt-get upgrade -y

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set the timezone
RUN echo "Europe/Berlin" | tee /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

#---------------------------------------------------
# go development
#---------------------------------------------------

RUN apt-get install -y \
    golang \
    git \
    wget \
    vim

WORKDIR /root
RUN mkdir go
ENV GOPATH /root/go
RUN echo 'GOPATH=$HOME/go' >> /root/.bashrc
RUN echo 'PATH=$GOPATH/bin:$PATH' >> /root/.bashrc

#---------------------------------------------------
# Install Oniguruma Library for Linux 64 Bit
#---------------------------------------------------

RUN apt-get install -y \
    build-essential \
    libonig-dev

#---------------------------------------------------
# Install Oniguruma Library for Windows 64 Bit
#---------------------------------------------------

RUN apt-get install -y \
    automake \
    automake1.11 \
    gcc-mingw-w64-x86-64 \
    libtool

# Cross-compile Oniguruma for mingw in /tmp

WORKDIR /tmp
RUN apt-get source libonig-dev
WORKDIR /tmp/libonig-5.9.6
RUN CC=x86_64-w64-mingw32-gcc ./configure --host x86_64-w64-mingw32 --prefix=/usr/x86_64-w64-mingw32
RUN CC=x86_64-w64-mingw32-gcc make || true
RUN mv '$(encdir)/.deps' enc
RUN CC=x86_64-w64-mingw32-gcc make
RUN CC=x86_64-w64-mingw32-gcc make install

WORKDIR /root
RUN rm -r /tmp/*

#---------------------------------------------------
# Create compile scripts
#---------------------------------------------------

# check-if-gopath-available.sh

RUN echo "if [ ! -d '/root/go/src/github.com/fstab/grok_exporter' ] ; then" >> /root/check-if-gopath-available.sh
RUN echo "    cat <<EOF >&2" >> /root/check-if-gopath-available.sh
RUN echo "ERROR: Did not find grok_exporter sources." >> /root/check-if-gopath-available.sh
RUN echo "This image expectes that the host system's \\\$GOPATH is mounted to '/root/go'." >> /root/check-if-gopath-available.sh
RUN echo "Start this container with '-v \\\$GOPATH:/root/go', and make sure the sources for" >> /root/check-if-gopath-available.sh
RUN echo "'github.com/fstab/grok_exporter' are available in the host's '\\\$GOPATH'." >> /root/check-if-gopath-available.sh
RUN echo "EOF" >> /root/check-if-gopath-available.sh
RUN echo "    exit 1" >> /root/check-if-gopath-available.sh
RUN echo "fi" >> /root/check-if-gopath-available.sh

RUN chmod 755 /root/check-if-gopath-available.sh

# compile-windows-amd64.sh

RUN echo '#!/bin/bash' >> /root/compile-windows-amd64.sh
RUN echo '' >> /root/compile-windows-amd64.sh
RUN echo 'set -e' >> /root/compile-windows-amd64.sh
RUN echo '' >> /root/compile-windows-amd64.sh
RUN echo '/root/check-if-gopath-available.sh' >> /root/compile-windows-amd64.sh
RUN echo '' >> /root/compile-windows-amd64.sh
RUN echo 'if [[ "$1" == "-o" ]] && [[ ! -z "$2" ]]' >> /root/compile-windows-amd64.sh
RUN echo 'then' >> /root/compile-windows-amd64.sh
RUN echo '    cd /root/go/src/github.com/fstab/grok_exporter' >> /root/compile-windows-amd64.sh
RUN echo '    CC=x86_64-w64-mingw32-gcc GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -o $2 .' >> /root/compile-windows-amd64.sh
RUN echo 'else' >> /root/compile-windows-amd64.sh
RUN echo '    echo "Usage: $(basename "$0") -o <file>" >&2' >> /root/compile-windows-amd64.sh
RUN echo '    echo "Note that <file> is relative to \$GOPATH." >&2' >> /root/compile-windows-amd64.sh
RUN echo '    exit 1' >> /root/compile-windows-amd64.sh
RUN echo 'fi' >> /root/compile-windows-amd64.sh

RUN chmod 755 /root/compile-windows-amd64.sh

# compile-linux-amd64.sh

RUN echo '#!/bin/bash' >> /root/compile-linux-amd64.sh
RUN echo '' >> /root/compile-linux-amd64.sh
RUN echo 'set -e' >> /root/compile-linux-amd64.sh
RUN echo '' >> /root/compile-linux-amd64.sh
RUN echo '/root/check-if-gopath-available.sh' >> /root/compile-linux-amd64.sh
RUN echo '' >> /root/compile-linux-amd64.sh
RUN echo 'if [[ "$1" == "-o" ]] && [[ ! -z "$2" ]]' >> /root/compile-linux-amd64.sh
RUN echo 'then' >> /root/compile-linux-amd64.sh
RUN echo '    cd /root/go/src/github.com/fstab/grok_exporter' >> /root/compile-linux-amd64.sh
RUN echo '    go build -o $2 .' >> /root/compile-linux-amd64.sh
RUN echo 'else' >> /root/compile-linux-amd64.sh
RUN echo '    echo "Usage: $(basename "$0") -o <file>" >&2' >> /root/compile-linux-amd64.sh
RUN echo '    echo "Note that <file> is relative to \$GOPATH." >&2' >> /root/compile-linux-amd64.sh
RUN echo '    exit 1' >> /root/compile-linux-amd64.sh
RUN echo 'fi' >> /root/compile-linux-amd64.sh

RUN chmod 755 /root/compile-linux-amd64.sh

ENV PATH /root:/root/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD /root/check-if-gopath-available.sh && echo "Type 'ls' to see the available compile scripts." && /bin/bash
