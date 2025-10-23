# Gateway Timeout トラブルシューティング

## 問題の症状
- https://archive.210.131.211.98.nip.io にアクセスすると「Gateway Timeout」
- https://search.210.131.211.98.nip.io も同様の問題の可能性

## 診断手順

### 1. 診断スクリプトの実行

VPS上で以下を実行：

```bash
cd /opt/my-archive
chmod +x diagnose_timeout.sh
./diagnose_timeout.sh > diagnosis_$(date +%Y%m%d_%H%M%S).log 2>&1
```

ログファイルを確認して、以下の問題パターンを特定します。

## 考えられる原因と修正方法

### 原因1: ArchiveBoxが起動していない

**症状**:
- `docker compose ps` でarchiveboxのSTATUSが「Up」ではない
- ログに `wget: error` または接続エラー

**修正**:
```bash
cd /opt/my-archive
docker compose -f docker-compose.vps.yml restart archivebox
docker compose -f docker-compose.vps.yml logs -f archivebox
```

起動に失敗する場合、`docker-compose.vps.yml`のcommandを確認：
```yaml
command: server --quick-init 0.0.0.0:8000
```

### 原因2: Traefikがarchiveboxを見つけられない

**症状**:
- Traefikログに `backend not found` や `service not found`
- ネットワーク検査でarchiveboxが `n8n-compose_default` に接続されていない

**修正**:

1. ネットワーク再接続：
```bash
cd /opt/my-archive
docker compose -f docker-compose.vps.yml down
docker compose -f docker-compose.vps.yml up -d
```

2. Traefikがarchiveboxを認識しているか確認：
```bash
docker logs $(docker ps -q -f name=traefik) 2>&1 | grep -i archivebox
```

### 原因3: ポート8000でリッスンしていない

**症状**:
- `curl http://localhost:8002` でエラー
- ArchiveBoxログに `command not found` や起動エラー

**修正**:

ArchiveBoxのcommandが正しいか確認。以下に変更を試す：

```bash
cd /opt/my-archive
nano docker-compose.vps.yml
```

commandを以下のいずれかに変更：
```yaml
# オプション1 (現在)
command: server --quick-init 0.0.0.0:8000

# オプション2
command: server 0.0.0.0:8000

# オプション3
command: ["archivebox", "server", "0.0.0.0:8000"]
```

変更後：
```bash
docker compose -f docker-compose.vps.yml up -d archivebox
```

### 原因4: Traefik証明書取得の遅延

**症状**:
- 直接HTTP (http://210.131.211.98:8002) はアクセスできる
- HTTPSのみタイムアウト
- Traefikログに `acme` や `certificate` エラー

**修正**:

1. HTTP経由でアクセスを試す（証明書をスキップ）：
```bash
curl -H "Host: archive.210.131.211.98.nip.io" http://210.131.211.98/
```

2. Traefikのacmeログを確認：
```bash
docker logs $(docker ps -q -f name=traefik) 2>&1 | grep -i "acme\|certificate"
```

3. 証明書取得に時間がかかっている場合、5-10分待ってから再度アクセス

### 原因5: Traefik設定の問題

**症状**:
- すべてのサービスでタイムアウト
- Traefikログに設定エラー

**修正**:

Traefik設定を確認：
```bash
# Traefikの設定ファイルを確認
docker exec $(docker ps -q -f name=traefik) cat /etc/traefik/traefik.yml

# または静的設定を確認
docker inspect $(docker ps -q -f name=traefik) | grep -A 20 "Args"
```

## 緊急対応: Traefikをバイパスして直接アクセス

HTTPS経由でアクセスできない場合、一時的に直接HTTPでアクセス：

```bash
# ファイアウォールでポート開放（既に開放済みのはず）
ufw allow 8002/tcp
ufw allow 8081/tcp
```

アクセスURL:
- **ArchiveBox**: http://210.131.211.98:8002
- **Fess**: http://210.131.211.98:8081

## 最終手段: Traefik経由の設定を一時的に無効化

Traefik経由でどうしてもアクセスできない場合：

```bash
cd /opt/my-archive
nano docker-compose.vps.yml
```

ArchiveBoxとFessのlabelsセクションをコメントアウト：

```yaml
# labels:
#   - "traefik.enable=true"
#   - "traefik.http.routers.archivebox.rule=Host(`archive.${DOMAIN:-210.131.211.98.nip.io}`)"
#   ...
```

再起動：
```bash
docker compose -f docker-compose.vps.yml up -d
```

この場合、直接HTTPポート経由でのみアクセス可能になります。

## 診断結果の共有

診断ログを確認して、特定の問題が見つかった場合、そのセクションのログを共有してください。

```bash
cat diagnosis_*.log
```
