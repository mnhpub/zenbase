# Zenbase - Quick Start Guide for Ona Environment

## Start the Application

### Terminal 1 - Backend
```bash
cd /backend
node src/server.js
```

The backend will start on port 3000 in mock mode (no Supabase required for demo).

**Backend URL**: The Gitpod URL will be shown as `https://3000--...gitpod.dev`

### Terminal 2 - Frontend  
```bash
cd /frontend
npm run dev
```

The frontend will start on port 8080.

**Frontend URL**: Vite will display the URL as `https://8080--...gitpod.dev`

## Access the Application

### Backend API
Visit the backend URL (port 3000) in your browser to see available endpoints:
- Root: `https://3000--...gitpod.dev/` - API documentation
- Health: `https://3000--...gitpod.dev/health`
- Tenant Info: `https://3000--...gitpod.dev/api/tenant/info?tenant=seattle`

### Frontend App
Visit the frontend URL (port 8080) in your browser to access the UI.

## Test Multi-Tenancy

Add `?tenant=TENANT_NAME` to any API URL to simulate different tenants:
- `?tenant=seattle`
- `?tenant=portland`
- `?tenant=vancouver`

Example:
```
https://3000--...gitpod.dev/api/tenant/info?tenant=seattle
```

## API Endpoints

Test the backend directly:
```bash
# API documentation (lists all endpoints)
curl https://3000--YOUR-GITPOD-URL.gitpod.dev/

# Health check
curl https://3000--YOUR-GITPOD-URL.gitpod.dev/health

# Tenant info (requires ?tenant= parameter)
curl "https://3000--YOUR-GITPOD-URL.gitpod.dev/api/tenant/info?tenant=seattle"
```

## Notes

- The app runs in **mock mode** without Supabase credentials
- Mock data is returned for dashboard and admin endpoints
- To use real Supabase, update `.env` files in `backend/` and `frontend/` directories
- See `README.md` for full setup instructions including Supabase schema
