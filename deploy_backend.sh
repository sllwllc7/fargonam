#!/bin/bash
# Fargonam backend + nginx to'liq deploy
# Ishlatish: ./deploy_backend.sh 45.92.173.42

set -e
SERVER_IP=${1:-45.92.173.42}
SSH="ssh -o StrictHostKeyChecking=no root@$SERVER_IP"
SCP="scp -o StrictHostKeyChecking=no -r"

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
$SCP backend/docker-entrypoint.sh root@$SERVER_IP:/opt/fargonam/backend/ 2>/dev/null || true

# ── 2. Admin web yuborish ────────────────────────────────────
echo "==> [2/5] Admin panel yuklanmoqda..."
$SSH "mkdir -p /var/www/fargonam/admin"
$SCP admin_web/index.html root@$SERVER_IP:/var/www/fargonam/admin/

# ── 3. VPS da setup ─────────────────────────────────────────
echo "==> [3/5] VPS da dependency va migratsiyalar..."
$SSH bash << 'REMOTE'
set -e
cd /opt/fargonam/backend

# Python virtual environment
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -r requirements.txt

# Alembic migratsiyalar
.venv/bin/alembic upgrade head
echo "✓ Migratsiyalar tayyor"
REMOTE

# ── 4. Systemd service — avtomatik qayta ishga tushirish ─────
echo "==> [4/5] Systemd service sozlanmoqda (auto-restart)..."
$SSH bash << 'REMOTE'
cat > /etc/systemd/system/fargonam-backend.service << 'SERVICE'
[Unit]
Description=Fargonam Backend API
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/fargonam/backend
Environment=PYTHONPATH=/opt/fargonam/backend
EnvironmentFile=-/opt/fargonam/backend/.env
ExecStart=/opt/fargonam/backend/.venv/bin/uvicorn app.main:app \
    --host 127.0.0.1 \
    --port 8000 \
    --workers 2 \
    --log-level info
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable fargonam-backend
systemctl restart fargonam-backend
sleep 3

if systemctl is-active --quiet fargonam-backend; then
    echo "✓ Backend ishga tushdi"
else
    echo "✗ Backend ishlamadi! Log:"
    journalctl -u fargonam-backend -n 30 --no-pager
    exit 1
fi
REMOTE

# ── 5. Nginx to'g'ri sozlash ─────────────────────────────────
echo "==> [5/5] Nginx sozlanmoqda..."
$SSH bash << 'REMOTE'
# Mavjud nginx.conf ni backup qilish
cp /etc/nginx/sites-available/fargonam /etc/nginx/sites-available/fargonam.bak 2>/dev/null || true

cat > /etc/nginx/sites-available/fargonam << 'NGINX'
server {
    listen 80;
    server_name fargonam.duckdns.org;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name fargonam.duckdns.org;

    # SSL — certbot tomonidan boshqariladi
    ssl_certificate /etc/letsencrypt/live/fargonam.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fargonam.duckdns.org/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Landing page — faqat asosiy sahifa
    location = / {
        root /var/www/fargonam/landing;
        index index.html;
    }
    location /landing-static/ {
        alias /var/www/fargonam/landing/static/;
    }

    # Admin panel
    location /admin/ {
        alias /var/www/fargonam/admin/;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
    }

    # Barcha qolgan so'rovlar → FastAPI backend
    # (WebSocket, API, static uploads)
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        # WebSocket uchun zarur
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 20M;
        proxy_read_timeout 300s;
        proxy_connect_timeout 10s;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/fargonam /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx
echo "✓ Nginx yangilandi"
REMOTE

# ── Natija tekshirish ────────────────────────────────────────
echo ""
echo "==> Tekshirish..."
sleep 2

STATUS=$(curl -s --max-time 10 https://fargonam.duckdns.org/ -o /dev/null -w "%{http_code}" 2>/dev/null)
API_STATUS=$(curl -s --max-time 10 https://fargonam.duckdns.org/health -o /dev/null -w "%{http_code}" 2>/dev/null)

echo ""
echo "========================================"
echo " Natija:"
echo "   Landing: https://fargonam.duckdns.org  → $STATUS"
echo "   API:     https://fargonam.duckdns.org/health → $API_STATUS"
echo "   Admin:   https://fargonam.duckdns.org/admin/"
echo "========================================"

if [ "$API_STATUS" = "200" ]; then
    echo " ✓ Hamma narsa ishlayapti!"
else
    echo " ✗ API javob bermayapti. Loglarni tekshiring:"
    echo "   ssh root@$SERVER_IP 'journalctl -u fargonam-backend -n 50'"
fi
