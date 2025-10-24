#!/bin/bash

# ==============================================================================
# GitHub Actions Workflow Test Helper
# ==============================================================================
# このスクリプトは、GitHub Actionsのワークフローをローカルでテストします
# 使用方法: ./test-workflow.sh [ワークフローファイルパス] [オプション]
# ==============================================================================

set -e

# テストスクリプト内での色出力をオフに（bash -c 内で問題が発生するため）
NO_COLOR=1

# カラー出力用の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ==============================================================================
# ヘルプメッセージ
# ==============================================================================
show_help() {
    cat << EOF
${BLUE}GitHub Actions Workflow テストツール${NC}

${GREEN}使用方法:${NC}
  ./test-workflow.sh [ワークフローファイル] [オプション]

${GREEN}引数:${NC}
  ワークフローファイル    テスト対象のワークフローファイルのパス
                        例: .github/workflows/manual-release.yml

${GREEN}オプション:${NC}
  -d, --dry-run         ドライラン実行（デフォルト）
  -e, --event EVENT     トリガーイベント（デフォルト: workflow_dispatch）
  -i, --input KEY=VAL   ワークフロー入力を指定（複数指定可）
                        例: -i version_bump=minor -i env=prod
  -s, --secrets FILE    シークレット情報を含むファイルを指定
  -l, --list            利用可能なワークフロー一覧を表示
  -h, --help            このメッセージを表示

${GREEN}例:${NC}
  # 基本的なドライラン
  ./test-workflow.sh .github/workflows/manual-release.yml

  # 入力パラメータ付きでテスト
  ./test-workflow.sh .github/workflows/manual-release.yml -i version_bump=minor

  # ドライラン + 詳細ログ表示
  ./test-workflow.sh .github/workflows/manual-release.yml -d

${GREEN}環境変数:${NC}
  ACT_LOG_LEVEL    ログレベル (trace, debug, info, warning, error)
                   デフォルト: info

EOF
}

# ==============================================================================
# ワークフロー一覧表示
# ==============================================================================
list_workflows() {
    echo -e "${BLUE}利用可能なワークフロー:${NC}\n"
    
    if [ -d "$PROJECT_ROOT/.github/workflows" ]; then
        find "$PROJECT_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml" | while read -r workflow; do
            workflow_name=$(basename "$workflow")
            workflow_rel_path=".github/workflows/$workflow_name"
            
            # ワークフローの説明を抽出
            description=$(grep -A 1 "^name:" "$workflow" | tail -1 | sed 's/^[[:space:]]*//' || echo "説明なし")
            
            echo -e "  ${GREEN}✓${NC} $workflow_rel_path"
            echo -e "     名前: $description"
            echo ""
        done
    else
        echo -e "${RED}✗${NC} .github/workflows ディレクトリが見つかりません"
        exit 1
    fi
}

# ==============================================================================
# ワークフローファイルの検証
# ==============================================================================
validate_workflow() {
    local workflow_file="$1"
    
    if [ ! -f "$PROJECT_ROOT/$workflow_file" ]; then
        echo -e "${RED}✗ エラー: ワークフローファイルが見つかりません${NC}"
        echo "  指定: $workflow_file"
        echo "  検索: $PROJECT_ROOT/$workflow_file"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} ワークフローファイル: $workflow_file"
}

# ==============================================================================
# ACT コマンドの構築
# ==============================================================================
build_act_command() {
    local workflow_file="$1"
    
    # act を呼び出す際の引数を準備
    # イベント名は第1引数として指定
    set -- "$EVENT"
    
    # ドライランオプション
    if [ "$DRY_RUN" = true ]; then
        set -- "$@" -n
    fi
    
    # ワークフローファイル
    set -- "$@" -W "$workflow_file"
    
    # 入力パラメータ
    if [ -n "$INPUTS" ]; then
        while IFS= read -r input; do
            set -- "$@" --input "$input"
        done <<< "$INPUTS"
    fi
    
    # シークレット
    if [ -n "$SECRETS_FILE" ]; then
        if [ -f "$SECRETS_FILE" ]; then
            set -- "$@" --secret-file "$SECRETS_FILE"
        else
            echo -e "${RED}✗ エラー: シークレットファイルが見つかりません${NC}"
            echo "  指定: $SECRETS_FILE"
            exit 1
        fi
    fi
    
    # ログレベル（ドライランモードが無効な場合）
    if [ "$DRY_RUN" != true ]; then
        set -- "$@" -v
    fi
    
    # 作成した引数をグローバル変数に保存（act コマンドは第1引数）
    act_cmd_args=("act" "$@")
}

# ==============================================================================
# ACT実行
# ==============================================================================
run_act() {
    local workflow_file="$1"
    shift
    local args="$@"
    
    validate_workflow "$workflow_file"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}ワークフローテスト実行${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # コマンド引数を構築
    build_act_command "$workflow_file" $args
    
    echo -e "${YELLOW}実行コマンド:${NC}"
    echo -e "  ${BLUE}${act_cmd_args[*]}${NC}"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}ℹ${NC} ドライランモード有効"
        echo ""
    fi
    
    echo -e "${YELLOW}ℹ${NC} ACT コンテナ内でワークフローをテスト実行中..."
    echo ""
    
    # docker compose exec で act コンテナ内で実行
    cd "$PROJECT_ROOT"
    
    # 配列を文字列に変換してbash -c 経由で実行
    local cmd_str=""
    for arg in "${act_cmd_args[@]}"; do
        # 特殊文字をエスケープ
        cmd_str="$cmd_str $(printf '%s\n' "$arg" | sed "s/'/'\\\\''/g" | sed "s/^/'/;s/\$/'/")"
    done
    
    # bash -c で実行
    if [ -t 0 ]; then
        docker compose exec -it act bash -c "$cmd_str"
    else
        docker compose exec -T act bash -c "$cmd_str"
    fi
}

# ==============================================================================
# メイン処理
# ==============================================================================
main() {
    local workflow_file=""
    local DRY_RUN=true
    local EVENT="workflow_dispatch"
    local INPUTS=""
    local SECRETS_FILE=""
    
    # 引数のパース
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_workflows
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -e|--event)
                EVENT="$2"
                shift 2
                ;;
            -i|--input)
                if [ -z "$INPUTS" ]; then
                    INPUTS="$2"
                else
                    INPUTS="$INPUTS"$'\n'"$2"
                fi
                shift 2
                ;;
            -s|--secrets)
                SECRETS_FILE="$2"
                shift 2
                ;;
            -*)
                echo -e "${RED}✗ 不明なオプション: $1${NC}"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$workflow_file" ]; then
                    workflow_file="$1"
                else
                    echo -e "${RED}✗ 複数のワークフローファイルは指定できません${NC}"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # ワークフローファイルが指定されているかチェック
    if [ -z "$workflow_file" ]; then
        echo -e "${RED}✗ エラー: ワークフローファイルが指定されていません${NC}\n"
        show_help
        exit 1
    fi
    
    # ACT の実行
    run_act "$workflow_file"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ テスト実行が完了しました${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# スクリプト実行
main "$@"
