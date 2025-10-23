# DNS設定手順

n8nと同じHTTPS環境を構築するため、DNSレコードを追加します。

## 必要なDNSレコード

xvps.jpのDNS管理画面で以下の2つのAレコードを追加してください：

```
タイプ   ホスト名    値                TTL
A       archive     210.131.211.98    3600
A       search      210.131.211.98    3600
```

## 設定後のアクセスURL

DNS設定が反映されると（5-30分程度）、以下のURLでHTTPSアクセスできます：

- **ArchiveBox**: https://archive.xvps.jp
- **Fess検索**: https://search.xvps.jp
- **n8n**: https://feer-n8n.xvps.jp（既存）

## 確認方法

DNS設定が反映されているか確認：

```bash
# ArchiveBoxのDNS確認
nslookup archive.xvps.jp

# Fessの DNS確認
nslookup search.xvps.jp
```

`Address: 210.131.211.98` と表示されればOKです。

## Traefik自動設定

DNS設定が完了すれば、Traefikが自動的に：
1. Let's Encrypt証明書を取得
2. HTTPSアクセスを有効化
3. HTTP→HTTPSリダイレクトを設定

初回アクセス時に証明書取得のため数秒かかる場合がありますが、以降は即座にHTTPSでアクセスできます。

## トラブルシューティング

### DNS設定が反映されない場合

1. TTL（Time To Live）を確認（短い方が早く反映）
2. キャッシュをクリア：`sudo systemd-resolve --flush-caches`
3. 別のDNSサーバーで確認：`nslookup archive.xvps.jp 8.8.8.8`

### 証明書エラーが出る場合

Traefikのログを確認：
```bash
docker logs $(docker ps -q -f name=traefik) 2>&1 | grep -i "certificate\|acme"
```
