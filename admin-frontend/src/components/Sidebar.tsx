import { Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Briefcase, FileText, UserSquare2, Tag, Bell, Users, LogOut, Image as ImageIcon } from 'lucide-react';

const Sidebar = () => {
  const location = useLocation();

  const menuItems = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
    { icon: ImageIcon, label: 'Banners', path: '/banners' },
    { icon: Briefcase, label: 'Jobs', path: '/jobs' },
    { icon: FileText, label: 'Tests', path: '/tests' },
    { icon: UserSquare2, label: 'Doctors', path: '/doctors' },
    { icon: Tag, label: 'Offers', path: '/offers' },
    { icon: Bell, label: 'Notifications', path: '/notifications' },
    { icon: Users, label: 'Users', path: '/users' },
  ];

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    window.location.href = '/login';
  };

  return (
    <div className="w-64 bg-white border-r border-border h-full flex flex-col shadow-sm">
      <div className="p-6 flex items-center gap-3">
        {/* Placeholder for Logo matching flutter app */}
        <div className="w-8 h-8 bg-primaryBrand rounded-md flex items-center justify-center text-white font-bold">C</div>
        <span className="text-xl font-bold text-primaryBrand">CareerSetu</span>
      </div>
      
      <nav className="flex-1 px-4 space-y-2 mt-4">
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.path}
              to={item.path}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                isActive 
                  ? 'bg-primaryBrand/10 text-primaryBrand font-medium' 
                  : 'text-secondaryText hover:bg-backgroundLight hover:text-primaryText'
              }`}
            >
              <item.icon size={20} />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t border-border">
        <button 
          onClick={handleLogout}
          className="flex items-center gap-3 px-4 py-3 w-full text-left text-error hover:bg-error/10 rounded-lg transition-colors"
        >
          <LogOut size={20} />
          <span>Logout</span>
        </button>
      </div>
    </div>
  );
};

export default Sidebar;
