ARG  TAG=latest
FROM terraform.cloud.icuc.me:${TAG}

RUN yum update -y && \
    yum clean all && \
    rm -rf /var/cache/yum

ENV GLCIURL="https://install.goreleaser.com/github.com/golangci/golangci-lint.sh" \
    MYURL="https://github.com/icuc-me/cloud.git" \
    GOPKGS="github.com/DATA-DOG/godog/cmd/godog \
            github.com/zmb3/gogetdoc \
            golang.org/x/tools/cmd/guru \
            golang.org/x/lint/golint \
            github.com/davidrjenni/reftools/cmd/fillstruct \
            github.com/rogpeppe/godef \
            github.com/fatih/motion \
            github.com/kisielk/errcheck \
            github.com/mdempsky/gocode \
            github.com/josharian/impl \
            github.com/koron/iferr \
            github.com/jstemmer/gotags \
            golang.org/x/tools/cmd/gorename \
            golang.org/x/tools/cmd/goimports \
            github.com/stamblerre/gocode \
            github.com/fatih/gomodifytags \
            honnef.co/go/tools/cmd/keyify \
            github.com/klauspost/asmfmt/cmd/asmfmt" \
    GOPATH="/usr/src/go" \
    GOCACHE="/var/cache/go"

COPY /dockerfiles/validate.cloud.icuc.me.dockerfile /root/

RUN mkdir -p "$GOPATH/bin" && \
    mkdir -p "$GOCACHE" && \
    cd /tmp && \
    curl -L -O $GLCIURL && \
    sh ./golangci-lint.sh -b $GOPATH/bin v1.15.0 && \
    cd / && \
    rm -rf /tmp/* /tmp/.??*

RUN for name in $GOPKGS; do go get $name; done && \
    cd /var/tmp/ && git clone --depth 1 "$MYURL" && \
    cd ./cloud/validate && go mod download && \
    export PATH="$PATH:$GOPATH/bin" && \
    make validate.test && \
    cd / && \
    rm -rf /var/tmp/* /var/tmp/.??*

ENV GOPATH="" \
    GOCACHE=""
