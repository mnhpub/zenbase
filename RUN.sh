#!/bin/bash

echo "🚀 Starting Zenbase Application"
echo ""

# Kill any existing processes
echo "Cleaning up existing processes..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# Start backend
echo "Starting backend on port 3000..."
cd backend
node src/server.js > /tmp/backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"

# Wait for backend to start
sleep 3

# Test backend
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Backend is running"
    echo "   URL: https://localhost:3000"
else
    echo "❌ Backend failed to start"
    echo "   Check logs: tail -f /tmp/backend.log"
    exit 1
fi

# Start frontend
echo ""
echo "Starting frontend on port 8080..."
cd frontend
pnpm install
pnpm run dev > /tmp/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"

echo ""
echo "✅ Both services started!"
echo ""
echo "Backend:  https://localhost:3000"
echo "Frontend: https://localhost:8080"
echo ""
echo "To view logs:"
echo "  Backend:  tail -f /tmp/backend.log"
echo "  Frontend: tail -f /tmp/frontend.log"
echo ""
echo "To stop services:"
echo "  kill $BACKEND_PID $FRONTEND_PID"
