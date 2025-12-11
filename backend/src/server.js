import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';
import { tenantMiddleware } from './middleware/tenant.js';
import tenantRoutes from './routes/tenant.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security and performance middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(express.json());

// Health check endpoint (no tenant required)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Root endpoint - API info
app.get('/', (req, res) => {
  res.json({
    name: 'Zenbase API',
    version: '1.0.0',
    message: 'Multi-tenant enterprise platform',
    endpoints: {
      health: '/health',
      api: '/api?tenant=TENANT_SLUG',
      tenantInfo: '/api/tenant/info?tenant=TENANT_SLUG',
      dashboard: '/api/tenant/dashboard?tenant=TENANT_SLUG (requires auth)',
      admins: '/api/tenant/admins?tenant=TENANT_SLUG (requires auth)'
    },
    examples: {
      seattle: '/api/tenant/info?tenant=seattle',
      portland: '/api/tenant/info?tenant=portland',
      vancouver: '/api/tenant/info?tenant=vancouver'
    },
    note: 'Running in mock mode. Configure Supabase credentials in .env for production.'
  });
});

// Apply tenant middleware to all /api routes
app.use('/api', tenantMiddleware);

// Mount tenant routes
app.use('/api/tenant', tenantRoutes);

// Root endpoint with tenant info
app.get('/api', (req, res) => {
  res.json({
    message: 'Zenbase API',
    tenant: req.tenant.slug,
    version: '1.0.0'
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ... (existing middleware)

// Serve frontend static files
const frontendPath = path.join(__dirname, '../../frontend/dist');
app.use(express.static(frontendPath));

// API 404 handler (must be registered *before* the catch-all)
app.use('/api/*', (req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Examples/Root API handler override for browser navigation
// (If you want / to still serve API info when not accepting HTML, check Accept header)
// For now, we'll let specific API routes take precedence (already defined above)
// and let the catch-all handle the rest for SPA.

// SPA Catch-all handler
app.get('*', (req, res) => {
  res.sendFile(path.join(frontendPath, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Zenbase API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
