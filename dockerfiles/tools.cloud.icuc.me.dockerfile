ARG  TAG=latest
FROM base.cloud.icuc.me:${TAG}

COPY /dockerfiles/tools.cloud.icuc.me.dockerfile /root/

ENV PACKER_VERSION="1.3.5" \
    OS_ARCH="amd64" \
    TFVER="0.11.14"
ENV TFURL="https://releases.hashicorp.com/terraform/${TFVER}/terraform_${TFVER}_linux_${OS_ARCH}.zip" \
    PACKER_DIST_FILENAME="packer_${PACKER_VERSION}_linux_${OS_ARCH}.zip"

RUN yum update -y && \
    cd /tmp && \
    curl -L --silent --show-error \
        -O "https://releases.hashicorp.com/packer/${PACKER_VERSION}/${PACKER_DIST_FILENAME}" && \
    curl -L --silent --show-error \
        "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS" \
        | grep "linux_${OS_ARCH}" > packer_sha256sums && \
    sha256sum --check packer_sha256sums && \
    unzip -o ${PACKER_DIST_FILENAME} && \
    install -D -m 755 -o root -g root --strip packer /usr/local/bin/packer && \
    rm -f "${PACKER_DIST_FILENAME}" packer_sha256sums && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN yum update -y && \
    cd /usr/local/bin && \
    curl -L --silent --show-error -o terraform.zip "$TFURL" && \
    unzip terraform.zip && \
    rm -f terraform.zip && \
    chmod 755 terraform && \
    yum clean all && \
    rm -rf /var/cache/yum
