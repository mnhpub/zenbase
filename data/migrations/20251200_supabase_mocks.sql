-- Mock Supabase Auth Schema for CI/Testing
-- Migration ID: 20251200_supabase_mocks

-- Create auth schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS auth;

-- Create Supabase roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role;
  END IF;
END
$$;

-- Create auth.users table
CREATE TABLE IF NOT EXISTS auth.users (
  id UUID PRIMARY KEY,
  instance_id UUID,
  aud VARCHAR(255),
  role VARCHAR(255),
  email VARCHAR(255),
  encrypted_password VARCHAR(255),
  email_confirmed_at TIMESTAMP WITH TIME ZONE,
  invited_at TIMESTAMP WITH TIME ZONE,
  confirmation_token VARCHAR(255),
  recovery_token VARCHAR(255),
  email_change_token_new VARCHAR(255),
  email_change VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  phone VARCHAR(255),
  phone_confirmed_at TIMESTAMP WITH TIME ZONE,
  phone_change VARCHAR(255),
  phone_change_token VARCHAR(255),
  email_change_token_current VARCHAR(255),
  email_change_confirm_status SMALLINT,
  banned_until TIMESTAMP WITH TIME ZONE,
  reauthentication_token VARCHAR(255),
  is_sso_user BOOLEAN DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create auth.uid() function mock
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS UUID AS $$
BEGIN
  -- Return a nil UUID or a specific test UUID for testing
  RETURN '00000000-0000-0000-0000-000000000000'::UUID;
END;
$$ LANGUAGE plpgsql;

-- Create auth.role() function mock
CREATE OR REPLACE FUNCTION auth.role()
RETURNS TEXT AS $$
BEGIN
  RETURN 'authenticated';
END;
$$ LANGUAGE plpgsql;
