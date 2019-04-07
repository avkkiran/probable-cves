FROM python:3.7.2-slim as base-api

WORKDIR /src

COPY ./src /src

EXPOSE 5000

RUN pip3 install -r requirements.txt  && rm requirements.txt

ENTRYPOINT [ "python" ]

CMD [ "cve.py" ]

# Prod build. Dev env doesn't run beyond this
# FROM base-api as build-api
# RUN npm build

# FROM nginx:alpine
# COPY --from=build-api /app/build/ /usr/share/nginx/html
