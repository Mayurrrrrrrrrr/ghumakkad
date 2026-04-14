#!/bin/bash
set -e

echo "=== Deploying Ghumakkad API ==="

cd /home/ubuntu/ghumakkad

# Pull latest
git pull origin main

# Install/update Dart dependencies
cd backend
dart pub get

# Compile to native binary
dart compile exe bin/server.dart -o ghumakkad_server
echo "Compiled successfully"

# Restart via PM2
pm2 restart ghumakkad-api || pm2 start pm2.config.js
pm2 save

echo "=== Deploy complete ==="
echo "Test: curl https://ghumakkad.yuktaa.com/api/v1/auth/send-otp -X POST -H 'Content-Type: application/json' -d '{\"phone\":\"9999999999\"}'"
