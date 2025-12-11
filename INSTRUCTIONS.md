# How to Start Zenbase Application

## Current Status
✅ Backend is ALREADY RUNNING on port 3000 (PID: 12904)

## What You Need to Do

### Start the Frontend

**In your Ona/Gitpod workspace:**

1. Look for the **Terminal** panel (usually at the bottom of the screen)
2. Click the **"+"** button to open a new terminal
3. Run these commands:

```bash
cd /frontend
npm run dev
```

4. Wait for Vite to start (you'll see output like):
```
VITE v5.4.21  ready in 143 ms

➜  Local:   http://localhost:8080/
➜  Network: http://100.64.68.143:8080/
```

5. **DO NOT close this terminal** - keep it running

## Accessing the Application

Once the frontend starts, check your **Ports panel** (usually bottom of screen):

You should see:
- **Port 3000** - Backend API
- **Port 8080** - Frontend App

Click on the port numbers to get the public URLs, or look for the "Open in Browser" icon.

### URLs will look like:
- Backend: `https://3000-<workspace-id>.gitpod.dev`
- Frontend: `https://8080-<workspace-id>.gitpod.dev`

## Testing Multi-Tenancy

Add `?tenant=` to the frontend URL:
- `?tenant=seattle`
- `?tenant=portland`
- `?tenant=vancouver`

## If Something Goes Wrong

### Restart Everything:
```bash
# Kill all processes
pkill -f "node src/server"
pkill -f vite

# Start backend
cd /backend
node src/server.js &

# Start frontend (in a new terminal)
cd /frontend
npm run dev
```

### Check if services are running:
```bash
curl http://localhost:3000/health
curl http://localhost:8080/
```

## Why This Approach?

Background processes started via scripts keep timing out in the automated environment. Running `npm run dev` in an interactive terminal keeps the process alive and visible.
