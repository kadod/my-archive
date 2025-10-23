#!/bin/bash

set -e

echo "=========================================="
echo "  マイ魚拓 VPSデプロイスクリプト"
echo "=========================================="
echo ""

# 環境変数ファイルの確認
if [ ! -f .env ]; then
    echo "❌ .env ファイルが見つかりません"
    echo "   .env.example をコピーして .env を作成してください："
    echo "   cp .env.example .env"
    exit 1
fi

# .envファイルを読み込み
source .env

echo "✅ 環境変数ファイル (.env) を読み込みました"
echo ""

# Docker のインストール確認
if ! command -v docker &> /dev/null; then
    echo "❌ Docker がインストールされていません"
    echo "   以下のコマンドでインストールしてください："
    echo "   curl -fsSL https://get.docker.com | sh"
    exit 1
fi

echo "✅ Docker を確認しました"
echo ""

# Docker Compose のインストール確認
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose がインストールされていません"
    exit 1
fi

echo "✅ Docker Compose を確認しました"
echo ""

# SSL証明書ディレクトリの作成
mkdir -p ssl

# Let's Encrypt証明書の取得（初回のみ）
if [ ! -f ssl/fullchain.pem ]; then
    echo "📜 SSL証明書を取得します..."
    docker run --rm -v $(pwd)/ssl:/etc/letsencrypt/live/${DOMAIN} \
        certbot/certbot certonly --standalone \
        --email ${CERTBOT_EMAIL} \
        --agree-tos \
        --no-eff-email \
        -d ${DOMAIN}

    # 証明書をコピー
    cp ssl/live/${DOMAIN}/fullchain.pem ssl/
    cp ssl/live/${DOMAIN}/privkey.pem ssl/

    echo "✅ SSL証明書を取得しました"
else
    echo "✅ SSL証明書は既に存在します"
fi

echo ""
echo "🚀 Dockerコンテナを起動します..."
docker-compose up -d

echo ""
echo "⏳ サービスの起動を待機しています（30秒）..."
sleep 30

echo ""
echo "=========================================="
echo "  デプロイが完了しました！"
echo "=========================================="
echo ""
echo "🌐 アクセスURL："
echo "   - ArchiveBox: https://${DOMAIN}"
echo "   - Fess検索:   https://${DOMAIN}:8080"
echo ""
echo "📝 次のステップ："
echo "   1. Fess管理画面でクローラを設定"
echo "   2. Pocket RSSを定期取得する cron を設定"
echo ""
echo "🔧 サービス状態確認："
echo "   docker-compose ps"
echo ""
echo "📊 ログ確認："
echo "   docker-compose logs -f"
echo ""
