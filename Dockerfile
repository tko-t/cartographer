FROM ruby:2.7.0

ENV APP /app
ENV LANG C.UTF-8
ENV TZ=Asia/Tokyo
ENV EDITOR=vim
ENV DOCKER_USER vagrant

# ユーザーグループを作成
RUN groupadd -r --gid 1000 $DOCKER_USER \
 && useradd -m -r --uid 1000 --gid 1000 $DOCKER_USER

# create directory.
# 関連ディレクトリの作成＆オーナーをvagrantユーザーに変更
# $BUNDLE_APP_CONFIG == /usr/local/bundle
RUN mkdir -p $APP $BUNDLE_APP_CONFIG \
 && chown -R $DOCKER_USER:$DOCKER_USER $APP \
 && chown -R $DOCKER_USER:$DOCKER_USER $BUNDLE_APP_CONFIG

# rails credentials:edit のためにvimも入れとく
RUN apt-get update -qq \
 && apt-get upgrade -y \
 && apt-get remove -y nodejs yarn
 && apt-get install -y apt-transport-https vim build-essential libpq-dev

# ここまでsuper user

USER $DOCKER_USER

WORKDIR $APP
ADD . $APP

CMD "/bin/bash"
