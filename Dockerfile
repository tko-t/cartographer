FROM ruby:2.7.0

ENV APP /app
ENV NOTO_FONTS /usr/share/fonts/noto
ENV NOTO_WORK $NOTO_FONTS/noto
ENV LANG C.UTF-8
ENV TZ=Asia/Tokyo
ENV EDITOR=vim
ENV DOCKER_USER vagrant

# ユーザーを作成
RUN groupadd -r --gid 1000 $DOCKER_USER \
 && useradd -m -r --uid 1000 --gid 1000 $DOCKER_USER

# create directory.
# 関連ディレクトリのオーナーをvagrantユーザーに変更
#RUN ls -la /usr/local/
#RUN ls -la $BUNDLE_APP_CONFIG
RUN mkdir -p $APP $NOTO_FONTS $NOTO_WORK $BUNDLE_APP_CONFIG \
 && chown -R $DOCKER_USER:$DOCKER_USER $APP \
 && chown -R $DOCKER_USER:$DOCKER_USER $NOTO_FONTS \
 && chown -R $DOCKER_USER:$DOCKER_USER $NOTO_WORK \
 && chown -R $DOCKER_USER:$DOCKER_USER $BUNDLE_APP_CONFIG # BUNDLE_APP_CONFIG == /usr/local/bundle
#RUN ls -la $BUNDLE_APP_CONFIG
#RUN ls -la /usr/local/

# rails credentials:edit のためにvimも入れとく
RUN apt update -qq \
 && apt install -y apt-transport-https vim \
 #&& curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 #&& wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add \
 # 署名を追加(chromeのインストールに必要) -> apt-getでchromeと依存ライブラリをインストール
 && curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add \
 && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list

RUN apt update -qq \
 && apt remove -y nodejs yarn \
 && apt install -y build-essential libpq-dev mariadb-client google-chrome-stable
# build-essential: gcc とか make とか
# libpq-dev:       mysql-devel とか

# chromedriverの最新をインストール
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
 && curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
 && unzip /tmp/chromedriver_linux64.zip \
 && rm /tmp/chromedriver_linux64.zip \
 && mv chromedriver /usr/local/bin/
# && chown -R $DOCKER_USER:$DOCKER_USER $BUNDLE_APP_CONFIG

#RUN ls -la /usr/local/

# ここまでsuper user

USER $DOCKER_USER

# chrome日本語化対応にnotoフォントをインストール
WORKDIR $NOTO_WORK
RUN wget -q https://noto-website.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip \
 && unzip NotoSansCJKjp-hinted.zip \
 && mv *.otf $NOTO_FONTS/ \
 && rm -rf $NOTO_WORK

WORKDIR $APP
#ADD Gemfile* $APP/
ADD . $APP
#RUN bundle install

#ADD . $APP

CMD "/bin/bash"
