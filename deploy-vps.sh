#!/bin/bash

set -e

echo "=========================================="
echo "  マイ魚拓 VPSデプロイスクリプト"
echo "  VPS IP: 210.131.211.98"
echo "=========================================="
echo ""

# Docker のインストール確認
if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker がインストールされていません"
    echo "   インストールしますか？ (y/n)"
    read -r answer
    if [ "$answer" = "y" ]; then
        echo "🔧 Docker をインストールしています..."
        curl -fsSL https://get.docker.com | sh
        systemctl start docker
        systemctl enable docker
        echo "✅ Docker のインストールが完了しました"
    else
        echo "❌ Docker が必要です"
        exit 1
    fi
fi

echo "✅ Docker を確認しました"
echo ""

# Docker Compose のインストール確認
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose が利用できません"
    echo "   Docker を最新版に更新してください"
    exit 1
fi

echo "✅ Docker Compose を確認しました"
echo ""

# ファイアウォール設定の確認
if command -v ufw &> /dev/null; then
    echo "🔒 ファイアウォール設定を確認しています..."

    # UFWが有効か確認
    if ufw status | grep -q "Status: active"; then
        echo "   UFWが有効です。必要なポートを開放します..."

        # 必要なポートを開放
        ufw allow 22/tcp   # SSH
        ufw allow 80/tcp   # HTTP (ArchiveBox)
        ufw allow 8081/tcp # Fess

        echo "✅ ファイアウォール設定が完了しました"
    else
        echo "⚠️  UFWが無効です。セキュリティのため有効化を推奨します"
    fi
else
    echo "ℹ️  UFWがインストールされていません"
fi

echo ""
echo "🚀 Dockerコンテナを起動します..."
docker compose -f docker-compose.vps.yml up -d

echo ""
echo "⏳ サービスの起動を待機しています（60秒）..."
sleep 60

echo ""
echo "📊 サービス状態を確認しています..."
docker compose -f docker-compose.vps.yml ps

echo ""
echo "=========================================="
echo "  デプロイが完了しました！"
echo "=========================================="
echo ""
echo "🌐 アクセスURL："
echo "   - ArchiveBox: http://210.131.211.98"
echo "   - Fess検索:   http://210.131.211.98:8081"
echo ""
echo "📝 次のステップ："
echo "   1. Fess管理画面でクローラを設定"
echo "      http://210.131.211.98:8081/admin"
echo "      (admin/admin)"
echo ""
echo "   2. Pocket RSSを定期取得する cron を設定"
echo "      詳細は VPS_DEPLOY.md を参照"
echo ""
echo "🔧 管理コマンド："
echo "   サービス状態: docker compose -f docker-compose.vps.yml ps"
echo "   ログ確認:     docker compose -f docker-compose.vps.yml logs -f"
echo "   再起動:       docker compose -f docker-compose.vps.yml restart"
echo ""
