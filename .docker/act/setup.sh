#!/bin/bash

# ==============================================================================
# GitHub Actions Workflow Test Environment Setup
# ==============================================================================
# このスクリプトでワークフローテスト環境をセットアップします
# ==============================================================================

set -e

# カラー出力用の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}GitHub Actions Workflow Test Environment Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ==============================================================================
# 1. Docker のチェック
# ==============================================================================
echo -e "${YELLOW}[1/4]${NC} Docker 環境のチェック..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker がインストールされていません${NC}"
    echo "  https://www.docker.com/products/docker-desktop からインストールしてください"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose がインストールされていません${NC}"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "${RED}✗ Docker デーモンが起動していません${NC}"
    echo "  Docker Desktop を起動してください"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker がインストールされています"
echo -e "  Docker version: $(docker --version)"
echo -e "  Docker Compose version: $(docker compose version)"
echo ""

# ==============================================================================
# 2. act コンテナのビルド・起動
# ==============================================================================
echo -e "${YELLOW}[2/4]${NC} ACT コンテナの準備..."

cd "$PROJECT_ROOT"

# docker-compose.yml に act サービスが定義されているか確認
if ! grep -q "act:" docker-compose.yml; then
    echo -e "${RED}✗ docker-compose.yml に act サービスが定義されていません${NC}"
    exit 1
fi

# Dockerfile が存在するか確認
if [ ! -f "$PROJECT_ROOT/.docker/act/Dockerfile" ]; then
    echo -e "${RED}✗ .docker/act/Dockerfile が見つかりません${NC}"
    exit 1
fi

echo -e "${YELLOW}ℹ${NC} ACT コンテナをビルド・起動中..."

if ! docker compose up -d act > /dev/null 2>&1; then
    echo -e "${RED}✗ ACT コンテナの起動に失敗しました${NC}"
    docker compose logs act
    exit 1
fi

# コンテナの起動を待つ
sleep 2

# コンテナが起動しているか確認
if docker compose ps act 2>/dev/null | grep -q "Up"; then
    echo -e "${GREEN}✓${NC} ACT コンテナが起動しました"
else
    echo -e "${RED}✗ ACT コンテナが起動していません${NC}"
    docker compose logs act
    exit 1
fi

# act コマンドが利用可能か確認
if docker compose exec act which act > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 'act' コマンドがコンテナ内で利用可能です"
    ACT_VERSION=$(docker compose exec act act --version 2>&1 || echo "unknown")
    echo -e "  Version: $ACT_VERSION"
else
    echo -e "${YELLOW}⚠${NC} 'act' コマンドが見つかりません（問題が発生した可能性があります）"
fi

echo ""

# ==============================================================================
# 3. テストスクリプトのセットアップ
# ==============================================================================
echo -e "${YELLOW}[3/4]${NC} テストスクリプトのセットアップ..."

TEST_SCRIPT="$PROJECT_ROOT/.docker/act/test-workflow.sh"

if [ ! -f "$TEST_SCRIPT" ]; then
    echo -e "${RED}✗ テストスクリプトが見つかりません${NC}"
    exit 1
fi

if [ ! -x "$TEST_SCRIPT" ]; then
    chmod +x "$TEST_SCRIPT"
    echo -e "${GREEN}✓${NC} テストスクリプトを実行可能にしました"
else
    echo -e "${GREEN}✓${NC} テストスクリプトは実行可能です"
fi

echo ""

# ==============================================================================
# 4. 利用可能なワークフロー一覧
# ==============================================================================
echo -e "${YELLOW}[4/4]${NC} ワークフロー一覧の確認..."

if [ -d "$PROJECT_ROOT/.github/workflows" ]; then
    WORKFLOW_COUNT=$(find "$PROJECT_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
    
    if [ "$WORKFLOW_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} $WORKFLOW_COUNT 個のワークフローが見つかりました"
        echo ""
        echo -e "${BLUE}利用可能なワークフロー:${NC}"
        find "$PROJECT_ROOT/.github/workflows" \( -name "*.yml" -o -name "*.yaml" \) | while read -r workflow; do
            workflow_name=$(basename "$workflow")
            echo -e "  ${GREEN}•${NC} .github/workflows/$workflow_name"
        done
    else
        echo -e "${YELLOW}⚠${NC} ワークフローが見つかりません"
    fi
else
    echo -e "${RED}✗ .github/workflows ディレクトリが見つかりません${NC}"
fi

echo ""

# ==============================================================================
# セットアップ完了
# ==============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ セットアップが完了しました!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}次のステップ:${NC}"
echo ""
echo -e "1. ${YELLOW}ワークフロー一覧を表示:${NC}"
echo -e "   $ ./.docker/act/test-workflow.sh --list"
echo ""
echo -e "2. ${YELLOW}ワークフローをドライラン:${NC}"
echo -e "   $ ./.docker/act/test-workflow.sh .github/workflows/manual-release.yml"
echo ""
echo -e "3. ${YELLOW}入力パラメータ付きでテスト:${NC}"
echo -e "   $ ./.docker/act/test-workflow.sh .github/workflows/manual-release.yml \\\\"
echo -e "     -i version_bump=minor"
echo ""
echo -e "詳細は以下のドキュメントを参照:${NC}"
echo -e "   $ cat .docker/ACT_WORKFLOW_TEST_GUIDE.md"
echo ""
