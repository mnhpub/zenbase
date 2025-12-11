#!/bin/bash
# Simple development startup script
# Starts both backend and frontend with proper error handling

set -e

echo "🚀 Starting Zenbase Development Environment"
echo ""

# Kill any existing processes
echo "Cleaning up existing processes..."
pkill -f "node src/server.js" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
sleep 2

# Start backend
echo "Starting backend on port 3000..."
cd /workspaces/workspaces/backend
node src/server.js > /tmp/zenbase-backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
for i in {1..30}; do
  if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Backend is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Backend failed to start"
    echo "Check logs: tail -f /tmp/zenbase-backend.log"
    exit 1
  fi
  sleep 1
done

# Start frontend
echo ""
echo "Starting frontend on port 5173..."
cd /workspaces/workspaces/frontend
npm run dev > /tmp/zenbase-frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"

# Wait for frontend to be ready
echo "Waiting for frontend to be ready..."
for i in {1..30}; do
  if curl -sf http://localhost:5173 > /dev/null 2>&1; then
    echo "✅ Frontend is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "⚠️  Frontend may not be ready yet"
    echo "Check logs: tail -f /tmp/zenbase-frontend.log"
  fi
  sleep 1
done

echo ""
echo "✅ Zenbase is running!"
echo ""
echo "Backend:  http://localhost:3000"
echo "Frontend: http://localhost:5173"
echo ""
echo "Logs:"
echo "  Backend:  tail -f /tmp/zenbase-backend.log"
echo "  Frontend: tail -f /tmp/zenbase-frontend.log"
echo ""
echo "To stop:"
echo "  kill $BACKEND_PID $FRONTEND_PID"
echo ""
echo "PIDs saved to /tmp/zenbase.pids"
echo "$BACKEND_PID $FRONTEND_PID" > /tmp/zenbase.pids
