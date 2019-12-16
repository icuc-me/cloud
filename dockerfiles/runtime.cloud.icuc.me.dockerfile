ARG  TAG=latest
FROM tools.cloud.icuc.me:${TAG}

RUN ooe.sh retry.sh 180 3 30 yum update -y && \
    ooe.sh yum clean all && \
    rm -rf /var/cache/yum && \
    rm -rf /var/tmp/* /var/tmp/.??* /tmp/* /tmp/.??*

COPY /dockerfiles/runtime.cloud.icuc.me.dockerfile /root/
COPY /dockerfiles/as_user.sh /usr/local/bin/as_user.sh

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
            github.com/klauspost/asmfmt/cmd/asmfmt"

RUN chmod 0755 /usr/local/bin/as_user.sh && \
    export GOPATH="/usr/src/go" && \
    export GOCACHE="/var/cache/go" && \
    mkdir -p "$GOPATH/bin" && \
    mkdir -p "$GOCACHE" && \
    cd /tmp && \
    ooe.sh retry.sh 30 5 30 curl -L --silent --show-error -O $GLCIURL && \
    ooe.sh retry.sh 30 5 30 sh ./golangci-lint.sh -b $GOPATH/bin v1.21.0 && \
    cd / && \
    rm -rf /var/tmp/* /var/tmp/.??* /tmp/* /tmp/.??*

RUN export GOPATH="/usr/src/go" && \
    export GOCACHE="/var/cache/go" && \
    export PATH="$PATH:$GOPATH/bin" && \
    for name in $GOPKGS; do ooe.sh retry.sh 30 3 60 go get $name; done && \
    cd /var/tmp/ && ooe.sh retry.sh 30 3 60 git clone --depth 1 "$MYURL" && \
    cd ./cloud/validate && \
    ooe.sh retry.sh 180 3 60 go mod download && \
    make validate.test && \
    cd / && \
    rm -rf /var/tmp/* /var/tmp/.??* /tmp/* /tmp/.??*

ENTRYPOINT ["/usr/local/bin/as_user.sh"]
