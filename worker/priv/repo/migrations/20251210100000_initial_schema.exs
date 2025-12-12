defmodule MyApp.Repo.Migrations.InitialSchema do
  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA IF NOT EXISTS extensions"
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" SCHEMA extensions"
    execute "GRANT USAGE ON SCHEMA extensions TO postgres"
    execute "GRANT USAGE ON SCHEMA extensions TO anon"
    execute "GRANT USAGE ON SCHEMA extensions TO authenticated"
    execute "GRANT USAGE ON SCHEMA extensions TO service_role"

    execute """
    CREATE TABLE IF NOT EXISTS tenants (
      id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
      slug TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      region TEXT NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    )
    """

    execute "ALTER TABLE tenants ENABLE ROW LEVEL SECURITY"

    execute """
    CREATE POLICY "Anyone can read tenants"
      ON tenants FOR SELECT
      USING (true)
    """

    execute """
    CREATE TABLE IF NOT EXISTS tenant_admins (
      id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
      tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
      role TEXT NOT NULL DEFAULT 'admin',
      elected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      term_ends_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      UNIQUE(tenant_id, user_id)
    )
    """

    execute "ALTER TABLE tenant_admins ENABLE ROW LEVEL SECURITY"

    execute """
    CREATE POLICY "Users can view admins of their tenant"
      ON tenant_admins FOR SELECT
      USING (
        tenant_id IN (
          SELECT tenant_id FROM tenant_admins 
          WHERE user_id = auth.uid()
        )
      )
    """

    execute """
    CREATE TABLE IF NOT EXISTS dashboard_data (
      id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
      tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
      metric TEXT NOT NULL,
      value NUMERIC NOT NULL,
      timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    )
    """

    execute "ALTER TABLE dashboard_data ENABLE ROW LEVEL SECURITY"

    execute """
    CREATE POLICY "Users can view their tenant data"
      ON dashboard_data FOR SELECT
      USING (
        tenant_id IN (
          SELECT tenant_id FROM tenant_admins 
          WHERE user_id = auth.uid()
        )
      )
    """

    execute """
    CREATE POLICY "Admins can insert data for their tenant"
      ON dashboard_data FOR INSERT
      WITH CHECK (
        tenant_id IN (
          SELECT tenant_id FROM tenant_admins 
          WHERE user_id = auth.uid()
        )
      )
    """

    execute """
    CREATE OR REPLACE FUNCTION set_tenant_context(tenant_id UUID)
    RETURNS void AS $$
    BEGIN
      PERFORM set_config('app.tenant_id', tenant_id::TEXT, false);
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER
    """

    execute """
    CREATE OR REPLACE FUNCTION get_current_tenant()
    RETURNS UUID AS $$
    BEGIN
      RETURN current_setting('app.tenant_id', true)::UUID;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql
    """

    execute "CREATE INDEX IF NOT EXISTS idx_dashboard_data_tenant_id ON dashboard_data(tenant_id)"
    execute "CREATE INDEX IF NOT EXISTS idx_tenant_admins_tenant_id ON tenant_admins(tenant_id)"
    execute "CREATE INDEX IF NOT EXISTS idx_tenant_admins_user_id ON tenant_admins(user_id)"
    execute "CREATE INDEX IF NOT EXISTS idx_tenants_slug ON tenants(slug)"

    execute """
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """

    execute """
    CREATE TRIGGER update_tenants_updated_at
      BEFORE UPDATE ON tenants
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column()
    """
    
    execute """
    INSERT INTO tenants (slug, name, region) VALUES
      ('seattle', 'Seattle Zenbase', 'Seattle, WA'),
      ('portland', 'Portland Zenbase', 'Portland, OR'),
      ('vancouver', 'Vancouver Zenbase', 'Vancouver, BC')
    ON CONFLICT (slug) DO NOTHING
    """
  end

  def down do
    execute "DROP TABLE IF EXISTS dashboard_data CASCADE"
    execute "DROP TABLE IF EXISTS tenant_admins CASCADE"
    execute "DROP TABLE IF EXISTS tenants CASCADE"
    execute "DROP FUNCTION IF EXISTS set_tenant_context(UUID)"
    execute "DROP FUNCTION IF EXISTS get_current_tenant()"
    execute "DROP FUNCTION IF EXISTS update_updated_at_column()"
  end
end
