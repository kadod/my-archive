# マイ魚拓 - プライベートアーカイブシステム

ArchiveBox + Pocket + Fess を組み合わせた、全文検索可能なプライベートWebアーカイブシステム

## 🚀 VPSへの即時デプロイ

### VPS情報
- **IPアドレス**: 210.131.211.98
- **スペック**: 4コア / 6GB RAM / 150GB SSD
- **OS**: Ubuntu 22.04

### 3ステップでデプロイ

```bash
# 1. VPSに接続
ssh root@210.131.211.98

# 2. リポジトリをクローン
cd /opt
git clone <your-repository-url> my-archive
cd my-archive

# 3. デプロイ実行
chmod +x deploy-vps.sh
./deploy-vps.sh
```

### アクセスURL（デプロイ後）

- **ArchiveBox**: http://210.131.211.98
- **Fess検索**: http://210.131.211.98:8081
- **Fess管理**: http://210.131.211.98:8081/admin (admin/admin)

詳細は **[VPS_DEPLOY.md](VPS_DEPLOY.md)** を参照

## 特徴

- **ArchiveBox**: Webページのアーカイブ（PDF、スクリーンショット、WARC形式）
- **Pocket**: いつでもどこでもアーカイブ登録（RSS連携）
- **Fess**: 全文検索エンジン
- **Elasticsearch**: 検索インデックス
- **Nginx**: リバースプロキシ + SSL/TLS対応

## 必要要件

### 最小スペック
- **CPU**: 2コア
- **メモリ**: 4GB
- **ストレージ**: 20GB以上

### ソフトウェア
- Docker 20.10+
- Docker Compose 2.0+

## ローカル環境でのセットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd my-archive
```

### 2. サービスの起動

```bash
docker-compose up -d
```

### 3. アクセス

- **ArchiveBox**: http://localhost:8000
- **Fess検索**: http://localhost:8080
- **Fess管理画面**: http://localhost:8080/admin
  - ユーザー名: `admin`
  - パスワード: `admin`

## VPSへのデプロイ

### 前提条件

- Ubuntu 20.04 / 22.04 または CentOS 7/8
- ドメイン名の取得
- DNSレコードの設定（AレコードでVPSのIPアドレスを指定）

### 1. VPSに接続

```bash
ssh user@your-vps-ip
```

### 2. リポジトリのクローン

```bash
git clone <repository-url>
cd my-archive
```

### 3. 環境変数の設定

```bash
cp .env.example .env
nano .env
```

以下を編集：
```env
DOMAIN=your-domain.com
CERTBOT_EMAIL=your-email@example.com
BASIC_AUTH_USER=admin
BASIC_AUTH_PASSWORD=secure_password_here
```

### 4. デプロイスクリプトの実行

```bash
chmod +x deploy.sh
./deploy.sh
```

このスクリプトは以下を自動実行します：
- Docker / Docker Compose のインストール確認
- Let's Encrypt SSL証明書の取得
- 全サービスの起動

### 5. アクセス確認

- **ArchiveBox**: https://your-domain.com
- **Fess検索**: https://your-domain.com:8080

## 使い方

### URLのアーカイブ

#### 方法1: ArchiveBox UI

1. https://your-domain.com にアクセス
2. "Add" ボタンからURLを入力

#### 方法2: コマンドライン

```bash
# 単一URL
echo 'https://example.com' | docker-compose exec -T archivebox archivebox add

# 複数URL（ファイルから）
cat urls.txt | docker-compose exec -T archivebox archivebox add

# RSSフィード
docker-compose exec archivebox archivebox add 'https://example.com/feed.xml'
```

#### 方法3: Pocket連携（推奨）

1. **Pocketアカウント作成**: https://getpocket.com
2. **RSS公開設定**:
   - アカウント設定 → プライバシー
   - "RSSフィードのパスワード保護" を解除
3. **cron設定**（1時間ごとに自動取得）:

```bash
crontab -e
```

以下を追加：
```cron
0 * * * * cd /path/to/my-archive && docker-compose exec -T archivebox archivebox add 'http://getpocket.com/users/YOUR-USERNAME/feed/all'
```

### Fess検索設定

#### 1. クローラ設定

1. Fess管理画面にログイン: https://your-domain.com:8080/admin
2. **クローラ** → **ウェブ** → **新規作成**
3. 以下を設定：
   - **名前**: ArchiveBox
   - **URL**: `http://archivebox:8000/`
   - **クロール対象**: `http://archivebox:8000/.*`
   - **間隔**: 1000
   - **スレッド数**: 5
   - **深さ**: 3

#### 2. 手動クローリング実行

1. **システム** → **スケジューラ**
2. **Default Crawler** の "今すぐ開始" をクリック
3. **システム** → **ジョブログ** で進捗確認

#### 3. 検索テスト

- Fessトップページで検索実行
- アーカイブ内容の全文検索が可能

## 管理コマンド

### サービス状態確認

```bash
docker-compose ps
```

### ログ確認

```bash
# 全サービス
docker-compose logs -f

# 特定サービス
docker-compose logs -f archivebox
docker-compose logs -f fess
docker-compose logs -f elasticsearch
```

### サービス再起動

```bash
docker-compose restart
```

### データバックアップ

```bash
# Dockerボリュームのバックアップ
docker run --rm -v my-archive_archivebox-data:/data -v $(pwd):/backup ubuntu tar czf /backup/archivebox-backup.tar.gz /data
docker run --rm -v my-archive_elasticsearch-data:/data -v $(pwd):/backup ubuntu tar czf /backup/elasticsearch-backup.tar.gz /data
```

### SSL証明書の更新

```bash
docker run --rm -v $(pwd)/ssl:/etc/letsencrypt certbot/certbot renew
docker-compose restart nginx
```

## トラブルシューティング

### Elasticsearchが起動しない

メモリ不足の場合、`docker-compose.yml` の以下を調整：

```yaml
environment:
  - "ES_JAVA_OPTS=-Xms512m -Xmx512m"  # 1g → 512m
```

### ArchiveBoxのアーカイブが失敗する

タイムアウト設定を増やす：

```yaml
environment:
  - TIMEOUT=120
  - MEDIA_TIMEOUT=240
```

### SSL証明書エラー

Let's Encrypt証明書は90日で期限切れとなります。自動更新をcronに設定：

```bash
0 0 1 * * cd /path/to/my-archive && docker run --rm -v $(pwd)/ssl:/etc/letsencrypt certbot/certbot renew && docker-compose restart nginx
```

## セキュリティ考慮事項

1. **ファイアウォール設定**:
   - 80番ポート（HTTP）
   - 443番ポート（HTTPS）
   - 8080番ポート（Fess）のみ開放

2. **Basic認証**: nginx.confで設定可能

3. **定期アップデート**:
```bash
docker-compose pull
docker-compose up -d
```

## ライセンス

各コンポーネントのライセンスに従います：
- ArchiveBox: MIT License
- Fess: Apache License 2.0
- Elasticsearch: Elastic License 2.0
- Nginx: 2-clause BSD License

## 参考リンク

- [ArchiveBox公式](https://github.com/ArchiveBox/ArchiveBox)
- [Fess公式](https://fess.codelibs.org/ja/)
- [Pocket](https://getpocket.com/)
