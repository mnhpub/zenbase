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

        const apiUrl = import.meta.env.VITE_API_URL || '';
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

  // ... (existing imports and interfaces)

  function OnboardingBanner({ status, error }: { status?: string, error?: string }) {
    if (!status || status === 'success') return null;

    const statusColors = {
      pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
      enqueued: 'bg-blue-100 text-blue-800 border-blue-200',
      processing: 'bg-blue-100 text-blue-800 border-blue-200',
      failed: 'bg-red-100 text-red-800 border-red-200',
    };

    const statusText = {
      pending: 'Onboarding Pending',
      enqueued: 'Onboarding Queued',
      processing: 'Onboarding in Progress',
      failed: 'Onboarding Failed',
    };

    const colorClass = statusColors[status as keyof typeof statusColors] || statusColors.pending;
    const title = statusText[status as keyof typeof statusText] || 'Onboarding Status';

    return (
      <div className={`mb-6 p-4 rounded-md border ${colorClass}`}>
        <div className="flex justify-between items-start">
          <div>
            <h3 className="font-medium">{title}</h3>
            <p className="mt-1 text-sm opacity-90">
              {status === 'failed'
                ? error || 'An error occurred during onboarding. Please try again.'
                : 'Your tenant environment is being provisioned. Features may be limited.'}
            </p>
          </div>
          {status === 'failed' && (
            <button
              className="px-3 py-1 text-sm bg-white border border-red-300 rounded hover:bg-red-50 text-red-700"
              onClick={() => alert('Retry triggered (mock)')}
            >
              Retry
            </button>
          )}
        </div>
      </div>
    );
  }

  // ... (inside Dashboard component)

  return (
    <div className="dashboard">
      <header>
        <h1>{tenant?.name || 'Zenbase'} Dashboard</h1>
        <p className="region">Region: {tenant?.region}</p>
      </header>

      <OnboardingBanner status={tenant?.onboarding_status} error={tenant?.onboarding_error} />

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
