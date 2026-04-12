#!/bin/bash

# Configuration
PROJECT_ROOT=$(pwd)
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BACKEND_WEB_DIR="$PROJECT_ROOT/backend/web"

echo "🚀 Starting Ghumakkad Web Build Process..."

# 1. Clean and Build Florida Web
cd "$FRONTEND_DIR" || exit
echo "📦 Building Flutter Web..."
flutter clean
flutter build web --release --base-href /

# 2. Sync with Backend
echo "📂 Moving build files to backend/web..."
rm -rf "$BACKEND_WEB_DIR"
mkdir -p "$BACKEND_WEB_DIR"
cp -r build/web/* "$BACKEND_WEB_DIR"

# 3. Final steps
echo "✅ Build Complete!"
echo "📍 Files are now in: $BACKEND_WEB_DIR"
echo "👉 You can now run the Dart server: cd ../backend && dart bin/server.dart"
