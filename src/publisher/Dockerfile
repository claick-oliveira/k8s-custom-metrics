FROM alpine:3.17.2

LABEL maintainer="Claick Oliveira" \
      version="0.1.0"

RUN apk add --no-cache bash py3-pip && \
    pip3 install --upgrade pip

RUN adduser -D app
USER app
ENV APP_PATH /home/app
WORKDIR ${APP_PATH}

COPY --chown=app:app src/publisher ${APP_PATH}
COPY --chown=app:app requirements.txt ${APP_PATH}/requirements.txt

RUN pip3 install --user -r requirements.txt

ENV PATH="${APP_PATH}/.local/bin:${PATH}"

ENTRYPOINT ["python3", "-u", "app.py"]
