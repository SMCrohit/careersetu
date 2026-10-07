import { useState, useEffect } from 'react';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';
import { Users, Briefcase, FileText, Calendar } from 'lucide-react';
import api from '../api/axios';
import { useToast } from '../context/ToastContext';

const Dashboard = () => {
  const { showToast } = useToast();
  const [filter, setFilter] = useState(() => localStorage.getItem('dashboard_filter') || 'This Week');
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totals: { users: 0, job_applications: 0, tests: 0, appointments: 0 },
    chart_data: [],
    completion_breakdown: [],
    users_by_goal: [],
    acquisition_sources: [],
    experience_levels: [],
    application_success: []
  });
  
  const COLORS = ['#0A66C2', '#4FACFE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8'];

  useEffect(() => {
    fetchStats();
  }, [filter]);

  const fetchStats = async () => {
    try {
      setLoading(true);
      const res = await api.get(`/dashboard/stats?filter=${filter}`);
      setStats(res.data);
    } catch (error) {
      showToast("Failed to load dashboard stats", "error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Dashboard Overview</h1>
          <p className="text-secondaryText">Here's what's happening for {filter.toLowerCase()}.</p>
        </div>
        <select 
          value={filter} 
          onChange={(e) => {
            const val = e.target.value;
            setFilter(val);
            localStorage.setItem('dashboard_filter', val);
          }}
          className="input-field w-48 bg-white cursor-pointer"
        >
          <option>Today</option>
          <option>Yesterday</option>
          <option>This Week</option>
          <option>This Month</option>
          <option>This Year</option>
          <option>All Time</option>
        </select>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard title="Total Students" value={loading ? '...' : stats.totals.users.toLocaleString()} icon={Users} color="text-primaryBrand" bg="bg-primaryBrand/10" />
        <StatCard title="Job Applications" value={loading ? '...' : stats.totals.job_applications.toLocaleString()} icon={Briefcase} color="text-highlight" bg="bg-highlight/10" />
        <StatCard title="Tests Taken" value={loading ? '...' : stats.totals.tests.toLocaleString()} icon={FileText} color="text-success" bg="bg-success/10" />
        <StatCard title="Appointments" value={loading ? '...' : stats.totals.appointments.toLocaleString()} icon={Calendar} color="text-[#F59E0B]" bg="bg-[#F59E0B]/10" />
      </div>

      <div className="card p-6 h-[420px] flex flex-col mb-8">
        <h2 className="text-lg font-semibold mb-6">
          Student Activity Trends ({['Today', 'Yesterday'].includes(filter) ? 'Last 7 Days' : filter})
        </h2>
        {loading ? (
          <div className="flex-1 flex items-center justify-center text-secondaryText">Loading chart data...</div>
        ) : (
          <div className="flex-1 min-h-0 pb-2 overflow-x-auto overflow-y-hidden">
            <div style={{ minWidth: stats.chart_data.length > 12 ? `${stats.chart_data.length * 60}px` : '100%', height: '100%' }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={stats.chart_data} margin={{ top: 5, right: 30, left: 20, bottom: 25 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E0E0E0" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} interval={0} tick={{ angle: -45, textAnchor: 'end', dy: 5, fontSize: 12 }} />
                  <YAxis allowDecimals={false} axisLine={false} tickLine={false} />
                  <Tooltip cursor={{fill: '#F3F2EF'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}/>
                  <Line type="monotone" dataKey="users" stroke="#0A66C2" strokeWidth={3} dot={{ r: 4 }} activeDot={{ r: 6 }} name="Signups" />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        )}
      </div>

      {/* Advanced Analytics Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6 mb-8">
        
        {/* Profile Completion (Bar Chart) */}
        <div className="card p-6 h-[420px] flex flex-col">
          <h2 className="text-lg font-semibold mb-2">Profile Completion</h2>
          {loading ? (
             <div className="flex-1 flex items-center justify-center text-secondaryText">Loading...</div>
          ) : (
             <ResponsiveContainer width="100%" height="100%">
                <BarChart data={stats.completion_breakdown} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                  <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                  <Tooltip cursor={{fill: '#f9fafb'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}/>
                  <Bar dataKey="value" fill="#4FACFE" radius={[4, 4, 0, 0]} name="Students" />
                </BarChart>
             </ResponsiveContainer>
          )}
        </div>

        {/* Top Goals (Bar Chart) */}
        <div className="card p-6 h-[420px] flex flex-col">
          <h2 className="text-lg font-semibold mb-2">Top 10 Career Goals</h2>
          {loading ? (
             <div className="flex-1 flex items-center justify-center text-secondaryText">Loading...</div>
          ) : (
             <ResponsiveContainer width="100%" height="100%">
                <BarChart layout="vertical" data={stats.users_by_goal} margin={{ top: 10, right: 20, left: 10, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#f0f0f0" />
                  <XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} />
                  <YAxis type="category" dataKey="name" width={120} axisLine={false} tickLine={false} tick={{ fontSize: 11 }} />
                  <Tooltip cursor={{fill: '#f9fafb'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}/>
                  <Bar dataKey="value" fill="#00C49F" radius={[0, 4, 4, 0]} name="Students" />
                </BarChart>
             </ResponsiveContainer>
          )}
        </div>

        {/* Acquisition Sources (Pie Chart) */}
        <div className="card p-6 h-[420px] flex flex-col">
          <h2 className="text-lg font-semibold mb-2">Acquisition Channels</h2>
          {loading ? (
             <div className="flex-1 flex items-center justify-center text-secondaryText">Loading...</div>
          ) : (
             <ResponsiveContainer width="100%" height="100%">
               <PieChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
                 <Pie data={stats.acquisition_sources} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={50} outerRadius={80} label>
                   {stats.acquisition_sources.map((_: any, index: number) => (
                     <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                   ))}
                 </Pie>
                 <Tooltip />
                 <Legend />
               </PieChart>
             </ResponsiveContainer>
          )}
        </div>

        {/* Experience Levels (Pie Chart) */}
        <div className="card p-6 h-[420px] flex flex-col">
          <h2 className="text-lg font-semibold mb-2">Experience Levels</h2>
          {loading ? (
             <div className="flex-1 flex items-center justify-center text-secondaryText">Loading...</div>
          ) : (
             <ResponsiveContainer width="100%" height="100%">
               <PieChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
                 <Pie data={stats.experience_levels} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                   {stats.experience_levels.map((_: any, index: number) => (
                     <Cell key={`cell-${index}`} fill={COLORS[(index + 3) % COLORS.length]} />
                   ))}
                 </Pie>
                 <Tooltip />
                 <Legend />
               </PieChart>
             </ResponsiveContainer>
          )}
        </div>

        {/* Application Success (Pie Chart) */}
        <div className="card p-6 h-[420px] flex flex-col">
          <h2 className="text-lg font-semibold mb-2">Job Application Success</h2>
          {loading ? (
             <div className="flex-1 flex items-center justify-center text-secondaryText">Loading...</div>
          ) : (
             <ResponsiveContainer width="100%" height="100%">
               <PieChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
                 <Pie data={stats.application_success} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={50} outerRadius={80} label>
                   {stats.application_success.map((_: any, index: number) => (
                     <Cell key={`cell-${index}`} fill={COLORS[(index + 2) % COLORS.length]} />
                   ))}
                 </Pie>
                 <Tooltip />
                 <Legend />
               </PieChart>
             </ResponsiveContainer>
          )}
        </div>

      </div>
    </div>
  );
};

const StatCard = ({ title, value, icon: Icon, color, bg }: any) => (
  <div className="card p-6 flex items-center gap-4 hover:shadow-md transition-shadow">
    <div className={`w-12 h-12 rounded-full flex items-center justify-center ${bg} ${color}`}>
      <Icon size={24} />
    </div>
    <div>
      <p className="text-sm font-medium text-secondaryText">{title}</p>
      <h3 className="text-2xl font-bold text-primaryText mt-1">{value}</h3>
    </div>
  </div>
);

export default Dashboard;
