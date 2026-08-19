#!/bin/bash
# Fargonam backend + nginx to'liq deploy
# Ishlatish: ./deploy_backend.sh <SERVER_IP_YOKI_DOMEN>

set -e

if [ -z "$1" ]; then
    echo "Xato: Server IP yoki domen ko'rsating"
    echo "Ishlatish: ./deploy_backend.sh <IP_YOKI_DOMEN>"
    exit 1
fi
SERVER_IP=$1

if [ -n "$SSHPASS" ]; then
    SSH="sshpass -e ssh -o StrictHostKeyChecking=no root@$SERVER_IP"
    SCP="sshpass -e scp -o StrictHostKeyChecking=no -r"
else
    SSH="ssh -o StrictHostKeyChecking=no root@$SERVER_IP"
    SCP="scp -o StrictHostKeyChecking=no -r"
fi

echo "========================================"
echo " Fargonam Backend Deploy — $SERVER_IP"
echo "========================================"

# ── 1. Backend kodi yuborish ─────────────────────────────────
echo ""
echo "==> [1/5] Backend kodi yuklanmoqda..."
$SSH "mkdir -p /opt/fargonam/backend"
$SCP backend/app root@$SERVER_IP:/opt/fargonam/backend/
$SCP backend/alembic root@$SERVER_IP:/opt/fargonam/backend/
$SCP backend/alembic.ini root@$SERVER_IP:/opt/fargonam/backend/
$SCP backend/requirements.txt root@$SERVER_IP:/opt/fargonam/backend/
$SCP backend/.env root@$SERVER_IP:/opt/fargonam/backend/
$SCP backend/docker-entrypoint.sh root@$SERVER_IP:/opt/fargonam/backend/ 2>/dev/null || true

# ── 2. Admin web va Landing yuborish ─────────────────────────
echo "==> [2/5] Admin panel va Landing yuklanmoqda..."
$SSH "mkdir -p /var/www/fargonam/admin /var/www/fargonam/landing"
$SCP admin_web/index.html root@$SERVER_IP:/var/www/fargonam/admin/
$SCP landing/index.html root@$SERVER_IP:/var/www/fargonam/landing/
$SCP landing/static root@$SERVER_IP:/var/www/fargonam/landing/

# ── 3. VPS da setup ─────────────────────────────────────────
echo "==> [3/5] VPS da dependency va Docker..."
$SSH bash << 'REMOTE'
set -e
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
fi
if ! docker compose version &> /dev/null; then
    apt-get update && apt-get install -y docker-compose-plugin
fi
mkdir -p /opt/fargonam
REMOTE

$SCP docker-compose.yml root@$SERVER_IP:/opt/fargonam/

$SSH bash << 'REMOTE'
set -e
cd /opt/fargonam
docker compose up -d
cd backend
# Lokal .env DEBUG=true bilan ishlaydi (dev qulayligi uchun) — production'da
# bu /docs'ni ochib qo'yadi va ichki xatolarni foydalanuvchiga ko'rsatadi,
# shuning uchun serverdagi nusxada DEBUG har doim majburan false qilinadi.
if grep -q '^DEBUG=' .env; then
    sed -i 's/^DEBUG=.*/DEBUG=false/' .env
else
    echo 'DEBUG=false' >> .env
fi
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -r requirements.txt
sleep 5
.venv/bin/alembic upgrade head
REMOTE

# ── 4. Systemd service ──────────────────────────────────────
echo "==> [4/5] Systemd service sozlanmoqda..."
$SSH bash << 'REMOTE'
cat > /etc/systemd/system/fargonam-backend.service << 'SERVICE'
[Unit]
Description=Fargonam Backend API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/fargonam/backend
Environment=PYTHONPATH=/opt/fargonam/backend
EnvironmentFile=-/opt/fargonam/backend/.env
ExecStart=/opt/fargonam/backend/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 2
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable fargonam-backend
systemctl restart fargonam-backend
REMOTE

# ── 5. Nginx ────────────────────────────────────────────────
echo "==> [5/5] Nginx sozlanmoqda..."
$SSH bash << REMOTE
set -e
if ! command -v nginx &> /dev/null; then
    apt-get update && apt-get install -y nginx
fi
cat > /etc/nginx/sites-available/fargonam << 'NGINX'
server {
    listen 80;
    server_name $SERVER_IP;

    location = / {
        root /var/www/fargonam/landing;
        index index.html;
    }
    location /landing-static/ {
        alias /var/www/fargonam/landing/static/;
    }
    location /admin/ {
        alias /var/www/fargonam/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
    }
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/fargonam /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
REMOTE

echo "========================================"
echo " Deploy tugadi!"
echo " Landing: http://$SERVER_IP"
echo " API:     http://$SERVER_IP/health"
echo "========================================"
