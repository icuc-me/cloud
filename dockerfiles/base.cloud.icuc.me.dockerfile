FROM centos:7

RUN yum update -y && \
    yum install -y epel-release centos-release-scl && \
    yum clean all && \
    rm -rf /var/cache/yum

COPY /dockerfiles/base.cloud.icuc.me.dockerfile /root/
COPY /dockerfiles/google-cloud-sdk.repo /etc/yum.repos.d/
COPY /dockerfiles/git /usr/bin/git
COPY /dockerfiles/centos.packages /root/

RUN sed -r -i -e 's/^debuglevel=.+/debuglevel=1/' /etc/yum.conf && \
    yum update -y && \
    yum install -y $(cat /root/centos.packages) && \
    chmod 755 /usr/bin/git && \
    ln -sf /usr/bin/python36 /usr/bin/python3 && \
    yum clean all && \
    rm -rf /var/cache/yum
