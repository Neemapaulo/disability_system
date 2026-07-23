import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../utils/supabase';
import { Lock, Mail, AlertCircle, ChevronRight, Eye, EyeOff } from 'lucide-react';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const currentEmail = email.toLowerCase().trim();

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email: currentEmail,
        password,
      });

      if (authError) {
        if (authError.message.includes("Database error querying schema")) {
            throw new Error("System Error: API Schema out of sync. Please run 'supabase/scripts/fresh_admin_refresh.sql' in your Supabase SQL Editor and REFRESH the page.");
        }
        throw authError;
      }

      // Profile verification: user must have admin or superuser role in profiles table.
      // No fallback to other tables. Database policy is the source of truth.
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', data.user?.id)
        .single();

      if (profile?.role !== 'admin' && profile?.role !== 'superuser') {
        await supabase.auth.signOut();
        throw new Error('Access denied. Admin privileges required.');
      }

      navigate('/dashboard');
    } catch (err: any) {
      console.error("Login error:", err);
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4 font-sans">
      <div className="max-w-md w-full bg-white rounded-[2.5rem] shadow-2xl p-12 border border-slate-100">
        <div className="text-center mb-12">
          <div className="w-24 h-24 mx-auto mb-6 rounded-3xl overflow-hidden shadow-2xl shadow-blue-200 border-4 border-white transform hover:scale-105 transition-transform">
            <img src="/logo.png" alt="MKMU Logo" className="w-full h-full object-cover" />
          </div>
          <h1 className="text-4xl font-black text-slate-900 tracking-tighter">MKMU Admin</h1>
          <p className="text-slate-400 mt-2 font-bold uppercase text-xs tracking-[0.2em]">Infrastructure Management</p>
        </div>

        {error && (
          <div role="alert" className="bg-red-50 border border-red-100 text-red-700 p-6 rounded-2xl mb-8 flex items-start gap-3 animate-in fade-in slide-in-from-top-2">
            <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0" aria-hidden="true" />
            <span className="text-sm font-bold leading-relaxed">{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-8">
          <div className="space-y-2">
            <label htmlFor="login-email" className="text-xs font-black text-slate-500 uppercase tracking-widest ml-2">Email Address</label>
            <div className="relative group">
              <Mail className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-blue-600 w-5 h-5 transition-colors" aria-hidden="true" />
              <input
                id="login-email" autoComplete="username"
                type="email" required value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-14 pr-6 py-5 bg-slate-50 border border-slate-200 rounded-[1.5rem] focus:ring-8 focus:ring-blue-500/5 focus:border-blue-600 outline-none transition-all font-black text-slate-700 placeholder:text-slate-300"
                placeholder="admin@mkmu.com"
              />
            </div>
          </div>

          <div className="space-y-2">
            <label htmlFor="login-password" className="text-xs font-black text-slate-500 uppercase tracking-widest ml-2">Secure Password</label>
            <div className="relative group">
              <Lock className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-blue-600 w-5 h-5 transition-colors" aria-hidden="true" />
              <input
                id="login-password" autoComplete="current-password"
                type={showPassword ? "text" : "password"}
                required value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-14 pr-14 py-5 bg-slate-50 border border-slate-200 rounded-[1.5rem] focus:ring-8 focus:ring-blue-500/5 focus:border-blue-600 outline-none transition-all font-black text-slate-700 placeholder:text-slate-300"
                placeholder="••••••••••••"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? 'Ficha nenosiri' : 'Onyesha nenosiri'}
                className="absolute right-5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded transition-colors"
              >
                {showPassword ? <EyeOff className="w-5 h-5" aria-hidden="true" /> : <Eye className="w-5 h-5" aria-hidden="true" />}
              </button>
            </div>
          </div>

          <button
            type="submit" disabled={loading}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-black py-6 rounded-[1.5rem] shadow-2xl shadow-blue-300 transition-all active:scale-[0.97] disabled:opacity-50 flex items-center justify-center gap-3 text-lg"
          >
            {loading ? (
              <div className="w-6 h-6 border-4 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>Sign Into Dashboard <ChevronRight className="w-6 h-6" /></>
            )}
          </button>
        </form>

        <div className="mt-16 pt-8 border-t border-slate-100 text-center">
            <p className="text-xs font-black text-slate-300 uppercase tracking-widest leading-loose">
              &copy; 2026 MKMU Dar es Salaam<br/>Safe Access For All
            </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
