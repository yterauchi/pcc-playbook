
## summary

これは[PrimeCloud Controller](http://www.primecloud-controller.org)サーバをAnsibleにより自動構築するためのPlay Bookである。
[チュートリアル](http://www.primecloud-controller.org/documentation/tutorial/step0.html)の手順をYAML化している。

ただしチュートリアルでは、予めビルドされた[バイナリ](http://www.primecloud-controller.org/download/index.html)をインストールしているが、本自動化ツールでは、githubの[PrimeCloud Controllerリポジトリ](https://github.com/primecloud-controller-org/primecloud-controller)より、指定したバージョンのソースコードをcloneしビルドしている。設定により、任意のブランチ、バージョンをインストールすることができる。

ビルド作業以降の手順は、チュートリアルとは異なるコマンドを発行している部分もありが、実施事項はまったく同じである。
想定しているネットワークアドレスやホスト名などのインストール条件は、チュートリアルと同じであるため、予め同じ設定としておくこと。

## 実行準備

### インスタンスの作成

以下のAMIよりEC2インスタンスを作成する。
セキュリティグループについても、[こちら](http://www.primecloud-controller.org/documentation/tutorial/step1.html#section-1)を参考に設定すること。
```
ami-68147968  primecloud_controller-centos6-201510220559
```

### ネットワーキング設定

作成したインスタンスに対して、AWS management consoleで[こちら](http://www.primecloud-controller.org/documentation/tutorial/step1.html#section-1)を参考に以下2点の設定をする。

* Source/Dest Checkの無効化
* VPC内でのルーティング設定

### sshとターゲットホストの設定

Ansibleのホストグループに、pccを作り、ターゲットホストのIPアドレスを追加。ansible-playbookは、"pcc"グループのホストに対してコマンドを発行する。
rootの鍵ファイルは、ansibleのhostsファイルにて設定しておき、ansibleを実行するホストからターゲットホストに 対し、rootでsshログインができることを予め確認しておくこと。

```
/etc/ansible/hostsの例:

[pcc]
50.60.70.80 <--作成したEC2インスタンスのIPアドレス

[pcc:vars]
ansible_ssh_user=root
ansible_ssh_private_key_file=/root/.ssh/KEY_FILE_NAME.pem

```

### ymlファイルの修正

#### PCCバージョンの指定 vars.yml

2015/12/21時点で最新は`2.5.2-SNAPSHOT`、Stable版は`2.5.1`である。
バージョンおよびブランチを設定する。

最新にしたい場合:
```
github_url: https://github.com/primecloud-controller-org/primecloud-controller.git
pcc_version: 2.5.2-SNAPSHOT
checkout_version: master
```
安定版にしたい場合:
```
github_url: https://github.com/primecloud-controller-org/primecloud-controller.git
pcc_version: 2.5.1
checkout_version: 2.5.1
```


#### vars_user.yml

この変数ファイルには、以下のパラメータを予め設定しておく。

* `vpc_id`: PCCインスタンスを作成したサブネットをもつVPC IDを設定。PCCサーバと同じサブネットに、PCC管理のインスタンスを作成することを想定。
* `aws_access_key_id`: PCCのプラットフォームとして登録するAWSアカウントIDを記載(上記VPC IDを持つアカウントであること)
* `aws_secret_access_key`: AWSアクセスキーに対応するシークレットキーを記載
* `pcc_user_id`: PCCにログインするID
* `pcc_user_pw`: PCCにログインするパスワード

#### 証明書の設定

PCCサーバがOpenVPNやGUIアクセスのためのhttpsで使用するサーバ証明書のパラメータを`files/vars`ファイルに記載する。
任意の文字列に変更してください。

### Oracle JDKパッケージ保存

[Oracleのサイト](http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html)から、`jdk-6u45-linux-x86-rpm.bin`をダウンロードし、filesディレクトリに保存する。


## 実行手順

### ansibleの実行

* ansible-playbook pcc_server_build.yml
* ansible-playbook pcc_tutorial.yml
* ansible-playbook install-sh.yml

まとめて実行するシェルスクリプトとして`all.sh`を作ってあるので、それを実行しても良い。

インストール作業は、おおよそ30分程かかる。

### zabbix GUIでの設定

Ansibleのplay bookが終了したら、以下を順次実行することでPCCサーバへのログインが可能となる。

#### GUIで初期セットアップ

zabbix GUIにアクセスする。
```
https://<IPaddress>/zabbix
```

指示に従いウィザードを進行させる。"4.Confiure DB Connection"にて入力するMySQLのuserは`zabbix`、パスワードは`password`。

#### Zabbix設定のインポートとAPIユーザ作成

［こちら］(http://www.primecloud-controller.org/documentation/tutorial/step5.html#zabbix-4)の手順に従い、Zabbix設定のインポートとZabbix APIアクセスユーザの作成を行う。

### PCCユーザ作成

PCCユーザ管理ツールはzabbix APIへのアクセスが必要である。上記zabbix設定が終わると、zabbix APIへのアクセス が可能となるため、以下を実行することができる。

* ansible-playbook pcc_user.yml


### PCCへのアクセス

以上で、PCCのインストールが終了である。以下のURLでPCCにアクセスが可能となっている。

```
https://<IPaddress>/auto-web
```

## YAML呼び出し構造

```
pcc_server_build.yml
  |-os_setup.yml
  |-oracle_jdk_install.yml
  |-maven_install.yml
  |-pcc_source_get.yml
  
pcc_source_build.yml

pcc_tutorial.yml
  |-openvpn_install.yml
  |   |-easy_rsa.yml
  |
  |-named_install.yml
  |
  |-install-sh.yml
      |-apache.yml
      |-zabbix.yml
      |-pcc_user.yml
      |-tomcat.yml

pcc_user.yml
```

## その他ファイル

* files
    インスタンスへ転送するファイルを配置

* openjdk_install.yml
    oracle_jdk_install.ymlでは、Oracle JDKをインストールするが、こちらを呼び出すとOpenJDKをインストールす る。
    ただし、後続タスクであるinstall-sh.ymlでは、PCCサーバでのJDKはOracle JDKを想定しているので、単純に入れ替えはできない。

* test.yml
    taskのみを宣言しているYAMLを、個別に実行するための暫定的なファイル。


ライセンス
GNU General Public License Version 2

