FROM registry.centos.org/centos/centos:7 as base-ui

RUN mkdir -p /var/www/html

ADD ./src /var/www/html

# ENV PCVE_SERVICE_HOST=probable-cve-api-probable-cve.devtools-dev.ext.devshift.net

ADD ./fix-permissions.sh ./install.sh ./passwd.template ./run.sh /opt/scripts/

RUN chmod -R 777 /opt/scripts && . /opt/scripts/install.sh

WORKDIR /var/www/html

ARG PCVE_SERVICE_HOST=probable-cve-api-probable-cve.devtools-dev.ext.devshift.net
# ENV pcve_hostname=$PCVE_SERVICE_HOST
# # RUN echo pcve_hostname
# RUN echo ${pcve_hostname}
RUN echo 'const APIENV={ "env":"'${PCVE_SERVICE_HOST}'"}' >> ./apienv.js

EXPOSE 8080

USER apache

ENTRYPOINT ["/opt/scripts/run.sh"]

CMD ["apache"]

# Prod build. Dev env doesn't run beyond this
# FROM base-ui as build-ui
# RUN npm build

# FROM nginx:alpine
# COPY --from=build-ui /app/build/ /usr/share/nginx/html