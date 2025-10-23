# クイックチェック - Gateway Timeout 診断

VPS上で以下のコマンドを順番に実行してください。

## 1. 直接HTTPアクセステスト（最優先）

ブラウザで以下のURLにアクセス：

- **ArchiveBox**: http://210.131.211.98:8002
- **Fess**: http://210.131.211.98:8081

✅ アクセスできた場合：サービスは正常。問題はTraefik設定。
❌ アクセスできない場合：サービス自体に問題あり。

## 2. VPS上でのローカルアクセステスト

```bash
# ArchiveBox内部アクセステスト
curl -I http://localhost:8002

# 成功例: HTTP/1.1 200 OK が返ってくる
# 失敗例: Connection refused
```

## 3. ArchiveBoxログ確認

```bash
cd /opt/my-archive
docker compose -f docker-compose.vps.yml logs --tail 50 archivebox
```

**確認ポイント**:
- `Uvicorn running on http://0.0.0.0:8000` があれば起動成功
- `Error` や `Failed` があれば問題あり

## 4. Traefikログ確認

```bash
docker logs $(docker ps -q -f name=traefik) --tail 100 2>&1 | grep -E "archive|error|timeout"
```

**確認ポイント**:
- `backend "archivebox@docker" not found` → ネットワーク問題
- `unable to obtain ACME certificate` → 証明書取得エラー
- エラーなし → 証明書取得中の可能性（5-10分待つ）

## 5. ネットワーク接続確認

```bash
# ArchiveBoxがTraefikネットワークに接続されているか
docker network inspect n8n-compose_default --format '{{range $k, $v := .Containers}}{{$v.Name}} {{end}}'
```

**確認ポイント**:
- `my-archive-archivebox-1` が表示されればOK
- 表示されない場合はネットワーク再接続が必要

## 問題別の修正方法

### ケース1: 直接HTTP (8002) はOKだが、HTTPS (nip.io) がNG

**原因**: Traefik証明書取得中または設定問題

**修正**:
```bash
# Traefik証明書ログ確認
docker logs $(docker ps -q -f name=traefik) 2>&1 | grep -i "acme\|certificate" | tail -20

# 5-10分待ってから再度HTTPSアクセス
# それでもダメなら、Traefik再起動
docker restart $(docker ps -q -f name=traefik)
```

### ケース2: 直接HTTP (8002) もNG

**原因**: ArchiveBox起動失敗

**修正**:
```bash
cd /opt/my-archive

# ArchiveBox再起動
docker compose -f docker-compose.vps.yml restart archivebox

# ログをリアルタイム監視
docker compose -f docker-compose.vps.yml logs -f archivebox
```

起動メッセージで `Uvicorn running on http://0.0.0.0:8000` を確認。

### ケース3: ネットワーク接続がない

**原因**: コンテナがTraefikネットワークに接続されていない

**修正**:
```bash
cd /opt/my-archive
docker compose -f docker-compose.vps.yml down
docker compose -f docker-compose.vps.yml up -d
```

## 診断結果報告

以下の情報を確認して報告してください：

1. **直接HTTPアクセス結果**:
   - http://210.131.211.98:8002 → ✅ OK / ❌ NG
   - http://210.131.211.98:8081 → ✅ OK / ❌ NG

2. **ArchiveBoxログ**（最後の数行）

3. **Traefikログ**（エラーがあれば）

これらの情報があれば、具体的な修正方法を提案できます。
