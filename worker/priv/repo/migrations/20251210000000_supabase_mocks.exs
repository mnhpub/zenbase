defmodule MyApp.Repo.Migrations.SupabaseMocks do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    # Only run this if we need to mock Supabase (e.g. not in an environment where it exists)
    # For now, we assume if auth schema is missing, we create it.
    execute "CREATE SCHEMA IF NOT EXISTS auth"

    execute """
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
    $$
    """

    execute """
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
    )
    """

    execute """
    CREATE OR REPLACE FUNCTION auth.uid()
    RETURNS UUID AS $$
    BEGIN
      RETURN '00000000-0000-0000-0000-000000000000'::UUID;
    END;
    $$ LANGUAGE plpgsql
    """

    execute """
    CREATE OR REPLACE FUNCTION auth.role()
    RETURNS TEXT AS $$
    BEGIN
      RETURN 'authenticated';
    END;
    $$ LANGUAGE plpgsql
    """
  end

  def down do
    # We might not want to drop auth schema in a real env, so be careful.
    # This is mostly for the CI mock environment.
    execute "DROP SCHEMA IF EXISTS auth CASCADE;"
  end
end
