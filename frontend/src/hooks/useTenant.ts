import { useState, useEffect } from 'react';

interface Tenant {
  id: string;
  slug: string;
  name: string;
  region: string;
  onboarding_status?: 'pending' | 'enqueued' | 'processing' | 'success' | 'failed';
  onboarding_error?: string;
}

interface TenantInfo {
  tenant: Tenant | null;
  user: any | null;
  loading: boolean;
  error: string | null;
}

/**
 * Hook to fetch and manage tenant context
 * Extracts tenant from subdomain and fetches tenant info from API
 */
export function useTenant(): TenantInfo {
  const [tenant, setTenant] = useState<Tenant | null>(null);
  const [user, setUser] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchTenantInfo() {
      try {
        const apiUrl = import.meta.env.VITE_API_URL || '';
        const response = await fetch(`${apiUrl}/api/tenant/info`, {
          credentials: 'include',
          headers: {
            'Content-Type': 'application/json',
          },
        });

        if (!response.ok) {
          throw new Error(`Failed to fetch tenant info: ${response.statusText}`);
        }

        const data = await response.json();
        setTenant(data.tenant);
        setUser(data.user);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    }

    fetchTenantInfo();
  }, []);

  return { tenant, user, loading, error };
}
