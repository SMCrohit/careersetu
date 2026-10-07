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
  ChevronDown,
  ChevronRight,
  Settings as SettingsIcon
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
  const [menuStates, setMenuStates] = useState<Record<string, boolean>>({});
  const [isHovered, setIsHovered] = useState(false);

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
    { icon: Bell, label: 'Notifications', path: '/notifications' },
    { icon: SettingsIcon, label: 'Settings', path: '/settings' },
  ];

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    window.location.href = '/login';
  };

  const isPathActive = (path?: string, subItems?: SubMenuItem[]) => {
    if (path && location.pathname === path) return true;
    if (subItems && subItems.some(sub => location.pathname === sub.path)) return true;
    return false;
  };

  const toggleMenu = (label: string, isActive: boolean) => {
    setMenuStates(prev => {
      const currentState = prev[label] !== undefined ? prev[label] : isActive;
      return { ...prev, [label]: !currentState };
    });
  };

  return (
    <div
      className="relative h-full flex flex-col bg-white border-r border-border shadow-sm"
      style={{
        width: isHovered ? '256px' : '64px',
        minWidth: isHovered ? '256px' : '64px',
        transition: 'width 0.25s cubic-bezier(0.4,0,0.2,1), min-width 0.25s cubic-bezier(0.4,0,0.2,1)',
        overflow: 'hidden',
        zIndex: 40,
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {/* Logo */}
      <div
        className="flex items-center gap-3 overflow-hidden"
        style={{
          padding: isHovered ? '24px' : '16px',
          transition: 'padding 0.25s ease',
          minHeight: '72px',
          whiteSpace: 'nowrap',
        }}
      >
        <div
          className="flex-shrink-0 w-8 h-8 bg-primaryBrand rounded-md flex items-center justify-center text-white font-bold text-sm"
        >
          C
        </div>
        <span
          className="text-xl font-bold text-primaryBrand overflow-hidden"
          style={{
            opacity: isHovered ? 1 : 0,
            maxWidth: isHovered ? '160px' : '0px',
            transition: 'opacity 0.2s ease, max-width 0.25s ease',
            whiteSpace: 'nowrap',
          }}
        >
          CareerSetu
        </span>
      </div>

      {/* Nav */}
      <nav
        className="flex-1 space-y-1 mt-2 overflow-y-auto overflow-x-hidden"
        style={{ padding: isHovered ? '0 12px' : '0 8px', transition: 'padding 0.25s ease' }}
      >
        {menuItems.map((item) => {
          const isActive = isPathActive(item.path, item.subItems);
          const isExpanded = isHovered && (menuStates[item.label] !== undefined ? menuStates[item.label] : isActive);

          return (
            <div key={item.label}>
              {item.subItems ? (
                <button
                  onClick={() => isHovered && toggleMenu(item.label, isActive)}
                  title={!isHovered ? item.label : undefined}
                  className={`w-full flex items-center rounded-lg transition-colors ${
                    isActive
                      ? 'bg-primaryBrand/10 text-primaryBrand font-medium'
                      : 'text-secondaryText hover:bg-backgroundLight hover:text-primaryText'
                  }`}
                  style={{
                    padding: isHovered ? '10px 12px' : '10px',
                    justifyContent: isHovered ? 'space-between' : 'center',
                    transition: 'padding 0.25s ease, justify-content 0.25s ease',
                  }}
                >
                  <div className="flex items-center gap-3">
                    <item.icon size={20} className="flex-shrink-0" />
                    <span
                      className="overflow-hidden whitespace-nowrap"
                      style={{
                        opacity: isHovered ? 1 : 0,
                        maxWidth: isHovered ? '140px' : '0px',
                        transition: 'opacity 0.2s ease, max-width 0.25s ease',
                      }}
                    >
                      {item.label}
                    </span>
                  </div>
                  {isHovered && (
                    <span style={{ opacity: isHovered ? 1 : 0, transition: 'opacity 0.2s ease' }}>
                      {isExpanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                    </span>
                  )}
                </button>
              ) : (
                <Link
                  to={item.path!}
                  title={!isHovered ? item.label : undefined}
                  className={`flex items-center gap-3 rounded-lg transition-colors ${
                    isActive
                      ? 'bg-primaryBrand/10 text-primaryBrand font-medium'
                      : 'text-secondaryText hover:bg-backgroundLight hover:text-primaryText'
                  }`}
                  style={{
                    padding: isHovered ? '10px 12px' : '10px',
                    justifyContent: isHovered ? 'flex-start' : 'center',
                    transition: 'padding 0.25s ease',
                  }}
                >
                  <item.icon size={20} className="flex-shrink-0" />
                  <span
                    className="overflow-hidden whitespace-nowrap"
                    style={{
                      opacity: isHovered ? 1 : 0,
                      maxWidth: isHovered ? '160px' : '0px',
                      transition: 'opacity 0.2s ease, max-width 0.25s ease',
                    }}
                  >
                    {item.label}
                  </span>
                </Link>
              )}

              {/* Submenus */}
              {item.subItems && (
                <div
                  style={{
                    maxHeight: isExpanded ? `${item.subItems.length * 44}px` : '0px',
                    overflow: 'hidden',
                    transition: 'max-height 0.25s cubic-bezier(0.4,0,0.2,1)',
                  }}
                >
                  <div className="ml-8 mt-1 space-y-1 pb-1">
                    {item.subItems.map((sub) => {
                      const isSubActive = location.pathname === sub.path;
                      return (
                        <Link
                          key={sub.path}
                          to={sub.path}
                          className={`block px-4 py-2 text-sm rounded-lg transition-colors whitespace-nowrap ${
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
                </div>
              )}
            </div>
          );
        })}
      </nav>

      {/* Logout */}
      <div
        className="border-t border-border"
        style={{ padding: isHovered ? '12px' : '8px', transition: 'padding 0.25s ease' }}
      >
        <button
          onClick={handleLogout}
          title={!isHovered ? 'Logout' : undefined}
          className="flex items-center gap-3 w-full text-left text-error hover:bg-error/10 rounded-lg transition-colors"
          style={{
            padding: isHovered ? '10px 12px' : '10px',
            justifyContent: isHovered ? 'flex-start' : 'center',
            transition: 'padding 0.25s ease',
          }}
        >
          <LogOut size={20} className="flex-shrink-0" />
          <span
            className="overflow-hidden whitespace-nowrap"
            style={{
              opacity: isHovered ? 1 : 0,
              maxWidth: isHovered ? '120px' : '0px',
              transition: 'opacity 0.2s ease, max-width 0.25s ease',
            }}
          >
            Logout
          </span>
        </button>
      </div>
    </div>
  );
};

export default Sidebar;
