# Zenbase

Multi-tenant enterprise application with wildcard subdomain routing.

## Docs

- Ona Agent guide: [AGENTS.md](AGENTS.md)
- Secrets configuration: [docs/secrets/README.md](docs/secrets/README.md)

## Architecture

- **Frontend**: React + TypeScript + Vite
- **Backend**: Node.js + Express
- **Database**: Supabase (PostgreSQL with RLS)
- **Auth**: Supabase Auth
- **Infrastructure**: Fly.io (production), Ona (staging & test), Docker Compose (development)

## Features

- Multi-tenant architecture with subdomain routing (*.tld)
- Row-Level Security (RLS) for tenant data isolation
- Regional dashboards with tenant-specific data
- Admin and counsel management per tenant
- Supabase authentication

## Development

```bash
# Install dependencies
make install

# Build the application
make build

# Start with docker-compose
make up

# View logs
make logs

# Run health checks
make health

# Stop services
make down
```

See `make help` for all available commands.

### Option 2: Local Development (npm)

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

### Option 3: Docker Compose

```bash
# Create .env file in root with Supabase credentials
echo "SUPABASE_URL=https://your-project.supabase.co" > .env
echo "SUPABASE_ANON_KEY=your-anon-key" >> .env

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## CI/CD with Screwdriver.cd

Zenbase uses Screwdriver.cd for automated builds and deployments. See [SCREWDRIVER.md](./SCREWDRIVER.md) for detailed documentation.

**Quick commands:**
```bash
# Deploy to development
make deploy-dev

# Deploy to staging
make deploy-staging

# Deploy to production
make deploy-prod
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
