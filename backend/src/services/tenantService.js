import { createTenantClient } from '../lib/supabase.js';

export class TenantService {
    /**
     * Get admins for a specific tenant
     * @param {string} tenantId 
     * @param {string} accessToken 
     * @returns {Promise<Array>}
     */
    static async getTenantAdmins(tenantId, accessToken) {
        const client = createTenantClient(tenantId, accessToken);
        if (!client) {
            throw new Error('Failed to initialize Supabase client');
        }

        const { data, error } = await client
            .from('tenant_admins')
            .select('*, user:users(*)')
            .eq('tenant_id', tenantId);

        if (error) throw error;

        return data || [];
    }
}
