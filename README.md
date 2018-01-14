# Pandocによるdocxビルド環境

## 概要

Pandocを利用してMarkdownからdocxファイルをビルドするにあたって必要な処理をまとめたビルドスクリプト（`build.sh`）を提供します。

また、スクリプトが依存するツール群をdockerで容易に導入できるようにするDockerfileも提供します。

本リポジトリで提供するビルドスクリプトは以下のツールに依存します。

- Pandoc
    - https://pandoc.org/
- php-docxtable
    - https://github.com/kojiro526/php-docxtable
- 画像生成ツール
    - PlantUML
        - http://plantuml.com/
    - Graphviz
        - https://graphviz.gitlab.io/
    - blockdiag, seqdiag, actdiag, nwdiag
        - http://blockdiag.com/ja/blockdiag/
        - http://blockdiag.com/ja/seqdiag/
        - http://blockdiag.com/ja/actdiag/
        - http://blockdiag.com/ja/nwdiag/

ビルドスクリプトはMacで利用することが前提（おそらくLinuxでも動作可能）ですが、dockerを使えばWindowsでも利用可能です。

## ビルドスクリプト

本リポジトリにはPandocによるdocxファイルの生成を行うためのビルドスクリプト（`build.sh`）が含まれます。

ビルドスクリプトは以下の環境が存在することを前提としています。（以下の環境はDockerで構築することもできます）

- Pandocがインストールされていること。（必須）
- php-docxtableがグローバルインストールされていること。（任意）
- 前述の画像生成ツールがインストールされていること。（任意）
    - PlantUMLはGraphvizに依存しているため、両方をインストールすること。
    - PlantUMLは`~/bin/`配下に`plantuml.jar`が配置されていること。

### ビルドスクリプトが前提とするディレクトリ構成

ビルドスクリプトはMakrdownと画像ファイルが以下のいずれかのディレクトリ構成を取ることを前提としています。

#### 章（Chapter）構成

ディレクトリ配下にMarkdownファイルが並列に配置される形式です。

画像ファイルは同じ階層に`images`ディレクトリを作成し、その中に配置します。

```
┳ images/ 
┃  ┣ image1.puml
┃  ┣ image2.dot
┃  ┣ image3.blockdiag
┃  ┣ image4.seqdiag
┃  ┣ image5.actdiag
┃  ┣ image6.nwdiag
┃  ┣ image7.png
┃  ┗ image8.jpg
┣ chapter1.md
┣ chapter2.md
```

#### 部・章（Part - Chapter）構成

部（Part）に相当するディレクトリを作成し、その下に章に相当するMarkdownファイルを配置する形式です。

画像は各部ごとに`images`ディレクトリを作成し、各Markdownファイルからは同じ部の配下にあるimagesディレクトリ内の画像を参照するようにします。

```
┳ images/ （Pandocでのビルド時に一時的に使用するディレクトリのため、画像は配置しないこと）
┣ part1/
┃  ┣ images/
┃  ┃  ┣ image1.png
┃  ┃  ┗ image2.jpg
┃  ┣ chapter1.md
┃  ┗ chapter2.md
┣ part2
┃  ┣ images/
┃  ┃  ┣ image3.png
┃  ┃  ┗ image4.jpg
┃  ┣ chapter3.md
┃  ┗ chapter4.md
```

- ビルドスクリプトは、各部の配下のimagesディレクトリ内の画像をトップレベルのimagesディレクトリ内にコピーしたのち、Pandocによるdocx生成を行います。
    - Markdownファイル内に記述した画像ファイルの参照パスは、Pandocによるビルド時はPandocを実行したディレクトリを起点としたパスになるためです。

## 使い方

ビルドスクリプトの使い方は以下の通りです。

```
Usage: ./build.sh [OPTIONS] directory
-f          Attempt to overwrite the output file without prompting for confirmation.
-n          Specify this when the structure of your project is part/chapter.
-o FILENAME Output file path.
-r FILENAME Specify a docx templete(reference.docx) for pandoc
-h          Show this help.
```

__-f__

`-o`で指定した出力ファイルがすでに存在する場合に、強制的に上書きをします。

__-n__

ドキュメントのディレクトリ構成が、前述の部・章構成の場合に指定します。指定が無ければ章構成を前提とします。

__-o FILENAME__

出力するファイル（docx形式）のパスを指定します。

ファイルがすでに存在する場合、通常は上書きを確認するプロンプトが表示されます。

__-r FILENAME__

Pandocで利用するテンプレートファイル（reference.docx）を指定します。

__directory__

Markdownファイルが配置されたディレクトリのパスを指定します。

### 使い方の例

```
$ bash build.sh -n -o ./path_to_output.docx -r ./path_to_reference.docx ./path_to_source_dir
```

## Docker

本リポジトリに含まれるDockerfileを元にビルドしたDockerイメージには、以下のツールが含まれます。

- Pandoc (1.19.2.1)
- php-docxtable  (ビルド時の最新バージョン)
- 画像生成ツール
    - PlantUML  (ビルド時の最新バージョン)
    - Graphviz  (ビルド時の最新バージョン)
    - blockdiag, seqdiag, actdiag, nwdiag  (ビルド時の最新バージョン)


Dockerイメージのビルド方法は以下の通り。

```
$ docker build -t kojiro526/pandoc-pack .
```

上記でビルドしたdockerイメージを使ってdocxを生成する方法は以下の通り。

```
$ docker run --rm -i -v $(pwd):/work kojiro526/pandoc-pack build.sh -r /work/template/reference.docx -o /work/output.docx /work
```

- `--rm`オプションを付加して、処理を実行後にコンテナが自動的に削除されるようにします。
- 出力ファイルの上書き確認などでプロンプトを表示するためには、`-i`オプションを付加する必要があります。
    - ビルドスクリプトに`-f`オプションを付加する場合は、`-i`オプションは必要ありません。
- カレントディレクトリ（`$(pwd)`）をコンテナ内の`/work`にマウントします。
    - ビルドスクリプトに与えるパスはコンテナにマウントされた`/work`から始まる絶対パスで指定します。
- ビルドスクリプトはコンテナ内の`/usr/local/bin`に実行権限付きで配置されるため、直接指定して実行可能です。
- カレントディレクトリ配下の`./template/reference.docx`をテンプレートファイルに指定します。
- カレントディレクトリ配下に`output.docx`という名前でファイルを出力します。
- カレントディレクトリをソースディレクトリに指定します。

出力ファイルの上書き確認などを行わないようにする場合は、以下のようにします。

```
$ docker run --rm -v $(pwd):/work kojiro526/pandoc-pack build.sh -f -r /work/template/reference.docx -o /work/output.docx /work
```

