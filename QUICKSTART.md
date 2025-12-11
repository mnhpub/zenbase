# Zenbase Quick Start

## Fastest Way to Run Zenbase

### Option 1: Docker Compose (Recommended)

```bash
# Start everything
make up

# View logs
make logs

# Check health
make health

# Stop everything
make down
```

### Option 2: Development Script

```bash
./start-dev.sh
```

This starts both backend and frontend with automatic health checks.

### Option 3: Manual (Two Terminals)

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
```

## Accessing the Application

- **Backend API**: http://localhost:3000
- **Frontend App**: http://localhost:5173

### Test Multi-Tenancy

Add `?tenant=` to the URL:
- http://localhost:5173/?tenant=seattle
- http://localhost:5173/?tenant=portland
- http://localhost:5173/?tenant=vancouver

## Common Issues

### Frontend Not Loading

**Symptom**: Backend works but frontend shows blank page

**Solutions**:

1. **Check if Vite is running:**
   ```bash
   curl http://localhost:5173
   ```

2. **Check browser console** for errors (F12 in most browsers)

3. **Restart frontend:**
   ```bash
   pkill -f vite
   cd frontend && npm run dev
   ```

4. **Clear browser cache** and hard reload (Ctrl+Shift+R or Cmd+Shift+R)

5. **Check Vite config** - ensure allowed hosts includes your domain:
   ```bash
   cat frontend/vite.config.ts
   ```

### Port Already in Use

```bash
# Find what's using the port
lsof -i :3000
lsof -i :5173

# Kill the process
kill -9 <PID>
```

### Docker Issues

```bash
# Rebuild containers
docker-compose build --no-cache

# Remove all containers and volumes
docker-compose down -v

# Start fresh
docker-compose up -d
```

## Environment Variables

Create `.env` files if you want to use real Supabase:

**backend/.env:**
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

**frontend/.env:**
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_URL=http://localhost:3000
```

**Note**: The app works in mock mode without Supabase for development.

## Next Steps

1. ✅ Get the app running
2. 📖 Read [README.md](./README.md) for full documentation
3. 🔧 Read [SCREWDRIVER.md](./SCREWDRIVER.md) for CI/CD setup
4. 🚀 Deploy to Fly.io when ready

## Need Help?

- Check logs: `make logs` or `tail -f /tmp/zenbase-*.log`
- Validate config: `make validate`
- Run health checks: `make health`
- See all commands: `make help`
