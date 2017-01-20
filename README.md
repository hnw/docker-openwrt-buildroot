docker-openwrt-buildroot
========================

[![Build Status](https://travis-ci.org/hnw/docker-openwrt-buildroot.svg?branch=master)](https://travis-ci.org/hnw/docker-openwrt-buildroot) [![License: MIT](http://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/hnw/docker-openwrt-buildroot/blob/master/LICENSE)

[OpenWrt](https://openwrt.org/)の[buildroot](http://wiki.openwrt.org/doc/howto/buildroot.exigence)環境をDockerイメージで提供するプロジェクトです。

Travis CIを利用し、OpenWrt buildrootのtoolchainまでビルドした状態で[Docker Hubにデプロイ](https://hub.docker.com/r/yhnw/openwrt-buildroot/tags/)しています。toolchainのビルド時間は環境にもよりますが30分から1時間程度かかることが多いかと思います。このtoolchainの生成が既に済んでいる状態のDockerイメージがあると自前ビルドの心理的ハードルが下がるのではないでしょうか（自前の`*.ipk`が作りたいだけなら[OpenWrt SDK](https://wiki.openwrt.org/doc/howto/obtain.firmware.sdk)の利用をオススメします）。

このイメージは下記のようにすれば利用できます。

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
  - bcm53xx (Broadcom BCM47xx/53xx (ARM))
  - ramips-mt7620a (MediaTek MT7620)
  - ramips-rt305x (Ralink RT3x5x/RT5350)

# menuconfigの修正内容

ビルド設定のうち、デフォルトから変更している内容は下記の通りです。ビルド時間短縮が目的です。

* Global build settings
  - Use top-level make jobserver for packages
	- on → off
  - Number of package submake jobs (2-512)
	- 2 → 3
* Advanced configuration options (for developers)
  - Use ccache
	- off → on
