class SupabaseConstants {
  SupabaseConstants._();

  static const String url = 'https://tniemfscnbcbzbypliem.supabase.co';

  /// Publishable ("anon") key. Safe to ship inside the app — it is protected
  /// by the row level security policies in supabase/schema.sql, not by secrecy.
  /// Never put the secret / service_role key here.
  static const String anonKey = 'sb_publishable_HVz5jE8dB5rYm4AvD3PHMg_o8SmYLgO';
}
