import { createTenantClient } from '../lib/supabase.js';

export class DashboardService {
    /**
     * Get dashboard data for a specific tenant
     * @param {string} tenantId 
     * @param {string} accessToken 
     * @returns {Promise<Array>}
     */
    static async getDashboardData(tenantId, accessToken) {
        const client = createTenantClient(tenantId, accessToken);
        if (!client) {
            throw new Error('Failed to initialize Supabase client');
        }

        const { data, error } = await client
            .from('dashboard_data')
            .select('*')
            .eq('tenant_id', tenantId);

        if (error) throw error;

        return data || [];
    }
}
