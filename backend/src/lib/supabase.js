import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('⚠️  Missing Supabase environment variables - using mock mode');
  console.warn('   Set SUPABASE_URL and SUPABASE_ANON_KEY in backend/.env');
}

export const supabase = supabaseUrl && supabaseAnonKey 
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null;

/**
 * Create tenant-scoped Supabase client with RLS context
 * Sets tenant_id in RLS context for row-level security
 */
export function createTenantClient(tenantId, accessToken = null) {
  if (!supabaseUrl || !supabaseAnonKey) {
    return null;
  }
  
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
