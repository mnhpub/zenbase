# Zenbase

Multi-tenant enterprise application with wildcard subdomain routing.

## Architecture

- **Frontend**: React + TypeScript + Vite
- **Backend**: Node.js + Express
- **Database**: Supabase (PostgreSQL with RLS)
- **Auth**: Supabase Auth
- **Deployment**: Fly.io (production), Docker Compose (development)

## Features

- Multi-tenant architecture with subdomain routing (*.zenbase.online)
- Row-Level Security (RLS) for tenant data isolation
- Regional dashboards with tenant-specific data
- Admin and counsel management per tenant
- Supabase authentication

## Prerequisites

- Node.js 20+
- npm
- Docker & Docker Compose (for containerized development)
- Supabase account
- Fly.io account (for production deployment)

## Setup

### 1. Supabase Configuration

Create a Supabase project and set up the following tables:

```sql
-- Tenants table
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  region TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Dashboard data table
CREATE TABLE dashboard_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  metric TEXT NOT NULL,
  value NUMERIC NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE dashboard_data ENABLE ROW LEVEL SECURITY;

-- RLS policies for dashboard_data
CREATE POLICY "Users can view their tenant data"
  ON dashboard_data FOR SELECT
  USING (tenant_id = current_setting('app.tenant_id')::UUID);

-- Tenant admins table
CREATE TABLE tenant_admins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin',
  elected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  term_ends_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(tenant_id, user_id)
);

ALTER TABLE tenant_admins ENABLE ROW LEVEL SECURITY;

-- Function to set tenant context for RLS
CREATE OR REPLACE FUNCTION set_tenant_context(tenant_id UUID)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.tenant_id', tenant_id::TEXT, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2. Environment Variables

**Backend** (`backend/.env`):
```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env`:
```
NODE_ENV=development
PORT=3000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CORS_ORIGIN=http://localhost:5173
```

**Frontend** (`frontend/.env`):
```bash
cp frontend/.env.example frontend/.env
```

Edit `frontend/.env`:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_URL=http://localhost:3000
```

### 3. Install Dependencies

```bash
# Backend
cd backend
npm install

# Frontend
cd ../frontend
npm install
```

## Development

### Option 1: Local Development (npm)

Run backend and frontend separately:

```bash
# Terminal 1 - Backend
cd backend
npm run dev

# Terminal 2 - Frontend
cd frontend
npm run dev
```

Access the app at [http://localhost:5173](http://localhost:5173)

### Option 2: Docker Compose

```bash
# Create .env file in root with Supabase credentials
echo "SUPABASE_URL=https://your-project.supabase.co" > .env
echo "SUPABASE_ANON_KEY=your-anon-key" >> .env

# Start services
docker-compose up
```

## Testing Multi-Tenancy

### Local Development

Use query parameters to simulate different tenants:
- [http://localhost:5173?tenant=seattle](http://localhost:5173?tenant=seattle)
- [http://localhost:5173?tenant=portland](http://localhost:5173?tenant=portland)

### Production (Fly.io)

Subdomains automatically route to tenants:
- [https://seattle.zenbase.online](https://seattle.zenbase.online)
- [https://portland.zenbase.online](https://portland.zenbase.online)

## Deployment to Fly.io

### 1. Install Fly CLI

```bash
curl -L https://fly.io/install.sh | sh
```

### 2. Login to Fly.io

```bash
fly auth login
```

### 3. Create Fly App

```bash
fly apps create zenbase
```

### 4. Set Secrets

```bash
fly secrets set SUPABASE_URL=https://your-project.supabase.co
fly secrets set SUPABASE_ANON_KEY=your-anon-key
```

### 5. Configure Wildcard Domain

```bash
# Add wildcard certificate for *.zenbase.online
fly certs add "*.zenbase.online"
fly certs add "zenbase.online"
```

Configure DNS:
- Add A record: `@` → Fly.io IP
- Add A record: `*` → Fly.io IP

### 6. Deploy

```bash
fly deploy
```

## Project Structure

```
.
├── backend/
│   ├── src/
│   │   ├── lib/
│   │   │   └── supabase.js          # Supabase client with RLS
│   │   ├── middleware/
│   │   │   ├── auth.js              # Authentication middleware
│   │   │   └── tenant.js            # Tenant context extraction
│   │   ├── routes/
│   │   │   └── tenant.js            # Tenant API routes
│   │   └── server.js                # Express server
│   ├── package.json
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── hooks/
│   │   │   └── useTenant.ts         # Tenant context hook
│   │   ├── lib/
│   │   │   └── supabase.ts          # Supabase client
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx        # Tenant dashboard
│   │   │   └── Login.tsx            # Authentication
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   └── .env.example
├── docker-compose.yml
├── Dockerfile
├── fly.toml
└── README.md
```

## API Endpoints

### Public
- `GET /health` - Health check

### Tenant-Scoped (requires subdomain or ?tenant=slug)
- `GET /api/tenant/info` - Get tenant information
- `GET /api/tenant/dashboard` - Get dashboard data (requires auth)
- `GET /api/tenant/admins` - Get tenant admins (requires auth)

## Tenant Isolation

Tenant isolation is enforced at multiple levels:

1. **Subdomain Routing**: Middleware extracts tenant from subdomain
2. **Database RLS**: PostgreSQL Row-Level Security policies
3. **API Layer**: Tenant context validated on every request
4. **Client Context**: Frontend hooks manage tenant state

## Contributing

This project is built on Ona (Gitpod) ephemeral environments, enabling rapid development and testing.

## License

MIT
