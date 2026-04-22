#!/bin/bash
# Fargonam landing page + Nginx server deploy qilish
# Ishlatish: ./deploy_landing.sh <server_ip>
# Masalan:   ./deploy_landing.sh 192.168.1.100

SERVER_IP=$1

if [ -z "$SERVER_IP" ]; then
  echo "Xato: server IP kerak!"
  echo "Ishlatish: ./deploy_landing.sh <server_ip>"
  exit 1
fi

echo "==> Landing page fayllarini serverga yuborish..."
ssh root@$SERVER_IP "mkdir -p /var/www/fargonam/landing/static"

scp -r landing/index.html root@$SERVER_IP:/var/www/fargonam/landing/
scp -r landing/static/ root@$SERVER_IP:/var/www/fargonam/landing/

echo "==> Admin panel fayllarini yuborish..."
scp -r admin_web/index.html root@$SERVER_IP:/var/www/fargonam/admin/

echo "==> Nginx o'rnatish va sozlash..."
ssh root@$SERVER_IP bash << 'EOF'
  apt install -y nginx certbot python3-certbot-nginx

  cp /dev/stdin /etc/nginx/sites-available/fargonam << 'NGINX'
server {
    listen 80;
    server_name fargonam.duckdns.org;

    location / {
        root /var/www/fargonam/landing;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 20M;
    }

    location /static/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
    }

    location /admin/ {
        root /var/www/fargonam;
        index index.html;
        try_files $uri $uri/ /admin/index.html;
    }
}
NGINX

  ln -sf /etc/nginx/sites-available/fargonam /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
  nginx -t && systemctl restart nginx

  echo "==> SSL sertifikat olish (Let's Encrypt)..."
  certbot --nginx -d fargonam.duckdns.org --non-interactive --agree-tos -m admin@fargonam.uz || \
    certbot --nginx -d fargonam.duckdns.org --non-interactive --agree-tos -m test@gmail.com

  echo "==> DONE! https://fargonam.duckdns.org ochib ko'ring"
EOF
