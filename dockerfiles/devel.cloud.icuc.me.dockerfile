ARG  TAG=latest
FROM validate.cloud.icuc.me:${TAG}

COPY /dockerfiles/devel.cloud.icuc.me.dockerfile /root/
COPY /dockerfiles/as_user.sh /usr/local/bin/as_user.sh

RUN yum update -y && \
    chmod 0755 /usr/local/bin/as_user.sh && \
    cd /var/tmp/ && git clone --depth 1 "$MYURL" && \
    cd / && rm -rf /var/tmp/cloud && \
    yum clean all && \
    rm -rf /var/cache/yum

ENTRYPOINT ["/usr/local/bin/as_user.sh"]
