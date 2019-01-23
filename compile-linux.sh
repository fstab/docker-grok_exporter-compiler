#!/usr/bin/env bash

set -e

/check-if-gopath-available.sh

if [[ "$1" == "-ldflags" ]] && [[ ! -z "$2" ]] && [[ "$3" == "-o" ]] && [[ ! -z "$4" ]]
then
    cd /go/src/github.com/fstab/grok_exporter
    export CGO_LDFLAGS=/usr/local/lib/libonig.a
    export GO111MODULE=off # use vendor instead
    echo go version: $(go version)
    go build -ldflags "$2" -o "$4" .
else
    echo "Usage:" $(basename "$0") "-ldflags \"-X name=value\" -o <file>" >&2
    echo "Note that <file> is relative to \$GOPATH/src/github.com/fstab/grok_exporter." >&2
    exit 1
fi
