if [ ! -d '/go/src/github.com/fstab/grok_exporter' ] ; then
    cat <<EOF >&2
ERROR: Did not find grok_exporter sources. Start this container as follows:
docker run -v \$GOPATH/src/github.com/fstab/grok_exporter:/go/src/github.com/fstab/grok_exporter --net none --user \$(id -u):\$(id -g) --rm -ti fstab/grok_exporter-compiler
EOF
    exit 1
fi
