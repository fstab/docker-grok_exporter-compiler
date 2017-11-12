FROM centos:6
MAINTAINER Fabian Stäber, fabian@fstab.de

#------------------------------------------------------------------------------
# Why centos:6
#------------------------------------------------------------------------------
# When compiled on current Linux versions, grok_exporter requires GLIBC_2.14,
# see output of 'objdump -p grok_exporter'. The reason is a call to memcpy,
# see output of 'objdump -T grok_exporter | grep GLIBC_2.14'.
# Centos 6 does not provide GLIBC_2.14. In order to make grok_exporter work on
# old Linux distributions, we compile it on Centos 6 to make sure it doesn't
# accidentally require a newer GLIBC version.
#------------------------------------------------------------------------------

# Edit the LAST_UPDATE variable to force re-run of 'yum update' when building
# the Docker image
ENV LAST_UPDATE=2017-11-12

RUN yum clean all && \
    yum update -y

#------------------------------------------------------------------------------
# Go development
#------------------------------------------------------------------------------

RUN yum install -y \
    curl \
    git \
    wget \
    vim

# Install golang manually, so we get the latest 1.7 version.

RUN cd /usr/local && \
    wget -nv https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz && \
    tar xfz go1.9.linux-amd64.tar.gz

ENV GOROOT /usr/local/go
RUN echo 'PATH=$GOROOT/bin:$PATH' >> /root/.bashrc

WORKDIR /root
RUN mkdir -p go/src/github.com/fstab go/bin go/pkg
ENV GOPATH /root/go
RUN echo 'GOPATH=$HOME/go' >> /root/.bashrc
RUN echo 'PATH=$GOPATH/bin:$PATH' >> /root/.bashrc

#------------------------------------------------------------------------------
# Create a statically linked Oniguruma library for Windows 64 Bit
#------------------------------------------------------------------------------

RUN yum install -y \
    epel-release
RUN yum install -y \
    gcc \
    mingw64-gcc

# Cross-compile Oniguruma for mingw in /tmp

WORKDIR /tmp
RUN curl -sLO https://github.com/kkos/oniguruma/releases/download/v5.9.6/onig-5.9.6.tar.gz && \
    tar xfz onig-5.9.6.tar.gz
WORKDIR /tmp/onig-5.9.6
RUN CC=x86_64-w64-mingw32-gcc ./configure --host x86_64-w64-mingw32 --prefix=/usr/x86_64-w64-mingw32
RUN CC=x86_64-w64-mingw32-gcc make
RUN CC=x86_64-w64-mingw32-gcc make install

# -> creates /usr/x86_64-w64-mingw32/lib/libonig.a

WORKDIR /root
RUN rm -r /tmp/*

#------------------------------------------------------------------------------
# Create a statically linked Oniguruma library for Linux 64 Bit
#------------------------------------------------------------------------------

WORKDIR /tmp
RUN curl -sLO https://github.com/kkos/oniguruma/releases/download/v5.9.6/onig-5.9.6.tar.gz && \
    tar xfz onig-5.9.6.tar.gz
WORKDIR /tmp/onig-5.9.6
RUN ./configure
RUN make
RUN make install

# -> creates /usr/local/lib/libonig.a

WORKDIR /root
RUN rm -r /tmp/*

#------------------------------------------------------------------------------
# Create compile scripts
#------------------------------------------------------------------------------

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
    echo 'if [[ "$1" == "-ldflags" ]] && [[ ! -z "$2" ]] && [[ "$3" == "-o" ]] && [[ ! -z "$4" ]]' >> /root/compile-windows-amd64.sh && \
    echo 'then' >> /root/compile-windows-amd64.sh && \
    echo '    cd /root/go/src/github.com/fstab/grok_exporter' >> /root/compile-windows-amd64.sh && \
    echo '    export CGO_LDFLAGS=/usr/x86_64-w64-mingw32/lib/libonig.a' >> /root/compile-windows-amd64.sh && \
    echo '    CC=x86_64-w64-mingw32-gcc GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -ldflags "$2" -o "$4" .' >> /root/compile-windows-amd64.sh && \
    echo 'else' >> /root/compile-windows-amd64.sh && \
    echo '    echo "Usage: $(basename "$0") -ldflags \\"-X name=value\\" -o <file>" >&2' >> /root/compile-windows-amd64.sh && \
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
    echo 'if [[ "$1" == "-ldflags" ]] && [[ ! -z "$2" ]] && [[ "$3" == "-o" ]] && [[ ! -z "$4" ]]' >> /root/compile-linux-amd64.sh && \
    echo 'then' >> /root/compile-linux-amd64.sh && \
    echo '    cd /root/go/src/github.com/fstab/grok_exporter' >> /root/compile-linux-amd64.sh && \
    echo '    export CGO_LDFLAGS=/usr/local/lib/libonig.a' >> /root/compile-linux-amd64.sh && \
    echo '    go build -ldflags "$2" -o "$4" .' >> /root/compile-linux-amd64.sh && \
    echo 'else' >> /root/compile-linux-amd64.sh && \
    echo '    echo "Usage: $(basename "$0") -ldflags \\"-X name=value\\" -o <file>" >&2' >> /root/compile-linux-amd64.sh && \
    echo '    echo "Note that <file> is relative to \$GOPATH/src/github.com/fstab/grok_exporter." >&2' >> /root/compile-linux-amd64.sh && \
    echo '    exit 1' >> /root/compile-linux-amd64.sh && \
    echo 'fi' >> /root/compile-linux-amd64.sh

RUN chmod 755 /root/compile-linux-amd64.sh

ENV PATH /usr/local/go/bin:/root:/root/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD /root/check-if-gopath-available.sh && echo "Type 'ls' to see the available compile scripts." && exec /bin/bash
