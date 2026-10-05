import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import api from '../api/axios';
import {
  Eye, MapPin, Phone, Users as UsersIcon,
  Download, FileText, FileSpreadsheet, FileDown, ChevronDown
} from 'lucide-react';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

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
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchUsers();
  }, []);

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

  const fetchUsers = async () => {
    try {
      const res = await api.get('/users');
      setUsers(res.data);
    } catch {
      showToast('Failed to fetch users', 'error');
    } finally {
      setLoading(false);
    }
  };

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
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${users.length} users`, 14, 22);

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

  const columns: Column<User>[] = [
    {
      header: 'Name',
      accessorKey: 'full_name',
      sortable: true,
      cell: (user) => (
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-full bg-primaryBrand/10 flex items-center justify-center shrink-0 text-primaryBrand font-semibold text-sm">
            {(user.full_name || '?')[0].toUpperCase()}
          </div>
          <span className="font-medium text-primaryText">{user.full_name || 'N/A'}</span>
        </div>
      )
    },
    {
      header: 'Contact',
      accessorKey: 'mobile_number',
      sortable: true,
      cell: (user) => (
        <div className="flex flex-col text-sm gap-0.5">
          <span className="flex items-center gap-1 text-primaryText">
            <Phone size={12} className="text-secondaryText" /> {user.mobile_number}
          </span>
          <span className="text-secondaryText text-xs">{user.email || 'No email'}</span>
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
      accessorKey: 'goal',
      sortable: true,
      cell: (user) => (
        <span className="px-2.5 py-1 bg-highlight/10 text-highlight rounded-full text-xs font-medium">
          {user.goal || 'Not set'}
        </span>
      )
    },
    {
      header: 'Joined On',
      accessorKey: 'created_datetime',
      sortable: true,
      cell: (user) => <span className="text-secondaryText text-sm">{formatDate(user.created_datetime)}</span>
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
      />
    </div>
  );
};

export default Users;
