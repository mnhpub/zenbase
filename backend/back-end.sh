# Start backend
echo "Starting backend"
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
