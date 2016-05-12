FROM ubuntu:16.04
MAINTAINER Fabian Stäber, fabian@fstab.de

ENV LAST_UPDATE=2016-05-08

#-----------------------------------------------------------------
# Standard Ubuntu set-up
#-----------------------------------------------------------------

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

#-----------------------------------------------------------------
# Go development
#-----------------------------------------------------------------

RUN apt-get install -y \
    golang \
    git \
    wget \
    vim

WORKDIR /root
RUN mkdir -p go/src/github.com/fstab go/bin go/pkg
ENV GOPATH /root/go
RUN echo 'GOPATH=$HOME/go' >> /root/.bashrc
RUN echo 'PATH=$GOPATH/bin:$PATH' >> /root/.bashrc

#-----------------------------------------------------------------
# Install dynamically linked Oniguruma Library for Linux 64 Bit
#-----------------------------------------------------------------

#RUN apt-get install -y \
#    build-essential \
#    libonig-dev

#-----------------------------------------------------------------
# Create a statically linked Oniguruma library for Windows 64 Bit
#-----------------------------------------------------------------

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

# -> creates /usr/x86_64-w64-mingw32/lib/libonig.a

WORKDIR /root
RUN rm -r /tmp/*

#-----------------------------------------------------------------
# Create a statically linked Oniguruma library for Linux 64 Bit
#-----------------------------------------------------------------

WORKDIR /tmp
RUN apt-get source libonig-dev
WORKDIR /tmp/libonig-5.9.6
RUN ./configure
RUN make || true
RUN mv '$(encdir)/.deps' enc
RUN make
RUN make install

# -> creates /usr/local/lib/libonig.a

WORKDIR /root
RUN rm -r /tmp/*

#-----------------------------------------------------------------
# Create compile scripts
#-----------------------------------------------------------------

# check-if-gopath-available.sh

RUN echo "if [ ! -d '/root/go/src/github.com/fstab/grok_exporter' ] ; then" >> /root/check-if-gopath-available.sh && \
    echo "    cat <<EOF >&2" >> /root/check-if-gopath-available.sh && \
    echo "ERROR: Did not find grok_exporter sources. Start this container as follows:" >> /root/check-if-gopath-available.sh && \
    echo "docker run -v \\\$GOPATH/src/github.com/fstab/grok_exporter:/root/go/src/github.com/fstab/grok_exporter --net none --rm -ti fstab/grok_exporter-compiler" >> /root/check-if-gopath-available.sh && \
    echo "EOF" >> /root/check-if-gopath-available.sh && \
    echo "    exit 1" >> /root/check-if-gopath-available.sh && \
    echo "fi" >> /root/check-if-gopath-available.sh

RUN chmod 755 /root/check-if-gopath-available.sh

# compile-windows-amd64.sh

RUN echo '#!/bin/bash' >> /root/compile-windows-amd64.sh && \
    echo '' >> /root/compile-windows-amd64.sh && \
    echo 'set -e' >> /root/compile-windows-amd64.sh && \
    echo '' >> /root/compile-windows-amd64.sh && \
    echo '/root/check-if-gopath-available.sh' >> /root/compile-windows-amd64.sh && \
    echo '' >> /root/compile-windows-amd64.sh && \
    echo 'if [[ "$1" == "-o" ]] && [[ ! -z "$2" ]]' >> /root/compile-windows-amd64.sh && \
    echo 'then' >> /root/compile-windows-amd64.sh && \
    echo '    cd /root/go/src/github.com/fstab/grok_exporter' >> /root/compile-windows-amd64.sh && \
    echo '    export CGO_LDFLAGS=/usr/x86_64-w64-mingw32/lib/libonig.a' >> /root/compile-windows-amd64.sh && \
    echo '    CC=x86_64-w64-mingw32-gcc GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -o $2 .' >> /root/compile-windows-amd64.sh && \
    echo 'else' >> /root/compile-windows-amd64.sh && \
    echo '    echo "Usage: $(basename "$0") -o <file>" >&2' >> /root/compile-windows-amd64.sh && \
    echo '    echo "Note that <file> is relative to \$GOPATH/src/github.com/fstab/grok_exporter." >&2' >> /root/compile-windows-amd64.sh && \
    echo '    exit 1' >> /root/compile-windows-amd64.sh && \
    echo 'fi' >> /root/compile-windows-amd64.sh

RUN chmod 755 /root/compile-windows-amd64.sh

# compile-linux-amd64.sh

RUN echo '#!/bin/bash' >> /root/compile-linux-amd64.sh && \
    echo '' >> /root/compile-linux-amd64.sh && \
    echo 'set -e' >> /root/compile-linux-amd64.sh && \
    echo '' >> /root/compile-linux-amd64.sh && \
    echo '/root/check-if-gopath-available.sh' >> /root/compile-linux-amd64.sh && \
    echo '' >> /root/compile-linux-amd64.sh && \
    echo 'if [[ "$1" == "-o" ]] && [[ ! -z "$2" ]]' >> /root/compile-linux-amd64.sh && \
    echo 'then' >> /root/compile-linux-amd64.sh && \
    echo '    cd /root/go/src/github.com/fstab/grok_exporter' >> /root/compile-linux-amd64.sh && \
    echo '    export CGO_LDFLAGS=/usr/local/lib/libonig.a' >> /root/compile-linux-amd64.sh && \
    echo '    go build -o $2 .' >> /root/compile-linux-amd64.sh && \
    echo 'else' >> /root/compile-linux-amd64.sh && \
    echo '    echo "Usage: $(basename "$0") -o <file>" >&2' >> /root/compile-linux-amd64.sh && \
    echo '    echo "Note that <file> is relative to \$GOPATH/src/github.com/fstab/grok_exporter." >&2' >> /root/compile-linux-amd64.sh && \
    echo '    exit 1' >> /root/compile-linux-amd64.sh && \
    echo 'fi' >> /root/compile-linux-amd64.sh

RUN chmod 755 /root/compile-linux-amd64.sh

ENV PATH /root:/root/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD /root/check-if-gopath-available.sh && echo "Type 'ls' to see the available compile scripts." && exec /bin/bash
