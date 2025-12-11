#!/bin/bash
# Build script for Screwdriver.cd pipeline

set -e

echo "🔨 Building Zenbase Application"

# Build backend
echo "Building backend..."
cd backend
npm ci
cd ..

# Build frontend
echo "Building frontend..."
cd frontend
npm ci
npm run build
cd ..

echo "✅ Build complete"
