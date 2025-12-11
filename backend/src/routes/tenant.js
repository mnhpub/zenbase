import express from 'express';
import { createTenantClient } from '../lib/supabase.js';
import { authMiddleware, optionalAuthMiddleware } from '../middleware/auth.js';

const router = express.Router();

/**
 * @swagger
 * /tenant/info:
 *   get:
 *     summary: Get tenant information
 *     tags: [Tenant]
 *     parameters:
 *       - in: query
 *         name: tenant
 *         schema:
 *           type: string
 *         required: false
 *         description: Tenant slug (e.g., seattle)
 *     responses:
 *       200:
 *         description: Tenant information
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 tenant:
 *                   type: object
 *                 user:
 *                   type: object
 */
router.get('/info', optionalAuthMiddleware, (req, res) => {
  res.json({
    tenant: req.tenant,
    user: req.user || null
  });
});

/**
 * @swagger
 * /tenant/dashboard:
 *   get:
 *     summary: Get dashboard data
 *     tags: [Tenant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard statistics
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 tenant:
 *                   type: object
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
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
 * @swagger
 * /tenant/admins:
 *   get:
 *     summary: Get tenant admins
 *     tags: [Tenant]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of admins
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 admins:
 *                   type: array
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
            email: 'admin@zenbase.online'
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
