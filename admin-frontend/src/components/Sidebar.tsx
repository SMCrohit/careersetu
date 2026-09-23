import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Briefcase, 
  FileText, 
  UserSquare2, 
  Tag, 
  Bell, 
  Users, 
  LogOut, 
  Image as ImageIcon,
  ChevronDown,
  ChevronRight
} from 'lucide-react';

type SubMenuItem = {
  label: string;
  path: string;
};

type MenuItem = {
  icon: any;
  label: string;
  path?: string;
  subItems?: SubMenuItem[];
};

const Sidebar = () => {
  const location = useLocation();
  const [expandedMenus, setExpandedMenus] = useState<string[]>([]);

  const menuItems: MenuItem[] = [
    { icon: LayoutDashboard, label: 'Dashboards', path: '/' },
    { icon: Users, label: 'Users', path: '/users' },
    { 
      icon: Briefcase, 
      label: 'Jobs',
      subItems: [
        { label: 'List', path: '/jobs' },
        { label: 'Applied', path: '/jobs/applied' },
      ]
    },
    { 
      icon: FileText, 
      label: 'Tests',
      subItems: [
        { label: 'List', path: '/tests' },
        { label: 'Attempted', path: '/tests/attempted' },
      ]
    },
    { 
      icon: UserSquare2, 
      label: 'Professionals',
      subItems: [
        { label: 'List', path: '/professionals' },
        { label: 'Appointments', path: '/appointments' },
        { label: 'Reviews', path: '/professionals/reviews' },
      ]
    },
    { 
      icon: Tag, 
      label: 'Offers',
      subItems: [
        { label: 'List', path: '/offers' },
        { label: 'Claimed', path: '/offers/claimed' },
      ]
    },
    { icon: ImageIcon, label: 'Banners', path: '/banners' },
    { icon: Bell, label: 'Notifications', path: '/notifications' },
  ];

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    window.location.href = '/login';
  };

  const toggleMenu = (label: string) => {
    setExpandedMenus(prev => 
      prev.includes(label) ? prev.filter(m => m !== label) : [...prev, label]
    );
  };

  const isPathActive = (path?: string, subItems?: SubMenuItem[]) => {
    if (path && location.pathname === path) return true;
    if (subItems && subItems.some(sub => location.pathname === sub.path)) return true;
    return false;
  };

  return (
    <div className="w-64 bg-white border-r border-border h-full flex flex-col shadow-sm">
      <div className="p-6 flex items-center gap-3">
        <div className="w-8 h-8 bg-primaryBrand rounded-md flex items-center justify-center text-white font-bold">C</div>
        <span className="text-xl font-bold text-primaryBrand">CareerSetu</span>
      </div>
      
      <nav className="flex-1 px-4 space-y-2 mt-4 overflow-y-auto">
        {menuItems.map((item) => {
          const isActive = isPathActive(item.path, item.subItems);
          const isExpanded = expandedMenus.includes(item.label) || isActive;

          return (
            <div key={item.label}>
              {item.subItems ? (
                <button
                  onClick={() => toggleMenu(item.label)}
                  className={`w-full flex items-center justify-between px-4 py-3 rounded-lg transition-colors ${
                    isActive 
                      ? 'bg-primaryBrand/10 text-primaryBrand font-medium' 
                      : 'text-secondaryText hover:bg-backgroundLight hover:text-primaryText'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <item.icon size={20} />
                    <span>{item.label}</span>
                  </div>
                  {isExpanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                </button>
              ) : (
                <Link
                  to={item.path!}
                  className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                    isActive 
                      ? 'bg-primaryBrand/10 text-primaryBrand font-medium' 
                      : 'text-secondaryText hover:bg-backgroundLight hover:text-primaryText'
                  }`}
                >
                  <item.icon size={20} />
                  <span>{item.label}</span>
                </Link>
              )}

              {/* Submenus */}
              {item.subItems && isExpanded && (
                <div className="ml-8 mt-1 space-y-1">
                  {item.subItems.map((sub) => {
                    const isSubActive = location.pathname === sub.path;
                    return (
                      <Link
                        key={sub.path}
                        to={sub.path}
                        className={`block px-4 py-2 text-sm rounded-lg transition-colors ${
                          isSubActive
                            ? 'text-primaryBrand font-medium bg-primaryBrand/5'
                            : 'text-secondaryText hover:bg-backgroundLight hover:text-primaryText'
                        }`}
                      >
                        {sub.label}
                      </Link>
                    );
                  })}
                </div>
              )}
            </div>
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
