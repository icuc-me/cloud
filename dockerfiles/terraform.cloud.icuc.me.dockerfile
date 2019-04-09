ARG  TAG=latest
FROM packer.cloud.icuc.me:${TAG}

COPY /dockerfiles/terraform.cloud.icuc.me.dockerfile /root/

ENV TFVER="0.11.13" \
    TFARCH="amd64"
ENV TFURL="https://releases.hashicorp.com/terraform/${TFVER}/terraform_${TFVER}_linux_${TFARCH}.zip"

RUN yum update -y && \
    cd /usr/local/bin && \
    curl -o terraform.zip "$TFURL" && \
    unzip terraform.zip && \
    rm -f terraform.zip && \
    chmod 755 terraform && \
    yum clean all && \
    rm -rf /var/cache/yum
