#!/bin/bash
# Gateway Timeout診断スクリプト

echo "========================================"
echo "Gateway Timeout 診断ツール"
echo "========================================"
echo ""

cd /opt/my-archive

echo "1. コンテナ状態確認"
echo "----------------------------------------"
docker compose -f docker-compose.vps.yml ps
echo ""

echo "2. ArchiveBox ログ確認 (最新30行)"
echo "----------------------------------------"
docker compose -f docker-compose.vps.yml logs --tail 30 archivebox
echo ""

echo "3. ArchiveBox ヘルスチェック"
echo "----------------------------------------"
echo "ArchiveBoxに内部からアクセステスト:"
docker compose -f docker-compose.vps.yml exec -T archivebox wget -O- http://localhost:8000/ 2>&1 | head -20
echo ""

echo "4. Traefik コンテナ確認"
echo "----------------------------------------"
docker ps --filter "name=traefik" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "5. Traefik ログ (最新50行)"
echo "----------------------------------------"
TRAEFIK_CONTAINER=$(docker ps -q -f name=traefik)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | grep -E "archive|error|ERROR|timeout"
else
    echo "ERROR: Traefikコンテナが見つかりません"
fi
echo ""

echo "6. ネットワーク接続確認"
echo "----------------------------------------"
echo "n8n-compose_defaultネットワーク上のコンテナ:"
docker network inspect n8n-compose_default --format '{{range $k, $v := .Containers}}{{printf "%s: %s\n" $v.Name $v.IPv4Address}}{{end}}'
echo ""

echo "7. Traefik設定確認"
echo "----------------------------------------"
echo "ArchiveBoxのTraefikラベル:"
docker inspect my-archive-archivebox-1 | grep -A 10 "traefik"
echo ""

echo "8. ポート確認"
echo "----------------------------------------"
echo "VPS上の8002, 8081ポート確認:"
netstat -tlnp | grep -E "8002|8081"
echo ""

echo "9. 直接HTTPアクセステスト"
echo "----------------------------------------"
echo "ArchiveBox (localhost:8002):"
curl -I http://localhost:8002 2>&1 | head -10
echo ""
echo "Fess (localhost:8081):"
curl -I http://localhost:8081 2>&1 | head -10
echo ""

echo "========================================"
echo "診断完了"
echo "========================================"
