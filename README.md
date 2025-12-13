# Zenbase

Multi-tenant enterprise application with wildcard subdomain routing.

## Architecture

- **Frontend**: React/TS/Vite
- **Backend**: Node.js/Express
- **Database**: PG/RLS

## Features

- Multi-tenant architecture with subdomain routing (*.tld)
- Row-Level Security (RLS) for tenant data isolation
- Regional dashboards with tenant-specific data
- Admin and counsel management per tenant

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

## CI/CD with Screwdriver.cd

Zenbase uses Screwdriver.cd for automated builds and deployments. See [SCREWDRIVER.md](./SCREWDRIVER.md) for detailed documentation.

### Production (Fly.io)

Subdomains automatically route to tenants:
- [https://seattle.zenbase.online](https://seattle.zenbase.online)
- [https://portland.zenbase.online](https://portland.zenbase.online)
- [http://localhost:5173?tenant=seattle](http://localhost:5173?tenant=seattle)
- [http://localhost:5173?tenant=portland](http://localhost:5173?tenant=portland)


### 2. Local Development

```
phase auth
make up
```

### 4. Set Secrets

Secrets are managed.

### 5. Maintain Wildcard Domain

```bash
# Wildcard certs for *.zenbase.online
fly certs add "*.zenbase.online"
fly certs add "zenbase.online"
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

This project utilizes devcontainer ephemeral environments, enabling rapid development and testing.

## License

MIT
