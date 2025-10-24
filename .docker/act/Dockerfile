FROM ubuntu:24.04

# 基本的なツールをインストール
RUN apt-get update && apt-get install -y \
    curl \
    git \
    bash \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# act CLI をインストール
RUN curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash

# act の bin ディレクトリを PATH に追加
ENV PATH="/root/bin:${PATH}"

# act のデフォルト設定を作成（初期化を自動スキップ）
RUN mkdir -p /root/.config/act && \
    echo "# ACT Configuration" > /root/.config/act/actrc && \
    echo "container: docker" >> /root/.config/act/actrc && \
    echo "image: node:18-bullseye" >> /root/.config/act/actrc

# /workspace ディレクトリを作成
RUN mkdir -p /workspace
WORKDIR /workspace

# スリープコマンド（永続的に起動したままにするため）
CMD ["/bin/bash", "-c", "while true; do sleep 3600; done"]
