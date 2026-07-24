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
            throw new Error("Hitilafu ya Mfumo: API Schema haiendani. Tafadhali endesha 'supabase/scripts/fresh_admin_refresh.sql' kwenye Supabase SQL Editor kisha upakie upya ukurasa.");
        }
        if (authError.message.includes("Invalid login credentials")) {
            throw new Error("Barua pepe au nenosiri si sahihi");
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
        throw new Error('Ruhusa imekataliwa. Unahitaji kuwa msimamizi.');
      }

      navigate('/dashboard');
    } catch (err: any) {
      console.error("Login error:", err);
      setError(err.message || 'Kuingia kumeshindikana');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4 font-sans">
      <div className="max-w-sm w-full bg-white rounded-3xl shadow-xl p-8 border border-slate-100">
        <div className="text-center mb-8">
          <div className="w-16 h-16 mx-auto mb-4 rounded-2xl overflow-hidden shadow-lg shadow-blue-200 border-4 border-white">
            <img src="/logo.png" alt="Nembo ya MKMU" className="w-full h-full object-cover" />
          </div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">MKMU Admin</h1>
          <p className="text-slate-400 mt-1 font-bold uppercase text-[0.65rem] tracking-[0.2em]">Usimamizi wa Miundombinu</p>
        </div>

        {error && (
          <div role="alert" className="bg-red-50 border border-red-100 text-red-700 p-4 rounded-xl mb-6 flex items-start gap-2.5 animate-in fade-in slide-in-from-top-2">
            <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0" aria-hidden="true" />
            <span className="text-sm font-bold leading-relaxed">{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-5">
          <div className="space-y-1.5">
            <label htmlFor="login-email" className="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Barua Pepe</label>
            <div className="relative group">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-blue-600 w-5 h-5 transition-colors" aria-hidden="true" />
              <input
                id="login-email" autoComplete="username"
                type="email" required value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-12 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-4 focus:ring-blue-500/10 focus:border-blue-600 outline-none transition-all font-bold text-slate-700 placeholder:text-slate-300"
                placeholder="admin@mkmu.com"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label htmlFor="login-password" className="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Nenosiri</label>
            <div className="relative group">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-blue-600 w-5 h-5 transition-colors" aria-hidden="true" />
              <input
                id="login-password" autoComplete="current-password"
                type={showPassword ? "text" : "password"}
                required value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-12 pr-12 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-4 focus:ring-blue-500/10 focus:border-blue-600 outline-none transition-all font-bold text-slate-700 placeholder:text-slate-300"
                placeholder="••••••••••••"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? 'Ficha nenosiri' : 'Onyesha nenosiri'}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded transition-colors"
              >
                {showPassword ? <EyeOff className="w-5 h-5" aria-hidden="true" /> : <Eye className="w-5 h-5" aria-hidden="true" />}
              </button>
            </div>
          </div>

          <button
            type="submit" disabled={loading}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-black py-4 rounded-xl shadow-lg shadow-blue-300 transition-all active:scale-[0.97] disabled:opacity-50 flex items-center justify-center gap-2 text-base"
          >
            {loading ? (
              <div className="w-5 h-5 border-4 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>Ingia <ChevronRight className="w-5 h-5" /></>
            )}
          </button>
        </form>

        <div className="mt-8 pt-6 border-t border-slate-100 text-center">
            <p className="text-[0.65rem] font-black text-slate-300 uppercase tracking-widest leading-loose">
              &copy; 2026 MKMU Dar es Salaam<br/>Ufikaji Salama kwa Wote
            </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
