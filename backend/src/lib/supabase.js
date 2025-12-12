import { createClient } from '@supabase/supabase-js';

const getEnv = (key) => {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing environment variable: ${key}`);
  }
  return value;
};

const supabaseUrl = getEnv('SUPABASE_URL');
const supabaseAnonKey = getEnv('SUPABASE_ANON_KEY');

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

/**
 * Create tenant-scoped Supabase client with RLS context
 * Sets tenant_id in RLS context for row-level security
 */
export function createTenantClient(tenantId, accessToken = null) {

  const client = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : {},
    },
  });

  // Set RLS context for tenant isolation
  if (tenantId) {
    client.rpc('set_tenant_context', { tenant_id: tenantId });
  }

  return client;
}
