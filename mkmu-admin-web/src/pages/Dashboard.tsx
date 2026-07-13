import React, { useEffect, useState, useRef } from 'react';
import { supabase } from '../utils/supabase';
import {
  Users, MapPin, CheckCircle, Clock,
  BarChart3, Filter, LogOut, Search,
  ChevronRight, AlertTriangle, Info, Map as MapIcon, Image as ImageIcon,
  Maximize2, X, LayoutGrid
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import * as d3 from 'd3';

// Declare Leaflet for TypeScript
declare const L: any;

const MAPTILER_KEY = 'WJJkkUF7ZR4ONv2iXSdu';

interface Report {
  id: string;
  aina: string;
  maelezo: string;
  hali: string;
  mkoa: string;
  wilaya: string;
  kata: string;
  created_at: string;
  picha_url: string;
  latitude?: number;
  longitude?: number;
}

const DISTRICT_WARDS: Record<string, string[]> = {
  "Ilala": [
    "Bonyokwa", "Buguruni", "Buyuni", "Chanika", "Gerezani", "Gongolamboto", "Ilala", "Jangwani",
    "Kariakoo", "Kimanga", "Kinyerezi", "Kipawa", "Kipunguni", "Kisukuru", "Kitunda", "Kisutu",
    "Kivukoni", "Kivule", "Kiwalani", "Liwiti", "Majohe", "Mchafukoge", "Mchikichini", "Minazi Mirefu",
    "Mnyamani", "Msongola", "Mzinga", "Pugu", "Pugu Station", "Segerea", "Tabata", "Ukonga",
    "Upanga East", "Upanga West", "Vingunguti", "Zingiziwa"
  ],
  "Kinondoni": [
    "Bunju", "Hananasif", "Kawe", "Kigogo", "Kijitonyama", "Kinondoni", "Kunduchi", "Mabwepande",
    "Magomeni", "Makongo", "Makumbusho", "Mbezi Juu", "Mbweni", "Mikocheni", "Msasani",
    "Mwananyamala", "Mzimuni", "Ndugumbi", "Tandale", "Wazo"
  ],
  "Temeke": [
    "Azimio", "Buza", "Chamazi", "Chang'ombe", "Charambe", "Keko", "Kiburugwa", "Kijichi",
    "Kilakala", "Kurasini", "Makangarawe", "Mbagala", "Mbagala Kuu", "Mianzini", "Miburani",
    "Mtoni", "Sandali", "Tandika", "Temeke", "Toangoma", "Yombo Vituka"
  ],
  "Ubungo": [
    "Goba", "Kibamba", "Kimara", "Kwembe", "Mabibo", "Makuburi", "Makurumla", "Manzese",
    "Mbezi", "Mburahati", "Msigani", "Saranga", "Sinza", "Ubungo"
  ],
  "Kigamboni": [
    "Kigamboni", "Kimbiji", "Kisarawe II", "Mjimwema", "Pembamnazi", "Somangila", "Tungi",
    "Vijibweni", "Kibada"
  ]
};

const Dashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'overview' | 'recent' | 'solved' | 'map'>('overview');
  const [reports, setReports] = useState<Report[]>([]);
  const [filteredReports, setFilteredReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [admin, setAdmin] = useState<any>(null);
  const [filter, setFilter] = useState({ wilaya: '', kata: '', search: '' });
  const [wilayas] = useState<string[]>(Object.keys(DISTRICT_WARDS));
  const [katas, setKatas] = useState<string[]>([]);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [selectedImage, setSelectedImage] = useState<string | null>(null);

  const mapRef = useRef<any>(null);
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<SVGSVGElement>(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchInitialData();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [filter, reports, activeTab]);

  useEffect(() => {
    if (loading) return;
    const timer = setTimeout(() => {
      if (activeTab === 'overview' || activeTab === 'map') {
        initMap();
        updateMapMarkers();
        if (activeTab === 'overview') renderD3Chart();
      }
    }, 200);
    return () => clearTimeout(timer);
  }, [activeTab, filteredReports, loading, sidebarOpen]);

  const initMap = () => {
    if (!mapContainerRef.current) return;
    if (mapRef.current) {
      mapRef.current.invalidateSize();
      return;
    }
    try {
      mapRef.current = L.map(mapContainerRef.current, { zoomControl: false, maxZoom: 19 }).setView([-6.8235, 39.2695], 13);
      L.tileLayer(`https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${MAPTILER_KEY}`, {
        attribution: '&copy; MapTiler',
        maxZoom: 19
      }).addTo(mapRef.current);
      L.control.zoom({ position: 'bottomright' }).addTo(mapRef.current);
    } catch (e) {
      console.error("Map fail:", e);
    }
  };

  const updateMapMarkers = () => {
    if (!mapRef.current) return;
    mapRef.current.eachLayer((layer: any) => { if (layer instanceof L.Marker) mapRef.current.removeLayer(layer); });
    const markers: any[] = [];

    // Strict Role Filtering for Markers
    let mapData = filteredReports;
    if (admin?.role === 'admin' && admin?.managed_wilaya) {
        mapData = mapData.filter(r => r.wilaya === admin.managed_wilaya);
    }

    mapData.forEach(report => {
      if (report.latitude && report.longitude) {
        const marker = L.marker([report.latitude, report.longitude])
          .bindPopup(`<div class="p-2 font-sans"><p class="font-black text-blue-600 text-[9px] uppercase tracking-tighter">${report.aina}</p><p class="text-[10px] font-bold text-slate-800">${report.kata}</p></div>`);
        marker.addTo(mapRef.current);
        markers.push(marker);
      }
    });
    if (markers.length > 0) try { mapRef.current.fitBounds(L.featureGroup(markers).getBounds().pad(0.1)); } catch (e) {}
  };

  const fetchInitialData = async () => {
    setLoading(true);
    try {
      // 1. Get current user
      const { data: { user: authUser } } = await supabase.auth.getUser();

      if (!authUser) {
        navigate('/login');
        return;
      }

      // 2. Fetch profile
      let { data: profile, error } = await supabase.from('profiles').select('*').eq('id', authUser.id).single();

      if (error || !profile) {
          const { data: adminP } = await supabase.from('admin_profiles').select('*').eq('id', authUser.id).single();
          if (adminP) {
              profile = {
                  ...adminP,
                  full_name: adminP.majina_kamili,
                  managed_wilaya: adminP.assigned_district,
                  role: adminP.role
              };
          }
      }

      if (!profile) {
        console.error("No profile found for admin");
        await supabase.auth.signOut();
        navigate('/login');
        return;
      }

      setAdmin(profile);

      // 3. Fetch reports with strict scoping
      let query = supabase.from('ripoti').select('*');

      // If not superuser, limit to managed district
      if (profile.role !== 'superuser') {
        const district = profile.managed_wilaya; // Already normalized in the block above
        if (district) {
          query = query.eq('wilaya', district);
        }
      }

      const { data, error: reportsError } = await query.order('created_at', { ascending: false });

      if (reportsError) {
        console.error("Error fetching reports:", reportsError);
      }

      setReports(data || []);

      if (profile?.managed_wilaya) {
        setFilter(f => ({ ...f, wilaya: profile.managed_wilaya }));
      }
    } catch (err) {
      console.error("Initialization error:", err);
      navigate('/login');
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let result = reports;
    if (activeTab === 'recent') result = result.filter(r => r.hali === 'mpya' || r.hali === 'inashughulikiwa');
    else if (activeTab === 'solved') result = result.filter(r => r.hali === 'imekamilika');
    if (admin?.managed_wilaya) result = result.filter(r => r.wilaya === admin.managed_wilaya);
    else if (filter.wilaya) result = result.filter(r => r.wilaya === filter.wilaya);
    if (filter.kata) result = result.filter(r => r.kata === filter.kata);
    if (filter.search) {
      const s = filter.search.toLowerCase();
      result = result.filter(r => r.maelezo.toLowerCase().includes(s) || r.aina.toLowerCase().includes(s) || r.kata.toLowerCase().includes(s));
    }
    setFilteredReports(result);
    const w = admin?.managed_wilaya || filter.wilaya;
    const dynamicKatas = reports
      .filter(r => r.wilaya === w && r.kata && r.kata !== 'EMPTY')
      .map(r => r.kata);
    const combinedKatas = [...new Set([...(w && DISTRICT_WARDS[w] ? DISTRICT_WARDS[w] : []), ...dynamicKatas])].sort();
    setKatas(combinedKatas);
  };

  const renderD3Chart = () => {
    if (!chartRef.current || activeTab !== 'overview') return;

    // Process data for COMPARATIVE GROUPED BAR CHART
    const categories = [...new Set(filteredReports.map(d => d.aina))];
    if (categories.length === 0) categories.push('No Data');

    const statusKeys = ['mpya', 'inashughulikiwa', 'imekamilika'];
    const statusLabels: any = { mpya: 'Reported', inashughulikiwa: 'Fixing', imekamilika: 'Fixed' };
    const statusColors: any = { mpya: '#f97316', inashughulikiwa: '#a855f7', imekamilika: '#10b981' };

    const data = categories.map(cat => {
        const obj: any = { category: cat };
        statusKeys.forEach(status => {
            obj[status] = filteredReports.filter(r => r.aina === cat && r.hali === status).length;
        });
        return obj;
    });

    const margin = { top: 30, right: 30, bottom: 40, left: 120 };
    const width = 800 - margin.left - margin.right;
    const height = Math.max(300, data.length * 60);

    d3.select(chartRef.current).selectAll("*").remove();

    const svg = d3.select(chartRef.current)
      .attr("viewBox", `0 0 ${width + margin.left + margin.right} ${height + margin.top + margin.bottom}`)
      .append("g")
      .attr("transform", `translate(${margin.left},${margin.top})`);

    const y0 = d3.scaleBand().range([0, height]).domain(categories).paddingInner(0.3);
    const y1 = d3.scaleBand().domain(statusKeys).rangeRound([0, y0.bandwidth()]).padding(0.05);

    const maxVal = d3.max(data, d => d3.max(statusKeys, k => d[k])) || 1;
    const x = d3.scaleLinear()
        .domain([0, Math.max(5, maxVal)])
        .range([0, width]);

    // X Axis
    svg.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(d3.axisBottom(x).ticks(5).tickSize(-height).tickPadding(10))
      .call(g => g.select(".domain").remove())
      .call(g => g.selectAll(".tick line").attr("stroke", "#f1f5f9"));

    // Y Axis
    svg.append("g")
      .call(d3.axisLeft(y0).tickSize(0).tickPadding(10))
      .call(g => g.select(".domain").remove())
      .selectAll("text")
      .style("font-weight", "800")
      .style("font-size", "11px")
      .style("fill", "#64748b");

    // Bars
    svg.append("g")
      .selectAll("g")
      .data(data)
      .enter()
      .append("g")
      .attr("transform", d => `translate(0,${y0(d.category)})`)
      .selectAll("rect")
      .data(d => statusKeys.map(key => ({ key, value: d[key] })))
      .enter()
      .append("rect")
      .attr("x", x(0))
      .attr("y", d => y1(d.key) || 0)
      .attr("width", d => x(d.value))
      .attr("height", y1.bandwidth())
      .attr("fill", d => statusColors[d.key])
      .attr("rx", 4);

    // Legend
    const legend = svg.append("g")
        .attr("transform", `translate(${width - 150}, -20)`)
        .selectAll("g")
        .data(statusKeys)
        .enter().append("g")
        .attr("transform", (d, i) => `translate(${i * 60}, 0)`);

    legend.append("rect").attr("width", 8).attr("height", 8).attr("fill", d => statusColors[d]);
    legend.append("text").attr("x", 12).attr("y", 8).text(d => statusLabels[d]).style("font-size", "9px").style("font-weight", "900").style("fill", "#94a3b8").style("text-transform", "uppercase");
  };

  const updateStatus = async (id: string, h: string) => {
    try { await supabase.from('ripoti').update({ hali: h }).eq('id', id); setReports(reports.map(r => r.id === id ? { ...r, hali: h } : r)); }
    catch (err) { alert('Failed'); }
  };

  const handleLogout = async () => { await supabase.auth.signOut(); navigate('/'); };

  const isMapTab = activeTab === 'map';

  return (
    <div className="flex h-screen bg-slate-50 font-sans overflow-hidden">
      {/* Immersive Sidebar */}
      <aside className={`${sidebarOpen ? 'w-64' : 'w-0 overflow-hidden'} bg-slate-900 text-white flex flex-col transition-all duration-500 ease-in-out z-50 shadow-2xl relative`}>
        <div className="p-6">
            <div className="flex items-center gap-3 mb-10">
            <div className="w-8 h-8 rounded-lg overflow-hidden border border-blue-500/50 shadow-blue-500/10 shadow-lg">
                <img src="/logo.png" alt="Logo" className="w-full h-full object-cover" />
            </div>
            <span className="text-lg font-black tracking-tighter">MKMU ADMIN</span>
            </div>
            <nav className="space-y-1">
            <NavItem icon={<LayoutGrid size={18}/>} label="Overview" active={activeTab === 'overview'} onClick={() => setActiveTab('overview')} />
            <NavItem icon={<Clock size={18}/>} label="Recent" active={activeTab === 'recent'} onClick={() => setActiveTab('recent')} />
            <NavItem icon={<CheckCircle size={18}/>} label="Solved" active={activeTab === 'solved'} onClick={() => setActiveTab('solved')} />
            <NavItem icon={<MapIcon size={18}/>} label="Full Map" active={activeTab === 'map'} onClick={() => setActiveTab('map')} />
            </nav>
        </div>
        <div className="mt-auto p-6 border-t border-white/5">
          <div className="flex items-center gap-3 mb-6 bg-white/5 p-3 rounded-xl">
            <div className="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center font-bold text-[10px]">
              {admin?.full_name?.[0] || 'A'}
            </div>
            <div className="overflow-hidden">
              <p className="text-[10px] font-black truncate">{admin?.full_name || 'Admin'}</p>
              <p className="text-[8px] text-slate-500 font-bold uppercase tracking-tight">{admin?.managed_wilaya || 'Region'}</p>
            </div>
          </div>
          <button onClick={handleLogout} className="flex items-center gap-2 w-full p-2 text-red-400 hover:bg-red-500/10 rounded-lg font-bold text-xs transition-all">
            <LogOut size={14} /> Sign Out
          </button>
        </div>
      </aside>

      {/* Main Container */}
      <main className={`flex-1 flex flex-col relative ${isMapTab ? 'p-0' : 'p-8'} overflow-hidden transition-all duration-500`}>
        {/* Toggle Sidebar Button */}
        <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className={`absolute ${sidebarOpen ? 'left-4' : 'left-4'} top-4 z-[1001] bg-white/90 backdrop-blur-sm p-2 rounded-xl shadow-xl border border-slate-100 hover:bg-white transition-all`}
        >
            {sidebarOpen ? <X size={20} className="text-slate-400"/> : <LayoutGrid size={20} className="text-blue-600"/>}
        </button>

        {!isMapTab ? (
          <div className="h-full flex flex-col overflow-y-auto pr-2 custom-scrollbar">
            <header className="flex justify-between items-center mb-8 pl-12">
              <div>
                <h2 className="text-3xl font-black text-slate-900 tracking-tight capitalize">{activeTab}</h2>
                <p className="text-xs text-slate-500 font-bold uppercase tracking-widest mt-1">Dar es Salaam / {admin?.managed_wilaya || 'Metropolitan'}</p>
              </div>
              <div className="relative group">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 w-4 h-4 group-focus-within:text-blue-500 transition-colors" />
                <input
                  type="text" placeholder="Search data..."
                  className="pl-10 pr-6 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:ring-4 focus:ring-blue-500/5 focus:border-blue-500 w-64 shadow-sm text-xs font-bold transition-all"
                  value={filter.search} onChange={e => setFilter({ ...filter, search: e.target.value })}
                />
              </div>
            </header>

            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
              <StatCard label="Total" value={filteredReports.length} color="blue" />
              <StatCard label="New" value={filteredReports.filter(r => r.hali === 'mpya').length} color="orange" />
              <StatCard label="Active" value={filteredReports.filter(r => r.hali === 'inashughulikiwa').length} color="purple" />
              <StatCard label="Done" value={filteredReports.filter(r => r.hali === 'imekamilika').length} color="emerald" />
            </div>

            {activeTab === 'overview' && (
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
                <div className="lg:col-span-2 bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
                  <h3 className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-4">Distribution</h3>
                  <svg ref={chartRef} className="w-full"></svg>
                </div>
                <div className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
                  <h3 className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-6">Filter View</h3>
                  <div className="space-y-4">
                    <FilterSelect label="District" value={filter.wilaya} disabled={!!admin?.managed_wilaya}
                        options={wilayas} onChange={(v: any) => setFilter({ ...filter, wilaya: v, kata: '' })} />
                    <FilterSelect label="Ward" value={filter.kata} options={katas}
                        onChange={(v: any) => setFilter({ ...filter, kata: v })} />
                  </div>
                </div>
              </div>
            )}

            <div className="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden flex-1 min-h-[400px]">
                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead className="bg-slate-50/50">
                            <tr>
                                <th className="px-6 py-4 text-[9px] font-black text-slate-400 uppercase tracking-widest">Image</th>
                                <th className="px-6 py-4 text-[9px] font-black text-slate-400 uppercase tracking-widest">Description</th>
                                <th className="px-6 py-4 text-[9px] font-black text-slate-400 uppercase tracking-widest">Status</th>
                                <th className="px-6 py-4 text-[9px] font-black text-slate-400 uppercase tracking-widest">Action</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                            {filteredReports.map(r => (
                                <tr key={r.id} className="hover:bg-slate-50/50 transition-colors">
                                    <td className="px-6 py-4">
                                        <div
                                          className={`w-12 h-12 rounded-xl bg-slate-100 overflow-hidden border-2 border-white shadow-sm ${r.picha_url ? 'cursor-pointer hover:scale-110 transition-transform' : ''}`}
                                          onClick={() => r.picha_url && setSelectedImage(r.picha_url)}
                                        >
                                            {r.picha_url ? <img src={r.picha_url} className="w-full h-full object-cover"/> : <ImageIcon size={16} className="m-auto mt-4 text-slate-300"/>}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <p className="text-xs font-black text-slate-800">{r.aina}</p>
                                        <p className="text-[10px] text-slate-500 font-medium truncate max-w-[200px]">{r.maelezo}</p>
                                    </td>
                                    <td className="px-6 py-4"><StatusBadge status={r.hali}/></td>
                                    <td className="px-6 py-4">
                                        <button onClick={() => updateStatus(r.id, r.hali === 'mpya' ? 'inashughulikiwa' : 'imekamilika')} className="p-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-600 hover:text-white transition-all">
                                            <ChevronRight size={14}/>
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
          </div>
        ) : (
          /* IMMERSIVE MAP VIEW */
          <div className="h-full w-full relative group">
            <div ref={mapContainerRef} className="absolute inset-0 z-0"></div>

            {/* FLOATING TOP NAV */}
            <div className="absolute top-6 left-20 right-6 z-[1000] flex justify-between items-start pointer-events-none">
                <div className="flex gap-2 pointer-events-auto">
                    <div className="bg-white/80 backdrop-blur-md px-4 py-2 rounded-2xl shadow-2xl border border-white/50 flex items-center gap-3">
                        <MapIcon size={16} className="text-blue-600"/>
                        <span className="text-xs font-black tracking-tight text-slate-800">Live Infrastructure Monitoring</span>
                    </div>
                </div>

                <div className="bg-white/80 backdrop-blur-md p-2 rounded-2xl shadow-2xl border border-white/50 pointer-events-auto flex gap-2">
                    <select
                        className="bg-transparent text-[10px] font-black uppercase tracking-tighter outline-none px-2 py-1 border-r border-slate-200"
                        value={filter.wilaya} onChange={e => setFilter({...filter, wilaya: e.target.value, kata: ''})}
                    >
                        <option value="">All Districts</option>
                        {wilayas.map(w => <option key={w} value={w}>{w}</option>)}
                    </select>
                    <div className="px-2 py-1 flex items-center gap-2">
                        <Users size={12} className="text-blue-600"/>
                        <span className="text-[10px] font-black">{filteredReports.length} REPORTS</span>
                    </div>
                </div>
            </div>

            {/* MINI DATA OVERLAY */}
            <div className="absolute bottom-10 left-6 z-[1000] max-w-[280px] pointer-events-auto animate-in slide-in-from-left-4 duration-500">
                <div className="bg-slate-900/90 backdrop-blur-xl p-6 rounded-[2rem] shadow-2xl border border-white/10 text-white">
                    <h4 className="text-[9px] font-black text-blue-400 uppercase tracking-[0.2em] mb-4">Area Insight</h4>
                    <div className="space-y-4">
                        <div className="flex justify-between items-end">
                            <span className="text-[10px] font-bold text-slate-400">Total Active</span>
                            <span className="text-2xl font-black">{filteredReports.filter(r => r.hali !== 'imekamilika').length}</span>
                        </div>
                        <div className="h-1 bg-white/10 rounded-full overflow-hidden">
                            <div className="h-full bg-blue-500" style={{width: '65%'}}></div>
                        </div>
                        <p className="text-[9px] text-slate-400 leading-relaxed font-medium">
                            Displaying real-time geo-data for <span className="text-white font-bold">{filter.wilaya || 'All Districts'}</span>.
                            Interactive points indicate citizen-reported accessibility barriers.
                        </p>
                    </div>
                </div>
            </div>
          </div>
        )}
      </main>

      {/* Image Modal */}
      {selectedImage && (
        <div
          className="fixed inset-0 z-[2000] bg-slate-900/90 backdrop-blur-sm flex items-center justify-center p-4 animate-in fade-in duration-300"
          onClick={() => setSelectedImage(null)}
        >
          <button
            className="absolute top-6 right-6 text-white hover:bg-white/10 p-2 rounded-full transition-colors"
            onClick={() => setSelectedImage(null)}
          >
            <X size={32} />
          </button>

          <div className="relative max-w-5xl max-h-full w-full flex items-center justify-center">
            <img
              src={selectedImage}
              alt="Report Full Size"
              className="max-w-full max-h-[90vh] object-contain rounded-2xl shadow-2xl border border-white/10"
              onClick={(e) => e.stopPropagation()}
            />
          </div>
        </div>
      )}
    </div>
  );
};

const NavItem = ({ icon, label, active, onClick }: any) => (
  <button onClick={onClick} className={`flex items-center gap-3 w-full p-3.5 rounded-xl font-bold transition-all duration-300 ${
    active ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30 translate-x-1' : 'text-slate-500 hover:bg-white/5 hover:text-slate-300'
  }`}>
    <span className={active ? 'text-white' : 'text-slate-600'}>{icon}</span>
    <span className="text-xs">{label}</span>
  </button>
);

const StatCard = ({ label, value, color }: any) => {
  const colors: any = {
    blue: "text-blue-600",
    orange: "text-orange-600",
    purple: "text-purple-600",
    emerald: "text-emerald-600"
  };

  return (
    <div className="bg-white px-6 py-5 rounded-3xl border border-slate-100 shadow-sm hover:shadow-md transition-all">
      <p className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">{label}</p>
      <p className={`text-2xl font-black tracking-tighter ${colors[color]}`}>{value}</p>
    </div>
  );
};

const FilterSelect = ({ label, value, options, onChange, disabled }: any) => (
  <div className="flex-1">
    <label className="block text-[9px] font-black text-slate-400 uppercase tracking-[0.15em] mb-2 ml-1">{label}</label>
    <select
      disabled={disabled}
      className="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-xl outline-none focus:ring-4 focus:ring-blue-500/5 focus:border-blue-500 font-bold text-[11px] text-slate-700 transition-all disabled:opacity-50"
      value={value} onChange={e => onChange(e.target.value)}
    >
      <option value="">All {label}s</option>
      {options.map((o: any) => <option key={o} value={o}>{o}</option>)}
    </select>
  </div>
);

const StatusBadge = ({ status }: { status: string }) => {
  const cfg: any = {
    mpya: { bg: "bg-orange-400", label: "New" },
    inashughulikiwa: { bg: "bg-purple-500", label: "Action" },
    imekamilika: { bg: "bg-emerald-500", label: "Done" }
  }[status] || { bg: "bg-slate-400", label: status };

  return (
    <div className="flex items-center gap-2">
        <div className={`w-1.5 h-1.5 rounded-full ${cfg.bg}`}></div>
        <span className="text-[10px] font-bold text-slate-600 uppercase tracking-tighter">{cfg.label}</span>
    </div>
  );
};

export default Dashboard;
