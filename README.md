docker-openwrt-buildroot
========================
[![License: MIT](http://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/hnw/docker-openwrt-buildroot/blob/master/LICENSE)


This is a docker container for the [OpenWRT](https://openwrt.org/)
[buildroot](http://wiki.openwrt.org/doc/howto/buildroot.exigence).

Because the build system requires that its command are not executed by root,
the user `openwrt` was created. The buildroot can be found in
`/home/openwrt/openwrt`.

To run a shell in the buildroot, execute the following command:

```sh
docker run -it -u openwrt yhnw/openwrt-buildroot:15.05.1-ar71xx bash
```
More information on how to use this buildroot can be found on the
[OpenWRT wiki](http://wiki.openwrt.org/doc/howto/build).



docker-openwrt-buildroot
========================

[OpenWRT](https://openwrt.org/)の[buildroot](http://wiki.openwrt.org/doc/howto/buildroot.exigence)環境をDockerイメージで提供するプロジェクトです。

Travis CIを利用し、OpenWrt buildrootのtoolchainまでビルドした状態でDocker Hubにデプロイしています。一番時間のかかるtoolchainの生成が既に済んでいる状態のDockerイメージがあると自前ビルドの心理的ハードルが下がるのではないでしょうか（個人的には、自前の`*.ipk`が作りたいだけならOpenWrt SDKの利用をオススメします）。

このイメージは下記のようにすれば使えます。

```
$ docker run -it -u openwrt yhnw/openwrt-buildroot:15.05.1-ar71xx bash
# cd openwrt
# scripts/feeds update -a
```

ここで`make menuconfig`や`make kernel_menuconfig`などで設定をしてから`make`すれば`bin/`以下にカスタムファームウェアが作られます。

注意点ですが、Dockerイメージのダイエットのため`dl/`以下のアーカイブファイルを0バイトに切り詰めてあります。この状態でも`make`を行うだけなら問題がないのですが、`make toolchain/install`などとツール類を再作成しようとするとエラーで怒られますので、その際は一度`dl/`以下の全ファイルを削除してください。

現時点では下記の組み合わせのイメージしか提供していません。必要な組み合わせがあればissueなりpull requestなりからご連絡ください。

 * OpenWrtバージョン
   - 15.05.1
 * 対応ボード
   - ar71xx（Atheros AR71xx/AR7240/AR913x/AR934x）
