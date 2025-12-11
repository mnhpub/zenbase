# Troubleshooting Guide

## Frontend Not Loading

### Symptoms
- Backend works (http://localhost:3000/health returns OK)
- Frontend URL shows blank page or "Cannot connect"
- Browser console shows errors

### Diagnosis

**1. Check if frontend is running:**
```bash
curl http://localhost:5173
```

**2. Check processes:**
```bash
ps aux | grep vite
ps aux | grep "node src/server"
```

**3. Check ports:**
```bash
netstat -tuln | grep -E ":(3000|5173)"
```

### Solutions

**Solution 1: Use Docker Compose (Recommended)**
```bash
# Stop any running processes
pkill -f vite
pkill -f "node src/server"

# Start with docker-compose
make up

# Check logs
make logs

# Verify health
make health
```

**Solution 2: Use Startup Script**
```bash
./start-dev.sh
```

**Solution 3: Manual Restart**
```bash
# Terminal 1 - Backend
cd backend
npm run dev

# Terminal 2 - Frontend  
cd frontend
npm run dev
```

**Solution 4: Check Vite Configuration**

The frontend might not be accessible due to allowed hosts. Check `frontend/vite.config.ts`:

```typescript
server: {
  host: '0.0.0.0',
  port: 5173,
  allowedHosts: [
    '.gitpod.dev',
    '.gitpod.io',
    'localhost',
  ],
}
```

**Solution 5: Browser Issues**
- Clear browser cache (Ctrl+Shift+Delete)
- Hard reload (Ctrl+Shift+R or Cmd+Shift+R)
- Try incognito/private mode
- Check browser console (F12) for errors

## Port Conflicts

### Symptoms
- Error: "Port 3000 is already in use"
- Error: "EADDRINUSE"

### Solutions

**Find what's using the port:**
```bash
lsof -i :3000
lsof -i :5173
```

**Kill the process:**
```bash
kill -9 <PID>
```

**Or kill all node processes:**
```bash
pkill -9 node
```

## Docker Compose Issues

### Services Won't Start

**Check configuration:**
```bash
docker-compose config
```

**View logs:**
```bash
docker-compose logs
docker-compose logs backend
docker-compose logs frontend
```

**Rebuild containers:**
```bash
docker-compose build --no-cache
docker-compose up -d
```

### Health Checks Failing

**Check service status:**
```bash
docker-compose ps
```

**Check health:**
```bash
curl http://localhost:3000/health
curl http://localhost:5173
```

**View detailed logs:**
```bash
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Volume Issues

**Remove volumes and restart:**
```bash
docker-compose down -v
docker-compose up -d
```

## Build Errors

### Backend Build Fails

**Check dependencies:**
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

**Check for syntax errors:**
```bash
cd backend
node --check src/server.js
```

### Frontend Build Fails

**Check dependencies:**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

**Check TypeScript:**
```bash
cd frontend
npm run build
```

## Environment Variables

### Missing Variables

**Symptoms:**
- "Missing Supabase environment variables"
- Services start but don't work properly

**Solution:**

Create `.env` files:

**backend/.env:**
```bash
NODE_ENV=development
PORT=3000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CORS_ORIGIN=http://localhost:5173
```

**frontend/.env:**
```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_URL=http://localhost:3000
```

**Note:** The app works in mock mode without Supabase for development.

## Gitpod/Ona Specific Issues

### Ports Not Showing in Panel

**Make ports public:**
1. Open Ports panel (bottom of screen)
2. Right-click on port
3. Select "Make Public"

### Service Unavailable (502)

**Symptoms:**
- Services work on localhost
- External URLs show 502 error

**Solutions:**

1. **Check if services are listening on 0.0.0.0:**
   ```bash
   netstat -tuln | grep -E ":(3000|5173)"
   ```
   Should show `0.0.0.0:3000` not `127.0.0.1:3000`

2. **Restart services:**
   ```bash
   ./start-dev.sh
   ```

3. **Use docker-compose:**
   ```bash
   make up
   ```

### Frontend Shows "Host Not Allowed"

**Update Vite config** to allow Gitpod hosts:

```typescript
// frontend/vite.config.ts
server: {
  allowedHosts: [
    '.gitpod.dev',
    '.gitpod.io',
    'localhost',
  ],
}
```

## Database Issues

### Can't Connect to Supabase

**Check credentials:**
```bash
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY
```

**Test connection:**
```bash
curl -H "apikey: $SUPABASE_ANON_KEY" "$SUPABASE_URL/rest/v1/"
```

**Use mock mode:**
The app works without Supabase in development. Just ignore the warning.

## Performance Issues

### Slow Startup

**Use docker-compose:**
```bash
make up
```

**Or build once:**
```bash
make build
```

### High Memory Usage

**Limit Docker resources:**
Edit Docker Desktop settings to limit memory.

**Or use production build:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
```

## Common Commands

### Check Everything
```bash
# Validate configuration
make validate

# Check health
make health

# View logs
make logs
```

### Clean Start
```bash
# Stop everything
make down

# Clean up
make clean

# Install fresh
make install

# Build
make build

# Start
make up
```

### Debug Mode
```bash
# Backend with debug logs
cd backend
DEBUG=* npm run dev

# Frontend with verbose output
cd frontend
npm run dev -- --debug
```

## Still Having Issues?

1. **Check logs:**
   ```bash
   tail -f /tmp/zenbase-backend.log
   tail -f /tmp/zenbase-frontend.log
   ```

2. **Verify installation:**
   ```bash
   node --version  # Should be 20+
   npm --version
   docker --version
   docker-compose --version
   ```

3. **Try clean install:**
   ```bash
   make clean
   make install
   make build
   make up
   ```

4. **Check documentation:**
   - [README.md](./README.md) - Full documentation
   - [QUICKSTART.md](./QUICKSTART.md) - Quick start guide
   - [SCREWDRIVER.md](./SCREWDRIVER.md) - CI/CD setup

5. **Review configuration:**
   - `backend/.env.example`
   - `frontend/.env.example`
   - `docker-compose.yml`
   - `screwdriver.yaml`
