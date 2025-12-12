import express from 'express';
import { DashboardService } from '../services/dashboardService.js';
import { TenantService } from '../services/tenantService.js';
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
    const data = await DashboardService.getDashboardData(req.tenantId, req.accessToken);

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
    const data = await TenantService.getTenantAdmins(req.tenantId, req.accessToken);
    res.json({ admins: data });
  } catch (error) {
    console.error('Admins error:', error);
    res.status(500).json({ error: 'Failed to fetch admins' });
  }
});

export default router;
