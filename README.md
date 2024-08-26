# ita-toolbox

## これは何？

Human68k ITA TOOLBOX の各ツールをビルドするための環境 (のつもり) です。

## 事前準備1

Human68k に下記ツールをインストールしてください。

- [GNU Make](https://github.com/kg68k/gnu-make-human68k)
- [fish](http://retropc.net/x68000/software/tools/itatoolbox/fish/) 等の UN*X 系シェル
  - `MAKE_SHELL=fish.x` のように環境変数を設定すること
- [HAS060.X](http://retropc.net/x68000/software/develop/as/has060/) (アセンブラ)
- [hlk](https://github.com/kg68k/hlk-ev) (リンカ)
- [oar](http://retropc.net/x68000/software/develop/ar/oar/) (オブジェクトアーカイバ)
- [C Compiler PRO-68K (XC)](http://retropc.net/x68000/software/sharp/xc21/) の LIB.X (ライブラリアン) 
  - *.a を *.l に変換するのに必要
- [ITA TOOLBOX](http://retropc.net/x68000/software/tools/itatoolbox/) の cp / mv / rm
- [GNU Grep](https://www.vector.co.jp/soft/x68/util/se021835.html)
  - fish をビルドする場合のみ必要

## 事前準備2

```sh
git clone --recursive https://github.com/68fpjc/ita-toolbox.git
```
などとして、ソースファイルをサブモジュールごと取得してください。

その後、取得したソースファイルを Human68k の環境に配置してください。その際、ローカル Git リポジトリディレクトリ (`.git/`) やドットファイル (`.gitignore` 等) は削除して問題ありません。

## ビルド

Human68k 上で `01-fish` / `02-login` / … /  `34-colrm` の各サブディレクトリへ移動し、
```
make
````
してください。

- fish 以外をビルドする際も、 `01-fish` ディレクトリに fish のソースファイルが存在している必要があります。
- `07-mv` や `08-cp` 等をビルドするためのソースファイルが不足していたため、相当品を用意しました。
  -  [`lib/getlnenv.s`](lib/getlnenv.s) … l[ndrv](http://retropc.net/x68000/software/disk/symlink/lndrv/) のソースファイルから同等の処理を抜粋し、手直ししたもの

## 補足

- ビルドによって生成される `*.x` の動作確認はほぼ実施していません。
- `Makefile` には `*.lzh` 生成や ish 変換のターゲットも定義されていますが、動かないと考えてください (今さら使いませんよね？)。

以上
