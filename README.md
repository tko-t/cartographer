# cartographer

## Use

#### 指定したURLを起点に同じドメインのパス一覧を作成する

```
$ docker-compose run --rm app ruby cartographer.rb http://abc.jp:3000
```

#### param

```
URL           探索を開始するURLを引数
              routesを指定した場合は不要
```

#### options

```
--exploration 探索して
--routes      探索ルートファイル(yaml)を指定
```

link、button、submitを押して回ります

以下の構造を出力します

result
|-- exploration_yymmddhhmm_abc_jp_3000.json
|-- html
     |-- images
           |-- location_url_1_title.jpg
           |-- location_url_2_title.jpg
     |-- exploration_yymmddhhmm_abc_jp_3000.html


jsonのイメージ

```json
[
  {
    "url":"http://abc.jp:3000/login",
    "title":"ログイン"
  },
  {
    "url":"http://abc.jp:3000/users",
    "title":"ユーザー一覧"
  }
]
```

htmlのイメージ

```
<html>
  <body>
    <dl>
      <dt>title</dt>
      <dd>
        <p>/users</p>
        <p>/login -> 送信</p>
        <img src="./images/from_path_to_path_index.jpg"/>
      </dd>
      <dt>title</dt>
      <dd>
        ...
      </dd>
    </dl>
  </body>
</html>
```
