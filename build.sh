#!/bin/bash

# docxビルドスクリプト
#
# Usage:
#
# 1.  引数を省略するとデフォルトのファイル名は output.docx
#     bash ./build.sh
# 2.  第一引数でファイル名のベースを指定可能。
#     以下のコマンドで生成されるファイルのは mydocx.docx
#     bash ./build.sh mydocx
#
# 注意
# 各種の作図ツールは予めインストールされていること。
# 以下の例で plantuml.jar は ~/bin に格納されているものとする。


SOURCE_DIR=.
IS_FORCE=0
IS_NEST=0
BUILD_IMAGE_ONLY=0
PUML_PATH=~/bin/plantuml.jar

# 相対パスを絶対パスに変換する関数
abspath() {
  if [ -z "$1" ]; then
    echo ""
  else
    dir=$(cd $(dirname $1) && pwd)
    abspath=${dir%/}/$(basename $1)
    echo $abspath
  fi
}

# ユーザの入力を受け取る関数
yesno() {
  read ANSWER
  case $ANSWER in
    "" | "Y" | "y" | "yes" | "Yes" | "YES" ) echo "yes";;
    * ) echo "no";;
  esac
}

# Parsing options
usage_exit() {
        echo "Usage: $0 [OPTIONS] directory" 1>&2
        echo "-f          Attempt to overwrite the output file without prompting for confirmation."
        echo "-n          Specify this when the structure of your project is part/chapter."
        echo "-i          Specify this if you want to build images only."
        echo "-o FILENAME Output file path."
        echo "-r FILENAME Specify a docx templete(reference.docx) for pandoc"
        echo "-p OPTIONS  Specify another pandoc options."
        echo "-h          Show this help."
        exit 1
}

while getopts fnio:r:p:h OPT
do
  case $OPT in
    f)  IS_FORCE=1
      ;;
    n)  IS_NEST=1
      ;;
    i)  BUILD_IMAGE_ONLY=1
      ;;
    o)  OUTPUT_PATH=$OPTARG
      ;;
    r)  REF_FILE=$OPTARG
      ;;
    p)  PANDOC_OPTIONS=$OPTARG
      ;;
    h)  usage_exit
      ;;
    \?) usage_exit
      ;;
  esac
done

shift $((OPTIND - 1))

##### Main #####

## 引数に対する処理

if [ -n "$1" ]; then
  SOURCE_DIR=$1
  # 末尾のスラッシュを削除して正規化
  SOURCE_DIR=${SOURCE_DIR%/}
else
  usage_exit
fi
SOURCE_DIR=`abspath $SOURCE_DIR`

if [ ! -d $SOURCE_DIR ]; then
  echo "$SOURCE_DIR is not exists."
  exit 1
fi

## オプションに対する処理

OPT_REF=""
if [ -n "$REF_FILE" ]; then
  OPT_REF=`abspath $REF_FILE`
  OPT_REF="--reference-doc=$OPT_REF"
fi

OPT_OUTPUT="./output.docx"
if [ -n "$OUTPUT_PATH" ]; then
  OPT_OUTPUT=$OUTPUT_PATH
fi
OPT_OUTPUT=`abspath $OPT_OUTPUT`

# 出力ファイル名から拡張子を取得
OUTPUT_FORMAT=$(echo $OPT_OUTPUT | sed 's/^.*\.\([^\.]*\)$/\1/')
if [ "$OUTPUT_FORMAT" = $OPT_OUTPUT ]; then
  OUTPUT_FORMAT=""
fi

# 出力ファイルの存在チェック
if [ $BUILD_IMAGE_ONLY -eq 0 ] && [ -f $OPT_OUTPUT ] && [ $IS_FORCE -eq 0 ]; then
  echo "$OPT_OUTPUT is already exists. Overwrite? [Y/n]"
  RES=`yesno`
  if [ "$RES" = "no" ]; then
    exit 1
  fi
fi

## 変換処理

# pandocコマンドを実行するディレクトリをプロジェクト直下にするために移動
cd $SOURCE_DIR

# Markdownファイルと画像の検索パスを設定
# 部・章に分かれる構成の場合は再帰的に検索する。
if [ $IS_NEST -eq 0 ]; then
  MD_SEARCH_PATH=$SOURCE_DIR
else
  MD_SEARCH_PATH=$SOURCE_DIR/**
fi
IMAGE_SEARCH_PATH=$MD_SEARCH_PATH/images

# 図を生成
$( ls $IMAGE_SEARCH_PATH/*.dot > /dev/null 2>&1 )
if [ $? -eq 0 ] && type dot > /dev/null 2>&1; then
  dot $IMAGE_SEARCH_PATH/*.dot -Tpng -O
fi

$( ls $IMAGE_SEARCH_PATH/*.puml > /dev/null 2>&1 )
if [ $? -eq 0 ] && type java  > /dev/null 2>&1 && [ -f $PUML_PATH ]; then
  java -jar $PUML_PATH $IMAGE_SEARCH_PATH/*.puml
fi

$( ls $IMAGE_SEARCH_PATH/*.blockdiag > /dev/null 2>&1 )
if [ $? -eq 0 ] && type blockdiag > /dev/null 2>&1; then
  blockdiag -Tpng --antialias --no-transparency $IMAGE_SEARCH_PATH/*.blockdiag
fi

$( ls $IMAGE_SEARCH_PATH/*.seqdiag > /dev/null 2>&1 )
if [ $? -eq 0 ] && type seqdiag > /dev/null 2>&1; then
  seqdiag -Tpng --antialias --no-transparency $IMAGE_SEARCH_PATH/*.seqdiag
fi

$( ls $IMAGE_SEARCH_PATH/*.actdiag > /dev/null 2>&1 )
if [ $? -eq 0 ] && type actdiag > /dev/null 2>&1; then
  actdiag -Tpng --antialias --no-transparency $IMAGE_SEARCH_PATH/*.actdiag
fi

$( ls $IMAGE_SEARCH_PATH/*.nwdiag > /dev/null 2>&1 )
if [ $? -eq 0 ] && type nwdiag > /dev/null 2>&1; then
  nwdiag -Tpng --antialias --no-transparency $IMAGE_SEARCH_PATH/*.nwdiag
fi

if [ $BUILD_IMAGE_ONLY -eq 1 ]; then
  exit
fi

# ビルド用に画像を一時ディレクトリ内にコピー
if [ $IS_NEST -eq 1 ]; then
  if [ ! -e $SOURCE_DIR/images ]; then
    mkdir $SOURCE_DIR/images
  fi
  rm -rf $SOURCE_DIR/images/*
  cp $IMAGE_SEARCH_PATH/*.png $SOURCE_DIR/images/
  cp $IMAGE_SEARCH_PATH/*.jpg $SOURCE_DIR/images/
fi

