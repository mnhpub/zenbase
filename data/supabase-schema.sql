-- Zenbase Database Schema
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tenants table
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  region TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on tenants
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read tenants (needed for subdomain routing)
CREATE POLICY "Anyone can read tenants"
  ON tenants FOR SELECT
  USING (true);

-- Dashboard data table
CREATE TABLE IF NOT EXISTS dashboard_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  metric TEXT NOT NULL,
  value NUMERIC NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on dashboard_data
ALTER TABLE dashboard_data ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view data for their tenant
CREATE POLICY "Users can view their tenant data"
  ON dashboard_data FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM tenant_admins 
      WHERE user_id = auth.uid()
    )
  );

-- Policy: Admins can insert data for their tenant
CREATE POLICY "Admins can insert data for their tenant"
  ON dashboard_data FOR INSERT
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM tenant_admins 
      WHERE user_id = auth.uid()
    )
  );

-- Tenant admins table
CREATE TABLE IF NOT EXISTS tenant_admins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin',
  elected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  term_ends_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tenant_id, user_id)
);

-- Enable RLS on tenant_admins
ALTER TABLE tenant_admins ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view admins of their tenant
CREATE POLICY "Users can view admins of their tenant"
  ON tenant_admins FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM tenant_admins 
      WHERE user_id = auth.uid()
    )
  );

-- Function to set tenant context for RLS
CREATE OR REPLACE FUNCTION set_tenant_context(tenant_id UUID)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.tenant_id', tenant_id::TEXT, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current tenant from context
CREATE OR REPLACE FUNCTION get_current_tenant()
RETURNS UUID AS $$
BEGIN
  RETURN current_setting('app.tenant_id', true)::UUID;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Seed data: Create sample tenants
INSERT INTO tenants (slug, name, region) VALUES
  ('seattle', 'Seattle Zenbase', 'Seattle, WA'),
  ('portland', 'Portland Zenbase', 'Portland, OR'),
  ('vancouver', 'Vancouver Zenbase', 'Vancouver, BC')
ON CONFLICT (slug) DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_dashboard_data_tenant_id ON dashboard_data(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_admins_tenant_id ON tenant_admins(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_admins_user_id ON tenant_admins(user_id);
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON tenants(slug);

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at trigger to tenants
CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
