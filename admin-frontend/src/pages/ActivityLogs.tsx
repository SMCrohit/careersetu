import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Activity } from 'lucide-react';

interface Log {
  id: string;
  admin_id: string;
  action: string;
  module_name: string;
  record_id: string;
  created_datetime: string;
  details: any;
}

const ActivityLogs = () => {
  const [logs, setLogs] = useState<Log[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    try {
      const response = await api.get('/logs');
      setLogs(response.data);
    } catch (error) {
      console.error('Error fetching logs:', error);
    } finally {
      setLoading(false);
    }
  };

  const getActionColor = (action: string) => {
    switch (action.toUpperCase()) {
      case 'CREATE': return 'bg-green-100 text-green-800';
      case 'UPDATE': return 'bg-blue-100 text-blue-800';
      case 'DELETE': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-primaryText">Activity Logs</h1>
      </div>

      <div className="card p-0">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-surfaceDark border-b border-borderLight">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-secondaryText uppercase tracking-wider">Date & Time</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-secondaryText uppercase tracking-wider">Admin</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-secondaryText uppercase tracking-wider">Action</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-secondaryText uppercase tracking-wider">Module</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-secondaryText uppercase tracking-wider">Record ID</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-borderLight">
              {loading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-4 text-center text-secondaryText">Loading...</td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-4 text-center text-secondaryText">No activity logs found</td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-surfaceDark/50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-secondaryText">
                      {new Date(log.created_datetime).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center text-sm font-medium text-primaryText">
                        <Activity size={16} className="text-primaryBrand mr-2" />
                        {log.admin_id}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${getActionColor(log.action)}`}>
                        {log.action}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-primaryText">
                      {log.module_name}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-secondaryText font-mono">
                      {log.record_id}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default ActivityLogs;
