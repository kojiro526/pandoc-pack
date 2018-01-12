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
IS_NEST=0
PUML_PATH=~/bin/plantuml.jar

# Parsing options
usage_exit() {
        echo "Usage: $0 [-n] [-r reference_file_name] source_dir" 1>&2
        exit 1
}

while getopts no:r:h OPT
do
  case $OPT in
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

OPT_REF=""
if [ -n "$REF_FILE" ]; then
  OPT_REF="--reference-docx=$REF_FILE"
fi

OPT_OUTPUT="./output.docx"
if [ -n "$OUTPUT_PATH" ]; then
  OPT_OUTPUT=$OUTPUT_PATH
fi

if [ -n "$1" ]; then
  SOURCE_DIR=$1
else
  usage_exit
fi

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
  dot $SOURCE_DIR/**/images/*.dot -Tpng -O
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

# ビルド用に画像をコピー
if [ $IS_NEST -eq 1 ]; then
  rm -rf $SOURCE_DIR/images/*
  cp $IMAGE_SEARCH_PATH/*.png $SOURCE_DIR/images/
  cp $IMAGE_SEARCH_PATH/*.jpg $SOURCE_DIR/images/
fi

# docxファイルをビルド
pandoc $MD_SEARCH_PATH/*.md $OPT_REF --toc --toc-depth=3 -o "$OPT_OUTPUT"
docxtable-php update -f $OPT_OUTPUT -s MyTable

