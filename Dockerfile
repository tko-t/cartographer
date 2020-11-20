FROM ruby:2.7-alpine

ENV APP /app
ENV LANG C.UTF-8
ENV TZ=Asia/Tokyo
ENV EDITOR=vim
ENV DOCKER_USER vagrant

# ユーザーグループを作成
RUN addgroup -S $DOCKER_USER \
  && adduser -S $DOCKER_USER -G $DOCKER_USER \
  && echo "${DOCKER_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && echo "${DOCKER_USER}:${DOCKER_USER}" | chpasswd

# create directory.
# 関連ディレクトリの作成＆オーナーをvagrantユーザーに変更
# $BUNDLE_APP_CONFIG == /usr/local/bundle
RUN mkdir -p $APP $BUNDLE_APP_CONFIG \
 && chown -R $DOCKER_USER:$DOCKER_USER $APP \
 && chown -R $DOCKER_USER:$DOCKER_USER $BUNDLE_APP_CONFIG

# rails credentials:edit のためにvimも入れとく
RUN apk add --update --no-cache --virtual=.build-dependencies \
    vim \
    build-base \
    curl-dev \
    linux-headers \
    libxml2-dev \
    libxslt-dev \
    mysql-dev \
    ruby-dev \
    yaml-dev \
    zlib-dev && \
  apk add --update --no-cache \
    bash \
    make \
    gcc \
    libc-dev \
    git \
    openssh \
    ruby-json \
    tzdata \
    yaml && \
  apk del .build-dependencies

# ここまでsuper user

USER $DOCKER_USER

WORKDIR $APP
ADD . $APP

CMD "/bin/bash"
