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
  echo "TEST"
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
        echo "-o FILENAME Output file path."
        echo "-r FILENAME Specify a docx templete(reference.docx) for pandoc"
        echo "-h          Show this help."
        exit 1
}

while getopts fno:r:h OPT
do
  case $OPT in
    f)  IS_FORCE=1
      ;;
    n)  IS_NEST=1
      ;;
    o)  OUTPUT_PATH=$OPTARG
      ;;
    r)  REF_FILE=$OPTARG
      ;;
    h)  usage_exit
      ;;
    \?) usage_exit
      ;;
  esac
done

shift $((OPTIND - 1))

##### Main #####

## オプションに対する処理

OPT_REF=""
if [ -n "$REF_FILE" ]; then
  OPT_REF="--reference-docx=$REF_FILE"
fi
OPT_REF=`abspath $OPT_REF`

OPT_OUTPUT="./output.docx"
if [ -n "$OUTPUT_PATH" ]; then
  OPT_OUTPUT=$OUTPUT_PATH
fi
OPT_OUTPUT=`abspath $OPT_OUTPUT`

# 出力ファイルの存在チェック
if [ -f $OPT_OUTPUT ] & [ $IS_FORCE -eq 0 ]; then
  echo "$OPT_OUTPUT is already exists. Overwrite? [Y/n]"
  RES=`yesno`
  if $RES = "no"; then
    exit 1
  fi
fi

if [ -n "$1" ]; then
  SOURCE_DIR=$1
  # 末尾のスラッシュを削除して正規化
  SOURCE_DIR=${SOURCE_DIR%/}
else
  usage_exit
fi
SOURCE_DIR=`abspath $SOURCE_DIR`

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
if type dot > /dev/null 2>&1; then
  dot $IMAGE_SEARCH_PATH/*.dot -Tpng -O
fi
if type java  > /dev/null 2>&1 & [ -f $PUML_PATH ]; then
  java -jar $PUML_PATH $IMAGE_SEARCH_PATH/*.puml
fi
if type blockdiag > /dev/null 2>&1; then
  blockdiag -Tpng --antialias --no-transparency $IMAGE_SEARCH_PATH/*.blockdiag
fi
if type seqdiag > /dev/null 2>&1; then
  seqdiag -Tpng --antialias --no-transparency $IMAGE_SEARCH_PATH/*.seqdiag
fi
if type actdiag > /dev/null 2>&1; then
  actdiag -Tpng --antialias --no-transparency $IMAGE_SEARCH_PATH/*.actdiag
fi
if type nwdiag > /dev/null 2>&1; then
  nwdiag -Tpng --antialias --no-transparency $IMAGE_SEARCH_PATH/*.nwdiag
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

# docxファイルをビルド
pandoc $MD_SEARCH_PATH/*.md $OPT_REF --toc --toc-depth=3 -o "$OPT_OUTPUT"
docxtable-php update -f $OPT_OUTPUT -s MyTable

