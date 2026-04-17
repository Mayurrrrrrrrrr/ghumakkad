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
echo "Test backend health: curl https://ghumakkad.yuktaa.com/api/v1/trips/ -H 'Authorization: Bearer YOUR_TOKEN'"
echo "To test auth: use a real Firebase ID token from a test device or Firebase test phone number"
