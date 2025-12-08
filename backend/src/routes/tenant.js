import express from 'express';
import { createTenantClient } from '../lib/supabase.js';
import { authMiddleware, optionalAuthMiddleware } from '../middleware/auth.js';

const router = express.Router();

/**
 * GET /api/tenant/info
 * Returns current tenant information
 */
router.get('/info', optionalAuthMiddleware, (req, res) => {
  res.json({
    tenant: req.tenant,
    user: req.user || null
  });
});

/**
 * GET /api/tenant/dashboard
 * Returns dashboard data for current tenant
 */
router.get('/dashboard', authMiddleware, async (req, res) => {
  try {
    let data = [];
    
    if (createTenantClient(req.tenantId, req.accessToken)) {
      const client = createTenantClient(req.tenantId, req.accessToken);
      
      // Fetch tenant-specific dashboard data with RLS applied
      const result = await client
        .from('dashboard_data')
        .select('*')
        .eq('tenant_id', req.tenantId);

      if (result.error) {
        return res.status(500).json({ error: result.error.message });
      }
      data = result.data || [];
    } else {
      // Mock dashboard data for demo
      data = [
        {
          id: '1',
          metric: 'Active Ads',
          value: 42,
          timestamp: new Date().toISOString()
        },
        {
          id: '2',
          metric: 'Total Views',
          value: 1337,
          timestamp: new Date().toISOString()
        },
        {
          id: '3',
          metric: 'Community Members',
          value: 89,
          timestamp: new Date().toISOString()
        }
      ];
    }

    res.json({
      tenant: req.tenant,
      data
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

/**
 * GET /api/tenant/admins
 * Returns list of admins for current tenant
 */
router.get('/admins', authMiddleware, async (req, res) => {
  try {
    let data = [];
    
    if (createTenantClient(req.tenantId, req.accessToken)) {
      const client = createTenantClient(req.tenantId, req.accessToken);
      
      const result = await client
        .from('tenant_admins')
        .select('*, user:users(*)')
        .eq('tenant_id', req.tenantId);

      if (result.error) {
        return res.status(500).json({ error: result.error.message });
      }
      data = result.data || [];
    } else {
      // Mock admins data for demo
      data = [
        {
          id: '1',
          role: 'admin',
          elected_at: new Date().toISOString(),
          user: {
            email: 'admin@adfinder.online'
          }
        }
      ];
    }

    res.json({ admins: data });
  } catch (error) {
    console.error('Admins error:', error);
    res.status(500).json({ error: 'Failed to fetch admins' });
  }
});

export default router;
