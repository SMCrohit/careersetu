import { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Users, Briefcase, FileText, Calendar } from 'lucide-react';
import api from '../api/axios';
import { useToast } from '../context/ToastContext';

const Dashboard = () => {
  const { showToast } = useToast();
  const [filter, setFilter] = useState('This Week');
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totals: { users: 0, jobs: 0, tests: 0, appointments: 0 },
    chart_data: []
  });

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const res = await api.get('/dashboard/stats');
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
          onChange={(e) => setFilter(e.target.value)}
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
        <StatCard title="Total Users" value={loading ? '...' : stats.totals.users.toLocaleString()} icon={Users} color="text-primaryBrand" bg="bg-primaryBrand/10" />
        <StatCard title="Active Jobs" value={loading ? '...' : stats.totals.jobs.toLocaleString()} icon={Briefcase} color="text-highlight" bg="bg-highlight/10" />
        <StatCard title="Tests Taken" value={loading ? '...' : stats.totals.tests.toLocaleString()} icon={FileText} color="text-success" bg="bg-success/10" />
        <StatCard title="Appointments" value={loading ? '...' : stats.totals.appointments.toLocaleString()} icon={Calendar} color="text-[#F59E0B]" bg="bg-[#F59E0B]/10" />
      </div>

      <div className="card p-6 h-[400px]">
        <h2 className="text-lg font-semibold mb-6">Activity Trends (Last 7 Days)</h2>
        {loading ? (
          <div className="h-full flex items-center justify-center text-secondaryText">Loading chart data...</div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={stats.chart_data} margin={{ top: 5, right: 30, left: 20, bottom: 20 }}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E0E0E0" />
              <XAxis dataKey="name" axisLine={false} tickLine={false} />
              <YAxis allowDecimals={false} axisLine={false} tickLine={false} />
              <Tooltip cursor={{fill: '#F3F2EF'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}/>
              <Bar dataKey="users" fill="#0A66C2" radius={[4, 4, 0, 0]} />
              <Bar dataKey="jobs" fill="#4FACFE" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        )}
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
