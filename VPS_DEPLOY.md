# VPSデプロイ手順書

## VPS情報

- **IPアドレス**: 210.131.211.98
- **ホスト名**: x210-131-211-98.static.xvps.ne.jp
- **OS**: Ubuntu 22.04
- **スペック**: 4コア / 6GB RAM / 150GB SSD
- **既存アプリ**: n8n

## アクセスURL（デプロイ後）

### HTTPS経由（推奨・本格構成）
- **ArchiveBox**: https://archive.210.131.211.98.nip.io
- **Fess検索**: https://search.210.131.211.98.nip.io
- **n8n**: https://n8n.yourdomain.com（既存）

### 直接アクセス（開発・確認用）
- **ArchiveBox**: http://210.131.211.98:8002
- **Fess検索**: http://210.131.211.98:8081
- **n8n**: http://210.131.211.98:5678（既存）

※ nip.ioはワイルドカードDNSサービスです。独自ドメインを持っている場合は`.env`ファイルで設定してください。

## デプロイ手順

### 1. VPSに接続

```bash
ssh root@210.131.211.98
# または
ssh root@x210-131-211-98.static.xvps.ne.jp
```

### 2. システムアップデート

```bash
apt update && apt upgrade -y
```

### 3. 必要なパッケージのインストール

```bash
# Gitのインストール
apt install -y git curl

# Dockerのインストール（まだの場合）
curl -fsSL https://get.docker.com | sh

# Docker Composeのインストール確認
docker compose version
```

### 4. リポジトリのクローン

```bash
cd /opt
git clone <your-repository-url> my-archive
cd my-archive
```

### 5. 環境変数の設定（オプション）

独自ドメインを使用する場合：

```bash
# .envファイルを作成
cp .env.example .env
nano .env

# DOMAINを自分のドメインに変更
DOMAIN=yourdomain.com
```

ドメインがない場合はnip.ioが自動使用されます（設定不要）。

### 6. デプロイ実行

```bash
# VPS用の設定でサービス起動
docker compose -f docker-compose.vps.yml up -d
```

### 7. 起動確認

```bash
# サービス状態確認
docker compose -f docker-compose.vps.yml ps

# ログ確認
docker compose -f docker-compose.vps.yml logs -f
```

起動には数分かかります。全サービスが「Up」状態になるまで待ちます。

### 8. アクセステスト

ブラウザで以下にアクセス：

**HTTPS経由（推奨）：**
- ArchiveBox: https://archive.210.131.211.98.nip.io
- Fess検索: https://search.210.131.211.98.nip.io

**直接アクセス：**
- ArchiveBox: http://210.131.211.98:8002
- Fess: http://210.131.211.98:8081

※ 初回アクセス時、Let's Encrypt証明書取得に数秒かかる場合があります。

## ファイアウォール設定

### UFWを使用する場合

```bash
# UFWのインストール（必要な場合）
apt install -y ufw

# 基本ルール設定
ufw default deny incoming
ufw default allow outgoing

# 必要なポートを開放
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP (ArchiveBox)
ufw allow 8081/tcp    # Fess
ufw allow 5678/tcp    # n8n (既存)

# UFW有効化
ufw enable

# 状態確認
ufw status
```

## システムアーキテクチャ

### 本格構成の特徴

```
インターネット
    ↓ HTTPS (443)
[Traefik - 既存のn8nリバースプロキシ] ← Let's Encrypt自動証明書取得
    ├→ archive.210.131.211.98.nip.io → ArchiveBox:8000
    ├→ search.210.131.211.98.nip.io → Fess:8080
    └→ n8n.yourdomain.com → n8n:5678 (既存)

[ArchiveBox] → archivebox-data volume
    ↓ クロール対象
[Fess 14.17.0] → fess-data volume
    ↓ 検索クエリ
[Elasticsearch 8.13.4] → elasticsearch-data volume (1GB RAM割り当て)
```

### 外部Elasticsearchの利点

- **パフォーマンスチューニング**: メモリ設定の最適化が可能
- **スケーラビリティ**: データ量に応じた拡張が容易
- **バージョン管理**: Fessと互換性のあるESバージョンを明示的に指定
- **安定性**: Fess 14.17.0 + ES 8.13.4は検証済みの組み合わせ

### HTTPS対応

既存のTraefikを活用してHTTPS化：
- Let's Encrypt証明書の自動取得・更新
- HTTP→HTTPSの自動リダイレクト
- ポート80/443の競合回避（Traefikが一元管理）
- 独自ドメインまたはnip.ioサブドメイン対応

## Fess検索設定

### 1. Fess管理画面にアクセス

http://210.131.211.98:8081/admin

- ユーザー名: `admin`
- パスワード: `admin`

### 2. クローラ設定

**システム** → **クローラ** → **ウェブ** → **新規作成**

- **名前**: ArchiveBox
- **URL**: `http://archivebox:8000/`
- **クロール対象**: `http://archivebox:8000/.*`
- **間隔**: 1000
- **スレッド数**: 5
- **深さ**: 3

### 3. クローリング実行

**システム** → **スケジューラ** → **Default Crawler** → **今すぐ開始**

## Pocket連携設定

### 1. Pocketアカウント設定

1. https://getpocket.com でアカウント作成
2. アカウント設定 → プライバシー
3. "RSSフィードのパスワード保護" を解除
4. RSSフィードURLをコピー

### 2. cron設定（1時間ごとに自動取得）

```bash
crontab -e
```

以下を追加：

```cron
0 * * * * cd /opt/my-archive && docker compose -f docker-compose.vps.yml exec -T archivebox archivebox add 'http://getpocket.com/users/YOUR-USERNAME/feed/all' >> /var/log/archivebox-pocket.log 2>&1
```

## 管理コマンド

### サービス再起動

```bash
cd /opt/my-archive
docker compose -f docker-compose.vps.yml restart
```

### ログ確認

```bash
# 全サービス
docker compose -f docker-compose.vps.yml logs -f

# 特定サービス
docker compose -f docker-compose.vps.yml logs -f archivebox
docker compose -f docker-compose.vps.yml logs -f fess
docker compose -f docker-compose.vps.yml logs -f elasticsearch
```

### URLの手動追加

```bash
# 単一URL
echo 'https://example.com' | docker compose -f docker-compose.vps.yml exec -T archivebox archivebox add

# ファイルから一括追加
cat urls.txt | docker compose -f docker-compose.vps.yml exec -T archivebox archivebox add
```

### サービス停止

```bash
cd /opt/my-archive
docker compose -f docker-compose.vps.yml down
```

### 完全削除（データも削除）

```bash
cd /opt/my-archive
docker compose -f docker-compose.vps.yml down -v
```

## データバックアップ

### 手動バックアップ

```bash
# バックアップディレクトリ作成
mkdir -p /backup

# ArchiveBoxデータのバックアップ
docker run --rm \
  -v my-archive_archivebox-data:/data \
  -v /backup:/backup \
  ubuntu tar czf /backup/archivebox-$(date +%Y%m%d).tar.gz /data

# Elasticsearchデータのバックアップ
docker run --rm \
  -v my-archive_elasticsearch-data:/data \
  -v /backup:/backup \
  ubuntu tar czf /backup/elasticsearch-$(date +%Y%m%d).tar.gz /data
```

### 自動バックアップ（cron）

```bash
crontab -e
```

以下を追加（毎日3時にバックアップ）：

```cron
0 3 * * * docker run --rm -v my-archive_archivebox-data:/data -v /backup:/backup ubuntu tar czf /backup/archivebox-$(date +\%Y\%m\%d).tar.gz /data
0 3 * * * docker run --rm -v my-archive_elasticsearch-data:/data -v /backup:/backup ubuntu tar czf /backup/elasticsearch-$(date +\%Y\%m\%d).tar.gz /data
```

## トラブルシューティング

### ポート競合エラー

n8nと競合する場合、`docker-compose.vps.yml` のポート設定を変更：

```yaml
ports:
  - "8082:8080"  # Fessのポートを8082に変更
```

### メモリ不足

Elasticsearchのメモリ設定を調整：

```yaml
environment:
  - "ES_JAVA_OPTS=-Xms1g -Xmx1g"  # 2g → 1g
```

### サービスが起動しない

```bash
# サービス状態確認
docker compose -f docker-compose.vps.yml ps

# エラーログ確認
docker compose -f docker-compose.vps.yml logs
```

## セキュリティ推奨設定

### 1. SSH鍵認証の設定

パスワード認証を無効化し、SSH鍵認証のみ許可

### 2. fail2banのインストール

```bash
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### 3. 自動アップデート

```bash
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

## 定期メンテナンス

### 月次メンテナンス

```bash
# システムアップデート
apt update && apt upgrade -y

# Dockerイメージ更新
cd /opt/my-archive
docker compose -f docker-compose.vps.yml pull
docker compose -f docker-compose.vps.yml up -d

# 未使用イメージ削除
docker system prune -a -f
```

## サポート情報

問題が発生した場合：

1. ログを確認: `docker compose -f docker-compose.vps.yml logs`
2. サービス状態確認: `docker compose -f docker-compose.vps.yml ps`
3. ディスク容量確認: `df -h`
4. メモリ使用状況確認: `free -h`
