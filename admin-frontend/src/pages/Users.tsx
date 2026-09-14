import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../api/axios';
import { Search, Eye, MapPin, Phone } from 'lucide-react';
import { useToast } from '../context/ToastContext';

interface User {
  id: string;
  full_name: string;
  mobile_number: string;
  email: string;
  city: string;
  goal: string;
  created_datetime: string;
}

const Users = () => {
  const { showToast } = useToast();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const res = await api.get('/users');
      setUsers(res.data);
    } catch (error) {
      showToast("Failed to fetch users", "error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Users Directory</h1>
          <p className="text-secondaryText">Manage and view profiles for all registered students.</p>
        </div>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex justify-between items-center bg-gray-50/50">
          <div className="relative w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input type="text" placeholder="Search users by name or phone..." className="input-field pl-10 bg-white" />
          </div>
          <div className="text-sm font-medium text-secondaryText">
            Total Users: {users.length}
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium">Name</th>
                <th className="p-4 font-medium">Contact</th>
                <th className="p-4 font-medium">Location</th>
                <th className="p-4 font-medium">Goal</th>
                <th className="p-4 font-medium">Joined On</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} className="text-center p-8 text-secondaryText">Loading users...</td></tr>
              ) : users.length === 0 ? (
                <tr><td colSpan={6} className="text-center p-8 text-secondaryText">No users found.</td></tr>
              ) : (
                users.map((user) => (
                  <tr key={user.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4 font-medium text-primaryText">{user.full_name || 'N/A'}</td>
                    <td className="p-4">
                      <div className="flex flex-col text-sm">
                        <span className="flex items-center gap-1 text-primaryText"><Phone size={12}/> {user.mobile_number}</span>
                        <span className="text-secondaryText">{user.email || 'No email'}</span>
                      </div>
                    </td>
                    <td className="p-4 text-secondaryText flex items-center gap-1">
                      <MapPin size={14} /> {user.city || 'Unknown'}
                    </td>
                    <td className="p-4"><span className="px-2.5 py-1 bg-highlight/10 text-highlight rounded-full text-xs font-medium">{user.goal || 'Not set'}</span></td>
                    <td className="p-4 text-secondaryText text-sm">
                      {new Date(user.created_datetime).toLocaleDateString()}
                    </td>
                    <td className="p-4 text-right">
                      <Link to={`/users/${user.id}`} className="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-primaryBrand border border-primaryBrand rounded-md hover:bg-blue-50 transition-colors">
                        <Eye size={16} /> View Profile
                      </Link>
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

export default Users;
