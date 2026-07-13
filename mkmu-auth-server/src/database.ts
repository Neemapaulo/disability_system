import { createClient } from "@supabase/supabase-js";

// We use Supabase purely as a Postgres host
// BetterAuth writes directly to the database via the connection string
// Supabase client is used for profile queries and storage

export const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!, // Service role for admin ops
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);