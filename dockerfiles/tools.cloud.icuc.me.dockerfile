ARG  TAG=latest
FROM base.cloud.icuc.me:${TAG}

COPY /dockerfiles/tools.cloud.icuc.me.dockerfile /root/

ENV PACKER_VERSION="1.3.5" \
    OS_ARCH="amd64" \
    TFVER="0.11.14"
ENV TFURL="https://releases.hashicorp.com/terraform/${TFVER}/terraform_${TFVER}_linux_${OS_ARCH}.zip" \
    PACKER_DIST_FILENAME="packer_${PACKER_VERSION}_linux_${OS_ARCH}.zip"

RUN ooe.sh retry.sh 180 3 30 yum update -y && \
    ooe.sh retry.sh 120 3 60 yum install -y ansible && \
    cd /tmp && \
    ooe.sh retry.sh 30 5 30 curl -L --silent --show-error \
        -O "https://releases.hashicorp.com/packer/${PACKER_VERSION}/${PACKER_DIST_FILENAME}" && \
    ooe.sh retry.sh 30 5 30 curl -L --silent --show-error \
        "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS" \
        | grep "linux_${OS_ARCH}" > packer_sha256sums && \
    ooe.sh sha256sum --check packer_sha256sums && \
    ooe.sh unzip -o ${PACKER_DIST_FILENAME} && \
    ooe.sh install -D -m 755 -o root -g root --strip packer /usr/local/bin/packer && \
    /usr/local/bin/packer --version & \
    yum clean all && \
    rm -rf /var/cache/yum && \
    rm -rf /var/tmp/* /var/tmp/.??* /tmp/* /tmp/.??*

RUN cd /usr/local/bin && \
    ooe.sh retry.sh 30 5 30 curl -L --silent --show-error -o terraform.zip "$TFURL" && \
    ooe.sh unzip terraform.zip && \
    rm -f terraform.zip && \
    chmod 755 terraform && \
    /usr/local/bin/terraform --version && \
    rm -rf /var/tmp/* /var/tmp/.??* /tmp/* /tmp/.??*
