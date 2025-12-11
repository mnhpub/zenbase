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

// Root endpoint - API info moved to /api/info
app.get('/api/info', (req, res) => {
  res.json({
    name: 'Zenbase API',
    version: '1.0.0',
    message: 'Multi-tenant enterprise platform',
    endpoints: {
      health: '/health',
      docs: '/api-docs',
      api: '/api/v1?tenant=TENANT_SLUG',
      tenantInfo: '/api/v1/tenant/info?tenant=TENANT_SLUG',
      dashboard: '/api/v1/tenant/dashboard?tenant=TENANT_SLUG (requires auth)',
      admins: '/api/v1/tenant/admins?tenant=TENANT_SLUG (requires auth)'
    },
    examples: {
      seattle: '/api/v1/tenant/info?tenant=seattle',
      portland: '/api/v1/tenant/info?tenant=portland',
      vancouver: '/api/v1/tenant/info?tenant=vancouver'
    },
    note: 'Running in mock mode. Configure Supabase credentials in .env for production.'
  });
});

// Apply tenant middleware to all /api/v1 routes
app.use('/api/v1', tenantMiddleware);

// Mount tenant routes
app.use('/api/v1/tenant', tenantRoutes);

// Swagger Documentation
import swaggerUi from 'swagger-ui-express';
import swaggerSpecs from './config/swagger.js';
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs));

// Root endpoint with tenant info (Versioned)
app.get('/api/v1', (req, res) => {
  res.json({
    message: 'Zenbase API',
    tenant: req.tenant.slug,
    version: '1.0.0'
  });
});

// Legacy/Root API info redirect or info
app.get('/api/info', (req, res) => {
  res.redirect('/api-docs');
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
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ... (existing middleware)

// Serve frontend static files
const frontendPath = path.join(__dirname, '../../frontend/dist');
app.use(express.static(frontendPath));

// API 404 handler (must be registered *before* the catch-all)
app.use('/api/v1/*', (req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Examples/Root API handler override for browser navigation
// (If you want / to still serve API info when not accepting HTML, check Accept header)
// For now, we'll let specific API routes take precedence (already defined above)
// and let the catch-all handle the rest for SPA.

// SPA Catch-all handler
app.get('*', (req, res) => {
  const indexPath = path.join(frontendPath, 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    if (req.accepts('html')) {
      // Even if HTML is accepted, if the frontend is missing, we return a JSON error
      // to clearly indicate the failure state in a machine-readable way (and per user request),
      // or effectively a "backend-only" mode.
      res.status(404).json({
        error: 'Not Found',
        message: 'Frontend static files not found. The server is running in API-only mode.',
        hint: 'Ensure frontend is built if you expect a UI. For API, see /api/info'
      });
    } else {
      res.status(404).json({ error: 'Not Found' });
    }
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Zenbase API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
