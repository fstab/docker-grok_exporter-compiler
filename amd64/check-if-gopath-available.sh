if [ ! -d '/root/go/src/github.com/fstab/grok_exporter' ] ; then
    cat <<EOF >&2
ERROR: Did not find grok_exporter sources. Start this container as follows:
docker run -v \$GOPATH/src/github.com/fstab/grok_exporter:/root/go/src/github.com/fstab/grok_exporter --net none --rm -ti fstab/grok_exporter-compiler
EOF
    exit 1
fi
