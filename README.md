grok_exporter Compiler
----------------------

This Docker image is used for building [grok_exporter] releases. See the [release.sh] script for how it is used.

The image is available on [Docker hub]. The sources are on [Github].

To build the image from scratch on an Intel processor, run the following:

```bash
git clone https://github.com/fstab/docker-grok_exporter-compiler.git
cd docker-grok_exporter-compiler
docker build -t fstab/grok_exporter-compiler-amd64 -f Dockerfile.amd64 .
```

To build the image from scratch on an ARM 64 Bit processor (like a [Scaleway] server), run the following:

```bash
git clone https://github.com/fstab/docker-grok_exporter-compiler.git
cd docker-grok_exporter-compiler
docker build -t fstab/grok_exporter-compiler-arm64v8 -f Dockerfile.arm64v8 .
```

To build the image from scratch on an ARM 32 Bit processor (like [Raspberry Pi]), run the following:

```bash
git clone https://github.com/fstab/docker-grok_exporter-compiler.git
cd docker-grok_exporter-compiler
docker build -t fstab/grok_exporter-compiler-arm32v7 -f Dockerfile.arm32v7 .
```

Example call to build a [grok_exporter] release:

```bash
go get github.com/fstab/grok_exporter
cd $GOPATH/src/github.com/fstab/grok_exporter
git submodule update --init --recursive
./release.sh
```

See [github.com/fstab/grok_exporter](https://github.com/fstab/grok_exporter) for more info.

[grok_exporter]: https://github.com/fstab/grok_exporter
[release.sh]: https://github.com/fstab/grok_exporter/blob/master/release.sh
[Docker hub]: https://hub.docker.com/r/fstab/grok_exporter-compiler/
[Github]: https://github.com/fstab/docker-grok_exporter-compiler
[Scaleway]: https://www.scaleway.com/
[Raspberry Pi]: https://www.raspberrypi.org/
