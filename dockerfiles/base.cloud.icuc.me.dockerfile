ARG  TAG=latest
FROM centos:7

ENV BASE_TAG="$TAG"

COPY /dockerfiles/base.cloud.icuc.me.dockerfile /root/
COPY /dockerfiles/google-cloud-sdk.repo /etc/yum.repos.d/
COPY /dockerfiles/git /usr/bin/git
COPY /dockerfiles/ooe.sh /usr/bin/
COPY /dockerfiles/retry.sh /usr/bin/
COPY /dockerfiles/centos.packages /root/

RUN ooe.sh retry.sh 180 3 30 yum update -y && \
    ooe.sh retry.sh 30 3 60 yum install -y epel-release centos-release-scl && \
    ooe.sh yum clean all && \
    rm -rf /var/cache/yum && \
    rm -rf /var/tmp/* /var/tmp/.??* /tmp/* /tmp/.??*

RUN sed -r -i -e 's/^debuglevel=.+/debuglevel=1/' /etc/yum.conf && \
    ooe.sh retry.sh 300 2 60 yum install -y $(cat /root/centos.packages) && \
    ln -sf /usr/bin/python36 /usr/bin/python3 && \
    rm -rf /var/tmp/* /var/tmp/.??* /tmp/* /tmp/.??*
