import React, { useEffect, useState, useRef } from 'react';
import { supabase } from '../utils/supabase';
import {
  Users, CheckCircle, Clock,
  LogOut, Search,
  Map as MapIcon, Image as ImageIcon,
  X, LayoutGrid, AlertTriangle, Pencil, ArrowUpDown
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import * as d3 from 'd3';
import { HALI, HALI_ORDER, Hali, haliLabel, haliShort, haliDot } from '../constants/hali';
import { tarehe, tareheNaSaa, mudaUliopita, sikuTangu } from '../utils/tarehe';

/** Rows per page in the reports table. */
const PAGE_SIZE = 15;

// Declare Leaflet for TypeScript
declare const L: any;

const MAPTILER_KEY = 'WJJkkUF7ZR4ONv2iXSdu';

interface Report {
  id: string;
  aina: string;
  maelezo: string;
  hali: string;
  maoni_ya_admin: string | null;
  mkoa: string;
  wilaya: string;
  kata: string;
  eneo_jina?: string;
  created_at: string;
  admin_updated_at: string | null;
  picha_url: string | null;
  latitude?: number;
  longitude?: number;
  frequency_count?: number;
  severity_weight?: number;
  priority_score?: number;
  user_id?: string;
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

  /** Page-level problem the admin needs to see (load failure, blocked write). */
  const [banner, setBanner] = useState<string | null>(null);
  /** Report whose status is being edited, or null when the panel is closed. */
  const [editing, setEditing] = useState<Report | null>(null);
  const [page, setPage] = useState(1);
  const [sortNewestFirst, setSortNewestFirst] = useState(true);
  const [viewingDetails, setViewingDetails] = useState<Report | null>(null);

  const mapRef = useRef<any>(null);
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<SVGSVGElement>(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchInitialData();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [filter, reports, activeTab, sortNewestFirst]);

  // Any change to what is being listed invalidates the current page number —
  // without this, filtering down to 3 results while on page 4 shows an empty
  // table that looks like "no reports" rather than "wrong page".
  useEffect(() => {
    setPage(1);
  }, [filter, activeTab, sortNewestFirst]);

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

  const getStatusColor = (status: string): string => {
    return HALI[status as Hali]?.hex || '#64748b';
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
        const color = getStatusColor(report.hali);
        const icon = L.divIcon({
          html: `<div style="
            background-color: ${color};
            width: 24px;
            height: 24px;
            border-radius: 50%;
            border: 3px solid white;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
          " title="${haliLabel(report.hali)}"></div>`,
          iconSize: [30, 30],
          popupAnchor: [0, -15],
        });

        const marker = L.marker([report.latitude, report.longitude], { icon })
          .bindPopup(`<div class="p-2 font-sans"><p class="font-black text-xs uppercase tracking-tighter" style="color: ${color}">${report.aina}</p><p class="text-xs font-bold text-slate-800">${report.kata}</p><p class="text-xs text-slate-500 mt-1">${haliLabel(report.hali)}</p></div>`);
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

      // 2. Fetch profile from public.profiles only. No fallback to admin_profiles:
      // they live in different tables, and the database policy trusts only profiles.
      // An account without a profiles row has no permissions, regardless of login.
      const { data: profile, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', authUser.id)
        .single();

      if (error || !profile) {
        console.error("Profile not found", error?.message);
        await supabase.auth.signOut();
        navigate('/login');
        return;
      }

      if (profile.role !== 'admin' && profile.role !== 'superuser') {
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
        setBanner(`Imeshindwa kupakia ripoti: ${reportsError.message}`);
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
    // Anything not yet resolved — the middle statuses are reachable now, so this
    // must not enumerate them by hand or newly-set ones would vanish from the tab.
    if (activeTab === 'recent') result = result.filter(r => r.hali !== 'imekamilika');
    else if (activeTab === 'solved') result = result.filter(r => r.hali === 'imekamilika');
    // District/ward filtering: server-side query already scoped by managed_wilaya,
    // so we only apply filter.wilaya if the admin is NOT scoped. Do not double-filter.
    if (!admin?.managed_wilaya && filter.wilaya) {
      result = result.filter(r => r.wilaya === filter.wilaya);
    }
    if (filter.kata) result = result.filter(r => r.kata === filter.kata);
    if (filter.search) {
      const s = filter.search.toLowerCase();
      result = result.filter(r =>
        r.maelezo.toLowerCase().includes(s)
        || r.aina.toLowerCase().includes(s)
        || r.kata.toLowerCase().includes(s)
        || (r.eneo_jina && r.eneo_jina.toLowerCase().includes(s))
      );
    }
    result = [...result].sort((a, b) => {
      const diff = new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
      return sortNewestFirst ? diff : -diff;
    });

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

    const statusKeys: string[] = [...HALI_ORDER];
    const statusLabels: any = Object.fromEntries(HALI_ORDER.map(h => [h, HALI[h].short]));
    const statusColors: any = Object.fromEntries(HALI_ORDER.map(h => [h, HALI[h].hex]));

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

    // Legend. Width is derived from the number of statuses rather than fixed:
    // it was pinned at `width - 150` for three keys, which ran off the right
    // edge as soon as all five became reachable.
    const legendItemWidth = 105;
    const legendWidth = statusKeys.length * legendItemWidth;

    const legend = svg.append("g")
        .attr("transform", `translate(${Math.max(0, width - legendWidth)}, -20)`)
        .selectAll("g")
        .data(statusKeys)
        .enter().append("g")
        .attr("transform", (_d, i) => `translate(${i * legendItemWidth}, 0)`);

    legend.append("rect").attr("width", 8).attr("height", 8).attr("fill", d => statusColors[d]).attr("rx", 2);
    legend.append("text").attr("x", 12).attr("y", 8).text(d => statusLabels[d]).style("font-size", "11px").style("font-weight", "800").style("fill", "#64748b");
  };

  /**
   * Saves a status change and queues a citizen notification.
   *
   * Two things this deliberately does not do: it does not assume the write
   * succeeded, and it does not update local state before the database confirms.
   * `.select()` makes the update return the rows it actually touched — if RLS
   * refuses the write, Postgres reports zero rows rather than an error, so an
   * empty result is the only evidence that nothing was saved.
   *
   * When the status or comment changes, a trigger automatically writes a row to
   * ripoti_notifications, which a background service polls to send updates to
   * the citizen (push notification, email, or realtime stream).
   *
   * Returns an error string, or null on success.
   */
  const saveStatus = async (id: string, hali: Hali, maoni: string): Promise<string | null> => {
    const comment = maoni.trim();

    const { data, error } = await supabase
      .from('ripoti')
      .update({
        hali,
        maoni_ya_admin: comment === '' ? null : comment,
        admin_updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select();

    if (error) {
      console.error('Status update failed:', error);
      return `Imeshindwa kuhifadhi: ${error.message}`;
    }

    if (!data || data.length === 0) {
      // The row exists (it is on screen) but the update matched nothing, which
      // means the row-level security policy on ripoti refused this account.
      return 'Hairuhusiwi: akaunti yako haina ruhusa ya kubadilisha ripoti hii. ' +
             'Hakuna kilichohifadhiwa.';
    }

    const saved = data[0] as Report;
    setReports(reports.map(r => (r.id === id ? { ...r, ...saved } : r)));
    return null;
  };

  const handleLogout = async () => { await supabase.auth.signOut(); navigate('/'); };

  const isMapTab = activeTab === 'map';

  const totalPages = Math.max(1, Math.ceil(filteredReports.length / PAGE_SIZE));
  // Clamped rather than trusted: deleting or re-filtering can leave `page`
  // past the end for a render, and slicing from there yields a blank table.
  const safePage = Math.min(page, totalPages);
  const pageStart = (safePage - 1) * PAGE_SIZE;
  const pageReports = filteredReports.slice(pageStart, pageStart + PAGE_SIZE);

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
            <div className="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center font-bold text-xs">
              {admin?.full_name?.[0] || 'A'}
            </div>
            <div className="overflow-hidden">
              <p className="text-xs font-black truncate">{admin?.full_name || 'Admin'}</p>
              <p className="text-xs text-slate-500 font-bold uppercase tracking-tight">{admin?.managed_wilaya || 'Region'}</p>
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
            aria-label={sidebarOpen ? 'Ficha menyu' : 'Onyesha menyu'}
            aria-expanded={sidebarOpen}
            className="absolute left-4 top-4 z-[1001] bg-white/90 backdrop-blur-sm p-2 rounded-xl shadow-xl border border-slate-100 hover:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
        >
            {sidebarOpen ? <X size={20} className="text-slate-500" aria-hidden="true"/> : <LayoutGrid size={20} className="text-blue-600" aria-hidden="true"/>}
        </button>

        {banner && (
          <div
            role="alert"
            className="absolute top-4 left-1/2 -translate-x-1/2 z-[1002] flex items-center gap-3 bg-red-50 border border-red-200 text-red-800 rounded-xl px-4 py-3 shadow-lg max-w-xl"
          >
            <AlertTriangle size={16} className="shrink-0" aria-hidden="true" />
            <span className="text-sm font-medium">{banner}</span>
            <button
              onClick={() => setBanner(null)}
              aria-label="Funga taarifa"
              className="ml-auto p-1 hover:bg-red-100 rounded focus:outline-none focus:ring-2 focus:ring-red-500"
            >
              <X size={14} aria-hidden="true" />
            </button>
          </div>
        )}

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
                  type="search" id="report-search" aria-label="Tafuta ripoti"
                  placeholder="Tafuta..."
                  className="pl-10 pr-6 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 w-64 shadow-sm text-sm font-bold transition-all"
                  value={filter.search} onChange={e => setFilter({ ...filter, search: e.target.value })}
                />
              </div>
            </header>

            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
              <StatCard label="Jumla" value={filteredReports.length} color="blue" />
              <StatCard label="Mpya" value={filteredReports.filter(r => r.hali === 'mpya').length} color="orange" />
              <StatCard label="Kazini" value={filteredReports.filter(r => r.hali !== 'mpya' && r.hali !== 'imekamilika').length} color="purple" />
              <StatCard label="Imetatuliwa" value={filteredReports.filter(r => r.hali === 'imekamilika').length} color="emerald" />
            </div>

            {activeTab === 'overview' && (
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
                <div className="lg:col-span-2 bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
                  <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-4">Distribution</h3>
                  <svg ref={chartRef} className="w-full"></svg>
                </div>
                <div className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
                  <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-6">Filter View</h3>
                  <div className="space-y-4">
                    <FilterSelect label="District" value={filter.wilaya} disabled={!!admin?.managed_wilaya}
                        options={wilayas} onChange={(v: any) => setFilter({ ...filter, wilaya: v, kata: '' })} />
                    <FilterSelect label="Ward" value={filter.kata} options={katas}
                        onChange={(v: any) => setFilter({ ...filter, kata: v })} />
                  </div>
                </div>
              </div>
            )}

            {/* No overflow-hidden here: as a flex child it capped the card at the
                leftover height and clipped every row past the fold, which read as
                "the other reports are missing". The page itself scrolls instead. */}
            <div className="bg-white rounded-3xl border border-slate-100 shadow-sm">
                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <caption className="sr-only">
                          Ripoti za wananchi — {filteredReports.length} kwa jumla
                        </caption>
                        <thead className="bg-slate-50/50">
                            <tr>
                                <th scope="col" className="px-6 py-4 text-xs font-black text-slate-500 uppercase tracking-widest">Picha</th>
                                <th scope="col" className="px-6 py-4 text-xs font-black text-slate-500 uppercase tracking-widest">Maelezo</th>
                                <th scope="col" className="px-6 py-4 text-xs font-black text-slate-500 uppercase tracking-widest">
                                  <button
                                    onClick={() => setSortNewestFirst(s => !s)}
                                    aria-label={`Panga kwa tarehe — sasa ${sortNewestFirst ? 'mpya kwanza' : 'za zamani kwanza'}`}
                                    className="flex items-center gap-1 uppercase tracking-widest hover:text-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
                                  >
                                    Imetumwa
                                    <ArrowUpDown size={12} aria-hidden="true" />
                                  </button>
                                </th>
                                <th scope="col" className="px-6 py-4 text-xs font-black text-slate-500 uppercase tracking-widest">Hali</th>
                                <th scope="col" className="px-6 py-4 text-xs font-black text-slate-500 uppercase tracking-widest">Kitendo</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                            {pageReports.map(r => (
                                <tr key={r.id} className="hover:bg-slate-50/50 transition-colors">
                                    <td className="px-6 py-4">
                                        {r.picha_url ? (
                                          <button
                                            type="button"
                                            onClick={() => setSelectedImage(r.picha_url)}
                                            aria-label={`Fungua picha ya ripoti: ${r.aina}`}
                                            className="w-12 h-12 rounded-xl bg-slate-100 overflow-hidden border-2 border-white shadow-sm cursor-pointer hover:scale-110 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-transform"
                                          >
                                            <img src={r.picha_url} alt="" className="w-full h-full object-cover"/>
                                          </button>
                                        ) : (
                                          <div className="w-12 h-12 rounded-xl bg-slate-100 border-2 border-white shadow-sm flex items-center justify-center">
                                            <ImageIcon size={16} className="text-slate-400" aria-label="Hakuna picha"/>
                                          </div>
                                        )}
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-start justify-between gap-4">
                                          <div className="flex-1">
                                            <p className="text-sm font-black text-slate-800">{r.aina}</p>
                                            <p className="text-xs text-slate-500 font-medium mb-1">
                                              {r.eneo_jina && <span>{r.eneo_jina}</span>}
                                              {r.eneo_jina && r.kata && <span> • </span>}
                                              {r.kata && <span>{r.kata}</span>}
                                            </p>
                                            <p className="text-xs text-slate-600 line-clamp-2">{r.maelezo}</p>
                                            <button
                                              type="button"
                                              onClick={() => setViewingDetails(r)}
                                              className="mt-2 text-xs font-bold text-blue-600 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
                                            >
                                              Tazama →
                                            </button>
                                          </div>
                                          {(r.frequency_count || r.priority_score) && (
                                            <div className="flex flex-col gap-2 text-right">
                                              {r.frequency_count && (
                                                <div title="Idadi ya mara zilizoripoti" className="px-2 py-1 bg-amber-50 border border-amber-200 rounded text-xs font-bold text-amber-700">
                                                  ×{r.frequency_count}
                                                </div>
                                              )}
                                              {r.priority_score && r.priority_score > 0 && (
                                                <div
                                                  title="Alama ya kipaumbele"
                                                  className={`px-2 py-1 rounded text-xs font-bold ${
                                                    r.priority_score > 5 ? 'bg-red-50 border border-red-200 text-red-700' :
                                                    r.priority_score > 2 ? 'bg-orange-50 border border-orange-200 text-orange-700' :
                                                    'bg-yellow-50 border border-yellow-200 text-yellow-700'
                                                  }`}
                                                >
                                                  ⚡{r.priority_score.toFixed(1)}
                                                </div>
                                              )}
                                            </div>
                                          )}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <p className="text-sm font-bold text-slate-700" title={tareheNaSaa(r.created_at)}>
                                          {tarehe(r.created_at)}
                                        </p>
                                        <p className="text-xs text-slate-500">{mudaUliopita(r.created_at)}</p>
                                        {/* An old report nobody has resolved is the thing a council
                                            most needs surfaced, so it is called out rather than left
                                            for the reader to work out from the date. */}
                                        {r.hali !== 'imekamilika' && (sikuTangu(r.created_at) ?? 0) > 30 && (
                                          <p className="text-xs font-bold text-amber-700 mt-1">
                                            Imesubiri siku {sikuTangu(r.created_at)}
                                          </p>
                                        )}
                                    </td>
                                    <td className="px-6 py-4">
                                        <StatusBadge status={r.hali}/>
                                        {r.admin_updated_at && (
                                          <p className="text-xs text-slate-400 mt-1" title={tareheNaSaa(r.admin_updated_at)}>
                                            Ilihaririwa {mudaUliopita(r.admin_updated_at)}
                                          </p>
                                        )}
                                    </td>
                                    <td className="px-6 py-4">
                                        <button
                                          onClick={() => setEditing(r)}
                                          aria-label={`Badilisha hali ya ripoti: ${r.aina} — ${r.kata}`}
                                          className="flex items-center gap-2 px-3 py-2 bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-600 hover:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 text-xs font-bold transition-all"
                                        >
                                            <Pencil size={14} aria-hidden="true"/> Badilisha
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>

                    {loading && (
                      <p className="py-16 text-center text-sm text-slate-500">Inapakia ripoti...</p>
                    )}

                    {!loading && filteredReports.length === 0 && (
                      <div className="py-16 text-center">
                        <p className="text-sm font-bold text-slate-600">Hakuna ripoti zinazolingana.</p>
                        <p className="text-xs text-slate-500 mt-1">
                          {filter.search || filter.kata || filter.wilaya
                            ? 'Jaribu kuondoa vichujio.'
                            : 'Bado hakuna ripoti katika eneo hili.'}
                        </p>
                      </div>
                    )}
                </div>

                {totalPages > 1 && (
                  <nav
                    aria-label="Kurasa za ripoti"
                    className="flex items-center justify-between gap-4 px-6 py-4 border-t border-slate-100"
                  >
                    <p className="text-xs text-slate-600" aria-live="polite">
                      Inaonyesha <span className="font-bold">{pageStart + 1}–{pageStart + pageReports.length}</span>
                      {' '}kati ya <span className="font-bold">{filteredReports.length}</span>
                    </p>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => setPage(Math.max(1, safePage - 1))}
                        disabled={safePage === 1}
                        className="px-3 py-2 text-xs font-bold text-slate-700 bg-slate-50 rounded-lg hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                      >
                        Iliyotangulia
                      </button>
                      <span className="text-xs font-bold text-slate-600 px-2">
                        {safePage} / {totalPages}
                      </span>
                      <button
                        onClick={() => setPage(Math.min(totalPages, safePage + 1))}
                        disabled={safePage === totalPages}
                        className="px-3 py-2 text-xs font-bold text-slate-700 bg-slate-50 rounded-lg hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                      >
                        Inayofuata
                      </button>
                    </div>
                  </nav>
                )}
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
                        className="bg-transparent text-xs font-black uppercase tracking-tighter outline-none px-2 py-1 border-r border-slate-200"
                        value={filter.wilaya} onChange={e => setFilter({...filter, wilaya: e.target.value, kata: ''})}
                    >
                        <option value="">All Districts</option>
                        {wilayas.map(w => <option key={w} value={w}>{w}</option>)}
                    </select>
                    <div className="px-2 py-1 flex items-center gap-2">
                        <Users size={12} className="text-blue-600"/>
                        <span className="text-xs font-black">{filteredReports.length} REPORTS</span>
                    </div>
                </div>
            </div>

            {/* MINI DATA OVERLAY */}
            <div className="absolute bottom-10 left-6 z-[1000] max-w-[280px] pointer-events-auto animate-in slide-in-from-left-4 duration-500">
                <div className="bg-slate-900/90 backdrop-blur-xl p-6 rounded-[2rem] shadow-2xl border border-white/10 text-white">
                    <h4 className="text-xs font-black text-blue-400 uppercase tracking-[0.2em] mb-4">Area Insight</h4>
                    <div className="space-y-4">
                        <div className="flex justify-between items-end">
                            <span className="text-xs font-bold text-slate-400">Total Active</span>
                            <span className="text-2xl font-black">{filteredReports.filter(r => r.hali !== 'imekamilika').length}</span>
                        </div>
                        <div className="h-1 bg-white/10 rounded-full overflow-hidden">
                            <div className="h-full bg-blue-500" style={{width: '65%'}}></div>
                        </div>
                        <p className="text-xs text-slate-400 leading-relaxed font-medium">
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

      {/* Status change panel */}
      {editing && (
        <StatusPanel
          report={editing}
          onClose={() => setEditing(null)}
          onSave={saveStatus}
        />
      )}

      {/* Report detail view */}
      {viewingDetails && (
        <ReportDetail
          report={viewingDetails}
          onClose={() => setViewingDetails(null)}
          onEditStatus={() => {
            setEditing(viewingDetails);
            setViewingDetails(null);
          }}
        />
      )}
    </div>
  );
};

/**
 * Deliberate status change: pick the new status, say what was done, save.
 *
 * The comment lands in `maoni_ya_admin`, which the mobile timeline screen shows
 * to the citizen who filed the report — so this is the only place in the system
 * where an admin can explain a decision to the person affected by it.
 */
const StatusPanel = ({
  report,
  onClose,
  onSave,
}: {
  report: Report;
  onClose: () => void;
  onSave: (id: string, hali: Hali, maoni: string) => Promise<string | null>;
}) => {
  const [hali, setHali] = useState<Hali>(
    (HALI_ORDER as readonly string[]).includes(report.hali) ? (report.hali as Hali) : 'mpya'
  );
  const [maoni, setMaoni] = useState(report.maoni_ya_admin ?? '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const closingReport = hali === 'imekamilika' && report.hali !== 'imekamilika';

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    const failure = await onSave(report.id, hali, maoni);
    setSaving(false);
    if (failure) setError(failure);
    else onClose();
  };

  return (
    <div
      className="fixed inset-0 z-[2000] bg-slate-900/80 backdrop-blur-sm flex items-center justify-center p-4"
      onClick={onClose}
    >
      <form
        role="dialog"
        aria-modal="true"
        aria-labelledby="status-panel-title"
        onClick={(e) => e.stopPropagation()}
        onSubmit={submit}
        className="bg-white rounded-3xl w-full max-w-lg p-8 shadow-2xl"
      >
        <div className="flex justify-between items-start mb-6">
          <div>
            <h3 id="status-panel-title" className="text-xl font-black text-slate-900">Badilisha Hali</h3>
            <p className="text-sm text-slate-500 mt-1">{report.aina} — {report.kata || report.wilaya}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Funga"
            className="p-2 text-slate-400 hover:bg-slate-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <X size={20} aria-hidden="true" />
          </button>
        </div>

        <p className="text-sm text-slate-600 bg-slate-50 rounded-xl p-4 mb-6">{report.maelezo}</p>

        <label htmlFor="hali-select" className="block text-sm font-bold text-slate-700 mb-2">
          Hali mpya
        </label>
        <select
          id="hali-select"
          value={hali}
          onChange={(e) => setHali(e.target.value as Hali)}
          className="w-full p-3 mb-6 bg-white border border-slate-300 rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          {HALI_ORDER.map((h) => (
            <option key={h} value={h}>{HALI[h].label}</option>
          ))}
        </select>

        <label htmlFor="maoni-input" className="block text-sm font-bold text-slate-700 mb-2">
          Maoni ya msimamizi
        </label>
        <p id="maoni-help" className="text-xs text-slate-500 mb-2">
          Mwananchi aliyetuma ripoti ataona maelezo haya kwenye simu yake.
        </p>
        <textarea
          id="maoni-input"
          aria-describedby="maoni-help"
          value={maoni}
          onChange={(e) => setMaoni(e.target.value)}
          rows={3}
          placeholder="Eleza kilichofanyika..."
          className="w-full p-3 bg-white border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />

        {closingReport && (
          <p className="flex gap-2 mt-4 text-sm text-amber-800 bg-amber-50 border border-amber-200 rounded-xl p-3">
            <AlertTriangle size={16} className="shrink-0 mt-0.5" aria-hidden="true" />
            <span>Unafunga ripoti hii. Mwananchi ataona kuwa imetatuliwa.</span>
          </p>
        )}

        {error && (
          <p role="alert" className="flex gap-2 mt-4 text-sm text-red-800 bg-red-50 border border-red-200 rounded-xl p-3">
            <AlertTriangle size={16} className="shrink-0 mt-0.5" aria-hidden="true" />
            <span>{error}</span>
          </p>
        )}

        <div className="flex gap-3 mt-8">
          <button
            type="submit"
            disabled={saving}
            className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold text-sm hover:bg-blue-700 disabled:opacity-50 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
          >
            {saving ? 'Inahifadhi...' : 'Hifadhi'}
          </button>
          <button
            type="button"
            onClick={onClose}
            className="px-6 py-3 text-slate-600 rounded-xl font-bold text-sm hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
          >
            Ghairi
          </button>
        </div>
      </form>
    </div>
  );
};

/**
 * Full report details: complete description, location, priority metrics, history.
 * Opened from the table row "Tazama" link to show all information that was
 * truncated in the table view.
 */
interface HistoryEntry {
  id: string;
  ripoti_id: string;
  changed_by: string | null;
  hali_old: string | null;
  hali_new: string | null;
  maoni_ya_admin_old: string | null;
  maoni_ya_admin_new: string | null;
  changed_at: string;
}

const ReportDetail = ({
  report,
  onClose,
  onEditStatus,
}: {
  report: Report;
  onClose: () => void;
  onEditStatus: () => void;
}) => {
  const [history, setHistory] = useState<HistoryEntry[]>([]);
  const [loadingHistory, setLoadingHistory] = useState(true);

  useEffect(() => {
    const fetchHistory = async () => {
      const { data } = await supabase
        .from('ripoti_history')
        .select('*')
        .eq('ripoti_id', report.id)
        .order('changed_at', { ascending: false });
      setHistory((data || []) as HistoryEntry[]);
      setLoadingHistory(false);
    };
    fetchHistory();
  }, [report.id]);

  const photos = report.picha_url ? [report.picha_url] : [];
  const hasPriority = report.frequency_count || report.severity_weight || report.priority_score;

  return (
    <div
      className="fixed inset-0 z-[2000] bg-slate-900/80 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto"
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="bg-white rounded-3xl w-full max-w-2xl my-8 shadow-2xl"
      >
        {/* Header */}
        <div className="flex justify-between items-start p-8 border-b border-slate-100">
          <div>
            <h2 className="text-2xl font-black text-slate-900">{report.aina}</h2>
            <p className="text-sm text-slate-500 mt-1">
              {report.eneo_jina && <span>{report.eneo_jina}</span>}
              {report.eneo_jina && report.kata && <span> • </span>}
              {report.kata && <span>{report.kata}, {report.wilaya}</span>}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-slate-400 hover:bg-slate-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <X size={24} />
          </button>
        </div>

        {/* Content */}
        <div className="p-8 space-y-6">
          {/* Photo */}
          {photos.length > 0 && (
            <div className="rounded-2xl overflow-hidden bg-slate-100">
              <img src={photos[0]} alt="" className="w-full h-96 object-cover" />
            </div>
          )}

          {/* Full Description */}
          <div>
            <h3 className="text-sm font-black text-slate-600 uppercase tracking-widest mb-2">Maelezo</h3>
            <p className="text-sm text-slate-700 leading-relaxed whitespace-pre-wrap">{report.maelezo}</p>
          </div>

          {/* Location Details */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs font-black text-slate-500 uppercase tracking-widest">Mkoa</p>
              <p className="text-sm font-bold text-slate-800">{report.mkoa}</p>
            </div>
            <div>
              <p className="text-xs font-black text-slate-500 uppercase tracking-widest">Wilaya</p>
              <p className="text-sm font-bold text-slate-800">{report.wilaya}</p>
            </div>
            <div>
              <p className="text-xs font-black text-slate-500 uppercase tracking-widest">Kata</p>
              <p className="text-sm font-bold text-slate-800">{report.kata}</p>
            </div>
            <div>
              <p className="text-xs font-black text-slate-500 uppercase tracking-widest">Mahali</p>
              <p className="text-sm font-bold text-slate-800">{report.eneo_jina || '—'}</p>
            </div>
          </div>

          {/* Coordinates */}
          {(report.latitude || report.longitude) && (
            <div>
              <p className="text-xs font-black text-slate-500 uppercase tracking-widest mb-2">Nafasi</p>
              <p className="text-sm text-slate-700">
                {report.latitude?.toFixed(4)}, {report.longitude?.toFixed(4)}
              </p>
            </div>
          )}

          {/* Priority Index */}
          {hasPriority && (
            <div className="bg-slate-50 rounded-xl p-4">
              <p className="text-xs font-black text-slate-600 uppercase tracking-widest mb-3">Kipaumbele cha Ripoti</p>
              <div className="space-y-2">
                {report.frequency_count !== undefined && (
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-600">Idadi ya Mara</span>
                    <span className="font-bold text-slate-800">{report.frequency_count}</span>
                  </div>
                )}
                {report.severity_weight !== undefined && (
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-600">Uzito wa Ukali</span>
                    <span className="font-bold text-slate-800">{report.severity_weight.toFixed(2)}</span>
                  </div>
                )}
                {report.priority_score !== undefined && (
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-600">Alama ya Kipaumbele</span>
                    <span className="font-bold text-slate-800">{report.priority_score.toFixed(2)}</span>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Status & Admin Comments */}
          <div className="border-t border-slate-100 pt-4">
            <h3 className="text-sm font-black text-slate-600 uppercase tracking-widest mb-3">Hali na Maoni</h3>
            <div className="space-y-3">
              <div>
                <p className="text-xs text-slate-500 mb-1">Hali Mwanzo</p>
                <p className="text-sm font-bold">
                  <StatusBadge status={report.hali} />
                </p>
              </div>
              {report.maoni_ya_admin && (
                <div className="bg-blue-50 rounded-xl p-4">
                  <p className="text-xs font-black text-slate-600 uppercase tracking-widest mb-2">Maoni ya Msimamizi</p>
                  <p className="text-sm text-slate-700 whitespace-pre-wrap">{report.maoni_ya_admin}</p>
                  <p className="text-xs text-slate-500 mt-2">
                    Mwananchi ataona maelezo haya kwenye simu yake.
                  </p>
                </div>
              )}
              {report.admin_updated_at && (
                <p className="text-xs text-slate-500">
                  Ilihaririwa {tareheNaSaa(report.admin_updated_at)}
                </p>
              )}
            </div>
          </div>

          {/* Timeline info */}
          <div className="border-t border-slate-100 pt-4">
            <p className="text-xs text-slate-500">
              Imetumwa {tareheNaSaa(report.created_at)}
            </p>
          </div>

          {/* History Timeline */}
          {!loadingHistory && history.length > 0 && (
            <div className="border-t border-slate-100 pt-4">
              <h3 className="text-sm font-black text-slate-600 uppercase tracking-widest mb-4">Historia ya Badiliko</h3>
              <div className="space-y-3">
                {history.map((entry) => (
                  <div key={entry.id} className="flex gap-4">
                    <div className="mt-1">
                      <div className="w-2 h-2 rounded-full bg-blue-500"></div>
                    </div>
                    <div className="flex-1">
                      <p className="text-xs text-slate-500">{tareheNaSaa(entry.changed_at)}</p>
                      {entry.hali_old !== entry.hali_new && (
                        <p className="text-sm font-medium text-slate-700 mt-1">
                          Hali: <span className="line-through text-slate-400">{haliLabel(entry.hali_old || '')}</span>
                          {' → '}<span className="font-bold text-blue-600">{haliLabel(entry.hali_new || '')}</span>
                        </p>
                      )}
                      {entry.maoni_ya_admin_new && entry.maoni_ya_admin_old !== entry.maoni_ya_admin_new && (
                        <p className="text-sm text-slate-700 mt-1 bg-slate-50 p-2 rounded border border-slate-200">
                          "{entry.maoni_ya_admin_new}"
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3 p-8 border-t border-slate-100">
          <button
            type="button"
            onClick={onEditStatus}
            className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold text-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all flex items-center justify-center gap-2"
          >
            <Pencil size={16} aria-hidden="true" /> Badilisha Hali
          </button>
          <button
            type="button"
            onClick={onClose}
            className="px-6 py-3 text-slate-600 rounded-xl font-bold text-sm hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
          >
            Funga
          </button>
        </div>
      </div>
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
      <p className="text-xs font-black text-slate-500 uppercase tracking-widest mb-1">{label}</p>
      <p className={`text-2xl font-black tracking-tighter ${colors[color]}`}>{value}</p>
    </div>
  );
};

const FilterSelect = ({ label, value, options, onChange, disabled }: any) => {
  const id = `filter-${String(label).toLowerCase().replace(/\s+/g, '-')}`;
  return (
  <div className="flex-1">
    <label htmlFor={id} className="block text-xs font-black text-slate-500 uppercase tracking-[0.15em] mb-2 ml-1">{label}</label>
    <select
      id={id}
      disabled={disabled}
      className="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-xl outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 font-bold text-xs text-slate-700 transition-all disabled:opacity-50"
      value={value} onChange={e => onChange(e.target.value)}
    >
      <option value="">All {label}s</option>
      {options.map((o: any) => <option key={o} value={o}>{o}</option>)}
    </select>
  </div>
  );
};

const StatusBadge = ({ status }: { status: string }) => (
  <div className="flex items-center gap-2" title={haliLabel(status)}>
    <div className={`w-2 h-2 rounded-full ${haliDot(status)}`} aria-hidden="true"></div>
    <span className="text-xs font-bold text-slate-700">{haliShort(status)}</span>
  </div>
);

export default Dashboard;
