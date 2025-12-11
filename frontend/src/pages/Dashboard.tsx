import { useState, useEffect } from 'react';
import { useTenant } from '../hooks/useTenant';
import { supabase } from '../lib/supabase';

interface DashboardData {
  id: string;
  metric: string;
  value: number;
  timestamp: string;
}

export function Dashboard() {
  const { tenant, user, loading: tenantLoading } = useTenant();
  const [dashboardData, setDashboardData] = useState<DashboardData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchDashboard() {
      if (!tenant || !user) return;

      try {
        const { data: { session } } = await supabase.auth.getSession();
        
        if (!session) {
          setError('Not authenticated');
          return;
        }

        const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000';
        const response = await fetch(`${apiUrl}/api/tenant/dashboard`, {
          headers: {
            'Authorization': `Bearer ${session.access_token}`,
            'Content-Type': 'application/json',
          },
        });

        if (!response.ok) {
          throw new Error('Failed to fetch dashboard data');
        }

        const result = await response.json();
        setDashboardData(result.data || []);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    }

    if (!tenantLoading) {
      fetchDashboard();
    }
  }, [tenant, user, tenantLoading]);

  if (tenantLoading || loading) {
    return (
      <div className="loading">
        <h2>Loading dashboard...</h2>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error">
        <h2>Error</h2>
        <p>{error}</p>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <header>
        <h1>{tenant?.name || 'Zenbase'} Dashboard</h1>
        <p className="region">Region: {tenant?.region}</p>
      </header>

      <div className="user-info">
        <p>Welcome, {user?.email}</p>
      </div>

      <div className="metrics">
        <h2>Regional Metrics</h2>
        {dashboardData.length === 0 ? (
          <p>No data available yet.</p>
        ) : (
          <div className="metrics-grid">
            {dashboardData.map((item) => (
              <div key={item.id} className="metric-card">
                <h3>{item.metric}</h3>
                <p className="value">{item.value}</p>
                <p className="timestamp">{new Date(item.timestamp).toLocaleDateString()}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
