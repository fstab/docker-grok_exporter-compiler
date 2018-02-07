#!/bin/bash

set -e

#/root/check-if-gopath-available.sh

if [[ "$1" == "-ldflags" ]] && [[ ! -z "$2" ]] && [[ "$3" == "-o" ]] && [[ ! -z "$4" ]]
then
    cd /root/go/src/github.com/fstab/grok_exporter
    export CGO_LDFLAGS=/usr/x86_64-w64-mingw32/lib/libonig.a
    CC=x86_64-w64-mingw32-gcc GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -ldflags "$2" -o "$4" .
else
    echo "Usage:" $(basename "$0") "-ldflags \"-X name=value\" -o <file>" >&2
    echo "Note that <file> is relative to \$GOPATH/src/github.com/fstab/grok_exporter." >&2
    exit 1
fi
