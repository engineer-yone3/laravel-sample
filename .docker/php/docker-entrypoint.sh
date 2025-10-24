#!/bin/bash

echo "[Docker Entrypoint] Initializing Laravel SSL environment..."

# SSL証明書の自動生成・確認
echo "[Docker Entrypoint] Starting SSL certificate verification..."

# 証明書生成ディレクトリの作成
mkdir -p /ssl

# 既存の証明書をチェック
if [ -f "/ssl/localhost.crt" ] && [ -f "/ssl/localhost.key" ]; then
    echo "[Docker Entrypoint] Found existing certificates. Checking expiration..."
    
    # 証明書の有効期限をチェック（30日以内に期限切れなら再生成）
    if openssl x509 -checkend 2592000 -noout -in /ssl/localhost.crt >/dev/null 2>&1; then
        echo "[Docker Entrypoint] ✅ Valid SSL certificates exist. Skipping generation."
        
        # 証明書の詳細情報を表示
        echo "[Docker Entrypoint] 📅 Certificate information:"
        openssl x509 -in /ssl/localhost.crt -noout -dates | sed 's/^/[Docker Entrypoint]   /'
    else
        echo "[Docker Entrypoint] ⚠️  Certificates will expire within 30 days. Generating new certificates..."
        # 古い証明書ファイルを削除
        rm -f /ssl/localhost.*
        GENERATE_CERT=true
    fi
else
    echo "[Docker Entrypoint] 📜 No certificates found. Generating new certificates..."
    GENERATE_CERT=true
fi

# 証明書生成が必要な場合
if [ "$GENERATE_CERT" = "true" ]; then
    echo "[Docker Entrypoint] 🔑 Generating private key..."
    openssl genrsa -out /ssl/localhost.key 2048

    echo "[Docker Entrypoint] 📋 Creating certificate signing request..."
    
    # OpenSSL設定ファイルを作成
    cat > /ssl/openssl.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = JP
ST = Tokyo
L = Tokyo
O = Laravel Sample
CN = localhost

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

    # 設定ファイルを使用してCSRを生成
    openssl req -new -key /ssl/localhost.key -out /ssl/localhost.csr -config /ssl/openssl.conf

    echo "[Docker Entrypoint] 📄 Generating self-signed certificate..."
    
    # 設定ファイルを使用して証明書を生成
    openssl x509 -req -in /ssl/localhost.csr -signkey /ssl/localhost.key \
        -out /ssl/localhost.crt -days 365 \
        -extensions v3_req \
        -extfile /ssl/openssl.conf
    
    # 設定ファイルを削除
    rm -f /ssl/openssl.conf

    # 不要なファイルを削除
    rm -f /ssl/localhost.csr

    # 権限設定
    chmod 600 /ssl/localhost.key
    chmod 644 /ssl/localhost.crt

    echo "[Docker Entrypoint] ✅ SSL certificate generation completed!"
    echo "[Docker Entrypoint] 📁 Generated files:"
    echo "[Docker Entrypoint]   - /ssl/localhost.key (private key)"
    echo "[Docker Entrypoint]   - /ssl/localhost.crt (certificate)"
    echo "[Docker Entrypoint] 📅 Certificate expiration:"
    openssl x509 -in /ssl/localhost.crt -noout -dates | sed 's/^/[Docker Entrypoint]   /'
fi

echo "[Docker Entrypoint] 🚀 Starting Apache server..."
# Apacheの起動
exec apache2-foreground