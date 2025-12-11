import { supabase } from '../lib/supabase.js';

/**
 * Extract tenant subdomain from request
 * Supports *.zenbase.online wildcard routing
 */
export function extractTenantFromHost(host) {
  if (!host) return null;

  // Remove port if present
  const hostname = host.split(':')[0];

  // Extract subdomain from *.zenbase.online
  const parts = hostname.split('.');

  // If hostname is subdomain.zenbase.online, extract subdomain
  if (parts.length >= 3 && parts[parts.length - 2] === 'zenbase' && parts[parts.length - 1] === 'online') {
    return parts.slice(0, -2).join('.');
  }

  // For local development (e.g., tenant.localhost)
  if (parts.length >= 2 && parts[parts.length - 1] === 'localhost') {
    return parts[0];
  }

  return null;
}

/**
 * Middleware to extract and validate tenant context
 * Sets req.tenant with tenant information
 */
export async function tenantMiddleware(req, res, next) {
  try {
    // Extract tenant from subdomain or query parameter (fallback for dev)
    const tenantSlug = extractTenantFromHost(req.headers.host) || req.query.tenant;

    if (!tenantSlug) {
      return res.status(400).json({
        error: 'No tenant specified',
        message: 'Access via subdomain (e.g., seattle.zenbase.online) or ?tenant=slug'
      });
    }

    // Fetch tenant from database or use mock data
    let tenant;

    if (supabase) {
      const { data, error } = await supabase
        .from('tenants')
        .select('*')
        .eq('slug', tenantSlug)
        .single();

      if (error || !data) {
        return res.status(404).json({
          error: 'Tenant not found',
          tenant: tenantSlug
        });
      }
      tenant = data;
    } else {
      // Mock tenant data for demo
      tenant = {
        id: `mock-${tenantSlug}`,
        slug: tenantSlug,
        name: `${tenantSlug.charAt(0).toUpperCase() + tenantSlug.slice(1)} Zenbase`,
        region: `${tenantSlug.charAt(0).toUpperCase() + tenantSlug.slice(1)} Region`,
        onboarding_status: 'pending', // pending, processing, success, failed
        onboarding_error: null,
        created_at: new Date().toISOString()
      };
    }

    // Attach tenant to request
    req.tenant = tenant;
    req.tenantId = tenant.id;

    next();
  } catch (error) {
    console.error('Tenant middleware error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}
