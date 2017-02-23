FROM centos:6.8

RUN yum install -y openssh openssh-server openssh-clients perl nc sudo sysstat wget bind bind-utils && service postfix stop && chkconfig postfix off

VOLUME ["/opt/zimbra"]

EXPOSE 22 25 465 587 110 143 993 995 80 443 8080 8443 7071

COPY opt /opt/

CMD ["/bin/bash", "/opt/install.sh", "-d"]
