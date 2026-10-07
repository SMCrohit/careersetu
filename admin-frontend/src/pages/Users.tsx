import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import api from '../api/axios';
import {
  Eye, MapPin, Phone, Users as UsersIcon, Filter, X,
  Download, FileText, FileSpreadsheet, FileDown, ChevronDown
} from 'lucide-react';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';


const Users = () => {
  const { showToast } = useToast();
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Pagination & Search
  const [serverTotal, setServerTotal] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [currentLimit, setCurrentLimit] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Filters
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [availableGoals, setAvailableGoals] = useState<any[]>([]);
  const [educationOptions, setEducationOptions] = useState<string[]>([]);
  const [filters, setFilters] = useState({
    city: '',
    goal_id: '',
    education: '',
    joined_start: '',
    joined_end: '',
    min_profile_score: ''
  });
  
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (exportRef.current && !exportRef.current.contains(e.target as Node)) {
        setExportOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [goalsRes, eduRes] = await Promise.all([
          api.get('/goals'),
          api.get('/users/filters/education')
        ]);
        setAvailableGoals(goalsRes.data);
        setEducationOptions(eduRes.data);
      } catch (err) {
        console.error("Failed to fetch filter options", err);
      }
    };
    fetchData();
    fetchUsersWithParams(filters, 1, '', 10);
  }, []);

  const fetchUsersWithParams = async (overrideFilters: any = null, page: number = currentPage, search: string = searchTerm, limit: number = currentLimit) => {
    setLoading(true);
    try {
      const current = overrideFilters || filters;
      const params = new URLSearchParams();
      if(current.city) params.append('city', current.city);
      if(current.goal_id) params.append('goal_id', current.goal_id);
      if(current.education) params.append('education', current.education);
      if(current.joined_start) params.append('joined_start', current.joined_start);
      if(current.joined_end) params.append('joined_end', current.joined_end);
      if(current.min_profile_score) params.append('min_profile_score', current.min_profile_score);
      
      params.append('page', page.toString());
      params.append('limit', limit.toString());
      if (search) params.append('search', search);
      
      const res = await api.get(`/users?${params.toString()}`);
      setUsers(res.data.data);
      setServerTotal(res.data.total);
    } catch {
      showToast('Failed to fetch users', 'error');
    } finally {
      setLoading(false);
    }
  };

  // Close export dropdown when clicking outside
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (exportRef.current && !exportRef.current.contains(e.target as Node)) {
        setExportOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  

  const formatDate = (iso: string) =>
    iso
      ? new Date(iso).toLocaleDateString('en-IN', {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
        })
      : '—';

  // ─── Export helpers ────────────────────────────────────────────────────────
  const exportRows = users.map((u, i) => ({
    '#': i + 1,
    Name: u.full_name || '—',
    Mobile: u.mobile_number || '—',
    Email: u.email || '—',
    City: u.city || '—',
    Goal: u.goal || '—',
    'Joined On': formatDate(u.created_datetime),
  }));

  const exportToCSV = () => {
    const headers = Object.keys(exportRows[0] || {});
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'users.csv';
    a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Users');
    XLSX.writeFile(wb, 'users.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Users Directory', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${serverTotal} users`, 14, 22);

    autoTable(doc, {
      startY: 28,
      head: [['#', 'Name', 'Mobile', 'Email', 'City', 'Goal', 'Joined On']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });

    doc.save('users.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const columns: Column<any>[] = [
    {
      header: 'Name',
      accessorKey: 'full_name',
      sortable: true,
      cell: (user) => (
        <div className="flex items-center gap-2.5" title={user.full_name || 'N/A'}>
          {user.profile_image_url ? (
            <img src={user.profile_image_url} alt={user.full_name} className="w-8 h-8 rounded-full object-cover shrink-0" />
          ) : (
            <div className="w-8 h-8 rounded-full bg-primaryBrand/10 flex items-center justify-center shrink-0 text-primaryBrand font-semibold text-sm">
              {(user.full_name || '?')[0].toUpperCase()}
            </div>
          )}
          <span className="font-medium text-primaryText whitespace-nowrap">
            {user.full_name && user.full_name.length > 50 ? user.full_name.substring(0, 50) + '...' : (user.full_name || 'N/A')}
          </span>
        </div>
      )
    },
    {
      header: 'Contact',
      accessorKey: 'mobile_number',
      sortable: true,
      cell: (user) => (
        <div className="flex flex-col text-sm gap-0.5" title={user.email || 'No email'}>
          <span className="flex items-center gap-1 text-primaryText whitespace-nowrap">
            <Phone size={12} className="text-secondaryText" /> {user.mobile_number}
          </span>
          <span className="text-secondaryText text-xs whitespace-nowrap">
            {user.email && user.email.length > 50 ? user.email.substring(0, 50) + '...' : (user.email || 'No email')}
          </span>
        </div>
      )
    },
    {
      header: 'Location',
      accessorKey: 'city',
      sortable: true,
      cell: (user) => (
        <span className="flex items-center gap-1 text-secondaryText text-sm">
          <MapPin size={13} /> {user.city || 'Unknown'}
        </span>
      )
    },
    {
      header: 'Goal',
      accessorKey: 'goal.name',
      sortable: true,
      cell: (user: any) => (
        <span className="px-2.5 py-1 bg-highlight/10 text-highlight rounded-full text-xs font-medium whitespace-nowrap">
          {user.goal?.name || 'Not set'}
        </span>
      )
    },
    {
      header: 'Highest Education',
      accessorKey: 'education_history',
      sortable: false,
      cell: (user: any) => {
        const edu = user.education_history;
        if (!edu || edu.length === 0) return <span className="text-secondaryText text-sm">Not provided</span>;
        // Assuming latest education is the first one or we just pick the first one
        const latestEdu = edu[0].degree || 'Unknown Degree';
        return <span className="text-sm font-medium text-primaryText whitespace-nowrap max-w-[150px] truncate block" title={latestEdu}>{latestEdu}</span>;
      }
    },
    { 
      header: 'Experience', 
      accessorKey: 'experience_years', 
      sortable: true, 
      cell: (u: any) => <span className="whitespace-nowrap">{u.experience_years == null ? 'Not mentioned' : `${u.experience_years} yrs`}</span>
    },
    { 
      header: 'Profile %', 
      accessorKey: 'profile_score', 
      sortable: true,
      cell: (u: any) => {
        const score = u.profile_score || 0;
        return (
          <div className="flex items-center gap-2 whitespace-nowrap">
            <div className="w-16 h-2 bg-gray-100 rounded-full overflow-hidden">
              <div className={`h-full ${score >= 80 ? 'bg-green-500' : score >= 50 ? 'bg-orange-400' : 'bg-red-400'}`} style={{ width: `${score}%` }}></div>
            </div>
            <span className="text-xs text-secondaryText">{score}%</span>
          </div>
        );
      }
    },
    {
      header: 'Joined On',
      accessorKey: 'created_datetime',
      sortable: true,
      cell: (user) => <span className="text-secondaryText text-sm whitespace-nowrap">{formatDate(user.created_datetime)}</span>
    },
    {
      header: 'Actions',
      cell: (user) => (
        <div className="text-right">
          <Link
            to={`/users/${user.id}`}
            className="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-primaryBrand border border-primaryBrand rounded-lg hover:bg-blue-50 transition-colors"
          >
            <Eye size={15} /> View
          </Link>
        </div>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
      {/* ── Header ── */}
      <div className="flex flex-wrap items-center justify-between gap-4 mb-8">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primaryBrand/10 rounded-xl flex items-center justify-center">
            <UsersIcon size={20} className="text-primaryBrand" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-primaryText">Users Directory</h1>
            <p className="text-sm text-secondaryText">Manage and view profiles for all registered students.</p>
          </div>
        </div>

        {/* Export Button */}
        <div className="relative" ref={exportRef}>
          <button
            onClick={() => setExportOpen((o) => !o)}
            className="flex items-center gap-2 px-4 py-2.5 bg-primaryBrand text-white rounded-xl text-sm font-semibold hover:bg-primaryBrand/90 transition-colors shadow-sm"
          >
            <Download size={16} />
            Export
            <ChevronDown size={14} className={`transition-transform ${exportOpen ? 'rotate-180' : ''}`} />
          </button>

          {exportOpen && (
            <div className="absolute right-0 mt-2 w-48 bg-white border border-border rounded-xl shadow-lg z-50 overflow-hidden animate-fade-in">
              <button
                onClick={exportToPDF}
                className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors"
              >
                <FileText size={16} className="text-red-500" />
                Export as PDF
              </button>
              <button
                onClick={exportToExcel}
                className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors border-t border-border"
              >
                <FileSpreadsheet size={16} className="text-green-600" />
                Export as Excel
              </button>
              <button
                onClick={exportToCSV}
                className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors border-t border-border"
              >
                <FileDown size={16} className="text-blue-500" />
                Export as CSV
              </button>
            </div>
          )}
        </div>
      </div>

      <DataTable
        data={users}
        columns={columns}
        searchPlaceholder="Search by name, phone, email, city…"
        searchableKeys={['full_name', 'mobile_number', 'email', 'city']}
        loading={loading}
        emptyStateMessage="No users found."
        emptyStateIcon={<UsersIcon size={36} className="text-border" />}
        serverSideMode={true}
        serverSideTotal={serverTotal}
        serverSidePage={currentPage}
        onPageChange={(page) => {
          setCurrentPage(page);
          fetchUsersWithParams(null, page, searchTerm, currentLimit);
        }}
        onSearchChange={(s) => {
          setSearchTerm(s);
          setCurrentPage(1);
          fetchUsersWithParams(null, 1, s, currentLimit);
        }}
        onPageSizeChange={(size) => {
          setCurrentLimit(size);
          setCurrentPage(1);
          fetchUsersWithParams(null, 1, searchTerm, size);
        }}
        toolbarExtras={
          <button onClick={() => setIsFilterOpen(true)} className="flex items-center gap-2 px-3 py-1.5 border border-border rounded-lg text-sm font-medium hover:bg-gray-50 transition-colors bg-white shrink-0 h-[38px]">
            <Filter size={16} /> 
            Filters {Object.values(filters).filter(v => v !== '').length > 0 && <span className="w-5 h-5 bg-primaryBrand text-white text-[10px] flex items-center justify-center rounded-full">{Object.values(filters).filter(v => v !== '').length}</span>}
          </button>
        }

      />

      {/* Filter Modal */}
      {isFilterOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="absolute inset-0 bg-black/20" onClick={() => setIsFilterOpen(false)}></div>
          <div className="relative w-96 bg-white h-full shadow-2xl flex flex-col animate-slide-in-right">
            <div className="p-6 border-b border-border flex justify-between items-center">
              <h2 className="text-lg font-bold text-primaryText">Advanced Filters</h2>
              <button onClick={() => setIsFilterOpen(false)} className="text-gray-400 hover:text-gray-600"><X size={20}/></button>
            </div>
            <div className="p-6 flex-1 overflow-y-auto space-y-6">
              
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">City (Partial Match)</label>
                <input
                  type="text"
                  placeholder="e.g. Pune, Bang"
                  value={filters.city}
                  onChange={(e) => setFilters({ ...filters, city: e.target.value })}
                  className="input-field bg-white w-full px-3 py-2 border border-border rounded-lg"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Career Goal</label>
                <select 
                  className="input-field bg-white w-full px-3 py-2 border border-border rounded-lg" 
                  value={filters.goal_id} 
                  onChange={e => setFilters({...filters, goal_id: e.target.value})}
                >
                  <option value="">All Goals</option>
                  {availableGoals.map(g => (
                    <option key={g.id} value={g.id}>{g.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Highest Education</label>
                <select 
                  className="input-field bg-white w-full px-3 py-2 border border-border rounded-lg" 
                  value={filters.education} 
                  onChange={e => setFilters({...filters, education: e.target.value})}
                >
                  <option value="">All Educations</option>
                  {educationOptions.map((edu, idx) => (
                    <option key={idx} value={edu}>{edu}</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-2">Joined From</label>
                  <input
                    type="date"
                    value={filters.joined_start}
                    onChange={(e) => setFilters({ ...filters, joined_start: e.target.value })}
                    className="input-field bg-white px-2 w-full py-2 border border-border rounded-lg"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-2">Joined To</label>
                  <input
                    type="date"
                    value={filters.joined_end}
                    onChange={(e) => setFilters({ ...filters, joined_end: e.target.value })}
                    className="input-field bg-white px-2 w-full py-2 border border-border rounded-lg"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Minimum Profile Score (%)</label>
                <input
                  type="number"
                  placeholder="e.g. 80"
                  value={filters.min_profile_score}
                  onChange={(e) => setFilters({ ...filters, min_profile_score: e.target.value })}
                  className="input-field bg-white w-full px-3 py-2 border border-border rounded-lg"
                />
              </div>

            </div>
            <div className="p-6 border-t border-border flex gap-3">
              <button onClick={() => {
                const empty = {city: '', goal_id: '', education: '', joined_start: '', joined_end: '', min_profile_score: ''};
                setFilters(empty);
                setCurrentPage(1);
                fetchUsersWithParams(empty, 1, searchTerm, currentLimit);
              }} className="flex-1 py-2 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200">Clear All</button>
              <button onClick={() => {
                setIsFilterOpen(false);
                setCurrentPage(1);
                fetchUsersWithParams(filters, 1, searchTerm, currentLimit);
              }} className="flex-1 py-2 bg-primaryBrand text-white rounded-xl font-medium hover:bg-blue-700">Apply Filters</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Users;
