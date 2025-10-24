# GitHub Actions ワークフローローカルテスト環境

GitHub Actionsのワークフローをローカルでテストするための環境です。Docker コンテナ内で `nektos/act` を実行し、GitHub
Actions ワークフローをローカルマシンでテストできます。

## クイックスタート

### 環境のセットアップ

```bash
# 1回目のみ実行（コンテナのビルドと初期化）
./.docker/act/setup.sh
```

このコマンドは以下を実行します：

- Docker 環境の確認
- ACT コンテナのビルド・起動
- テストスクリプトの検証
- ワークフロー一覧の表示

### ワークフローのテスト実行

```bash
# 利用可能なワークフロー一覧を表示
./.docker/act/test-workflow.sh --list

# 基本的なドライラン（推奨）
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml

# 入力パラメータ付きでテスト
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \
  -i version_bump=minor
```

## アーキテクチャ

```
ホストマシン
  ├─ docker-compose.yml
  └─ .docker/
      └─ act/
          ├─ Dockerfile
          ├─ setup.sh
          ├─ test-workflow.sh
          └─ README.md

act コンテナ
  ├─ act コマンド（nektos/act）
  ├─ Docker CLI（ホストの Docker デーモンへアクセス）
  └─ プロジェクトボリューム（/workspace）
```

## ファイル構成

```
.docker/
└─ act/
   ├─ Dockerfile              # ACT コンテナ用 Dockerfile
   ├─ setup.sh                # 環境セットアップスクリプト
   ├─ test-workflow.sh        # ワークフローテスト実行スクリプト
   └─ README.md               # このファイル
```

## 主な特徴

✅ **コンテナ内で完結** - ホスト環境を汚さない  
✅ **ドライラン対応** - 実行前に動作確認可能  
✅ **入力パラメータ対応** - workflow_dispatch の入力をテスト可能  
✅ **リアルタイム出力** - ワークフロー実行状況をリアルタイムで確認  
✅ **再現性が高い** - Docker化により環境依存性を最小化

## 詳細な使用方法

### ワークフロー一覧の表示

利用可能なワークフロー一覧を確認できます。

```bash
./.docker/act/test-workflow.sh --list
```

### 基本的なテスト実行

```bash
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml
```

このコマンドは以下の操作を実行します：

- ワークフローファイルの検証
- ドライランモード（-n フラグ）でのテスト実行
- 実際の変更を加えずにワークフローの動作を確認

### 入力パラメータの指定

ワークフローが入力パラメータを必要とする場合、`-i` または `--input` オプションで指定します。

```bash
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \
  -i version_bump=minor
```

複数の入力パラメータを指定する場合：

```bash
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \
  -i version_bump=minor \
  -i target_env=production
```

### シークレット情報の指定

`-s` または `--secrets` オプションでシークレット情報を含むファイルを指定します。

```bash
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \
  -s .github/secrets
```

シークレットファイルの形式：

```
GITHUB_TOKEN=ghp_xxxxx
DATABASE_PASSWORD=secret123
API_KEY=key_xxxxx
```

### イベントタイプの指定

デフォルトは `workflow_dispatch` ですが、別のイベントタイプでテストする場合は `-e` オプションを使用します。

```bash
# push イベントでテスト
./.docker/act/test-workflow.sh .github/workflows/test.yml -e push

# pull_request イベントでテスト
./.docker/act/test-workflow.sh .github/workflows/test.yml -e pull_request
```

## 実践例

### manual-release.yml のテスト

```bash
# パッチリリースをシミュレート
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \
  -i version_bump=patch

# マイナーリリースをシミュレート  
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \
  -i version_bump=minor

# メジャーリリースをシミュレート
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \
  -i version_bump=major
```

### 複数入力パラメータ

```bash
./.docker/act/test-workflow.sh .github/workflows/some-workflow.yml \
  -i param1=value1 \
  -i param2=value2
```

### 実際の実行（ドライラン無し）

```bash
# ドライランモードを無効にして実際に実行
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \
  --dry-run false \
  -i version_bump=patch
```

## トラブルシューティング

### ACT コンテナが起動しない

```bash
# コンテナの状態確認
docker compose ps act

# コンテナのログ確認
docker compose logs act

# コンテナの再ビルド
docker compose up -d --build act

# フルクリーンアップと再起動
docker compose rm -f act
docker compose up -d act
```

### ワークフローファイルが見つからない

```bash
# 正しいパスを指定していることを確認
./.docker/act/test-workflow.sh --list

# フルパスで指定
./.docker/act/test-workflow.sh ./.github/workflows/manual-release.yml
```

### Docker ソケットのアクセス権限エラー

このエラーが表示された場合：

```
permission denied while trying to connect to Docker daemon socket
```

**解決方法:**

macOS の Docker Desktop の場合：

1. Docker Desktop を再起動
2. 再度セットアップを実行

Linux の場合：

```bash
# ユーザーを docker グループに追加
sudo usermod -aG docker $USER

# グループ変更を反映
newgrp docker

# Docker デーモンを再起動
sudo systemctl restart docker
```

### メモリ不足エラー

Docker Desktop のメモリ配分を増やしてください。

**macOS/Windows:**

1. Docker Desktop → Settings → Resources
2. Memory を増やす（推奨: 4GB 以上）
3. Docker Desktop を再起動

### 'act' コマンドが見つからない

コンテナ内で act が見つからない場合：

```bash
# コンテナ内で確認
docker compose exec act which act

# コンテナをリビルド
docker compose up -d --build act

# ビルドログを確認
docker compose build act --no-cache
```

### ワークフロー実行中にエラーが発生

詳細なログを確認：

```bash
# verbose モードで実行
ACT_LOG_LEVEL=debug ./.docker/act/test-workflow.sh .github/workflows/manual-release.yml

# または -v オプション付きで実行
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml
```

## CLI オプション一覧

| オプション       | 短形式  | 説明              | デフォルト             |
|-------------|------|-----------------|-------------------|
| `--help`    | `-h` | ヘルプメッセージを表示     | -                 |
| `--list`    | `-l` | ワークフロー一覧を表示     | -                 |
| `--dry-run` | `-d` | ドライランモード        | true              |
| `--event`   | `-e` | トリガーイベント        | workflow_dispatch |
| `--input`   | `-i` | ワークフロー入力（複数指定可） | -                 |
| `--secrets` | `-s` | シークレットファイル      | -                 |

## 環境変数

| 変数              | 説明                                         | デフォルト |
|-----------------|--------------------------------------------|-------|
| `ACT_LOG_LEVEL` | ログレベル (trace, debug, info, warning, error) | info  |

使用例：

```bash
ACT_LOG_LEVEL=debug ./.docker/act/test-workflow.sh .github/workflows/manual-release.yml
```

## ベストプラクティス

### 1. 必ずドライランで検証

本番環境への影響を避けるため、まずドライランで確認してください。

```bash
# ドライランで検証
./.docker/act/test-workflow.sh .github/workflows/manual-release.yml -i version_bump=minor
```

### 2. 段階的なテスト

複雑なワークフローは、各ステップを段階的にテストしてください。

```bash
# 簡単なワークフローから開始
./.docker/act/test-workflow.sh .github/workflows/lint.yml

# 徐々に複雑なものへ
./.docker/act/test-workflow.sh .github/workflows/build-and-deploy.yml
```

### 3. シークレット情報の管理

`.github/secrets` ファイルは `.gitignore` に追加し、リポジトリにコミットしないようにしてください。

```bash
# .gitignore に追加
echo ".github/secrets" >> .gitignore
```

## 環境情報

- **ACT バージョン**: 0.2.82
- **ベース イメージ**: ubuntu:24.04
- **Docker クライアント**: コンテナ内に含まれる

## 参考資料

- [nektos/act - GitHub](https://github.com/nektos/act)
- [act - Run your GitHub Actions locally](https://nektosact.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## サポート情報

問題が発生した場合は、以下の情報を提供してください：

1. エラーメッセージの全文
2. 実行したコマンド
3. `docker compose logs act` の出力
4. ワークフローファイルの内容
