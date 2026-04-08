#!/bin/bash
echo "============================================"
echo "  LUXE Fashion App - Platform Setup"
echo "============================================"
echo ""

echo "[1/3] Getting Flutter packages..."
flutter pub get || { echo "ERROR: flutter pub get failed."; exit 1; }

echo ""
echo "[2/3] Generating platform folders (android, web, windows)..."
flutter create --platforms=android,web,windows . || { echo "ERROR: flutter create failed."; exit 1; }

echo ""
echo "[3/3] Getting packages again after platform generation..."
flutter pub get

echo ""
echo "============================================"
echo "  Setup Complete! Run the app with:"
echo ""
echo "  Android phone:  flutter run -d android"
echo "  Web browser:    flutter run -d chrome"
echo "  Windows app:    flutter run -d windows"
echo "============================================"
