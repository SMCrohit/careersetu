import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import api from '../api/axios';
import {
  Search, Eye, MapPin, Phone, Users as UsersIcon,
  Download, ChevronLeft, ChevronRight, FileText,
  FileSpreadsheet, FileDown, ChevronDown
} from 'lucide-react';
import { useToast } from '../context/ToastContext';
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

const PAGE_SIZE_OPTIONS = [10, 50, 100];

const Users = () => {
  const { showToast } = useToast();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
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

  // Filtered list
  const filtered = users.filter(
    (u) =>
      u.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      u.mobile_number?.includes(search) ||
      u.email?.toLowerCase().includes(search.toLowerCase()) ||
      u.city?.toLowerCase().includes(search.toLowerCase())
  );

  // Pagination
  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const safePage = Math.min(currentPage, totalPages);
  const paginated = filtered.slice((safePage - 1) * pageSize, safePage * pageSize);

  const handleSearchChange = (val: string) => {
    setSearch(val);
    setCurrentPage(1);
  };

  const handlePageSizeChange = (val: number) => {
    setPageSize(val);
    setCurrentPage(1);
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
  const exportRows = filtered.map((u, i) => ({
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
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${filtered.length} users`, 14, 22);

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

  // ─── Page number buttons ───────────────────────────────────────────────────
  const getPageNumbers = () => {
    const pages: (number | '...')[] = [];
    if (totalPages <= 7) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
      pages.push(1);
      if (safePage > 3) pages.push('...');
      for (let i = Math.max(2, safePage - 1); i <= Math.min(totalPages - 1, safePage + 1); i++) pages.push(i);
      if (safePage < totalPages - 2) pages.push('...');
      pages.push(totalPages);
    }
    return pages;
  };

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

      {/* ── Table Card ── */}
      <div className="card">
        {/* Toolbar */}
        <div className="p-4 border-b border-border flex flex-wrap justify-between items-center gap-3 bg-gray-50/50">
          <div className="relative w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input
              type="text"
              value={search}
              onChange={(e) => handleSearchChange(e.target.value)}
              placeholder="Search by name, phone, email, city…"
              className="input-field pl-10 bg-white w-full"
            />
          </div>
          <span className="text-sm font-medium text-secondaryText">
            {filtered.length} {filtered.length === 1 ? 'user' : 'users'}
          </span>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText bg-backgroundLight/50">
                <th className="p-4 font-semibold">#</th>
                <th className="p-4 font-semibold">Name</th>
                <th className="p-4 font-semibold">Contact</th>
                <th className="p-4 font-semibold">Location</th>
                <th className="p-4 font-semibold">Goal</th>
                <th className="p-4 font-semibold">Joined On</th>
                <th className="p-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={7} className="text-center p-12">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-4 border-primaryBrand border-t-transparent rounded-full animate-spin" />
                      <span className="text-secondaryText text-sm">Loading users…</span>
                    </div>
                  </td>
                </tr>
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center p-12">
                    <div className="flex flex-col items-center gap-3">
                      <UsersIcon size={36} className="text-border" />
                      <span className="text-secondaryText">No users found.</span>
                    </div>
                  </td>
                </tr>
              ) : (
                paginated.map((user, idx) => {
                  const rowNum = (safePage - 1) * pageSize + idx + 1;
                  return (
                    <tr key={user.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                      <td className="p-4 text-secondaryText text-sm">{rowNum}</td>
                      <td className="p-4">
                        <div className="flex items-center gap-2.5">
                          <div className="w-8 h-8 rounded-full bg-primaryBrand/10 flex items-center justify-center shrink-0 text-primaryBrand font-semibold text-sm">
                            {(user.full_name || '?')[0].toUpperCase()}
                          </div>
                          <span className="font-medium text-primaryText">{user.full_name || 'N/A'}</span>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col text-sm gap-0.5">
                          <span className="flex items-center gap-1 text-primaryText">
                            <Phone size={12} className="text-secondaryText" /> {user.mobile_number}
                          </span>
                          <span className="text-secondaryText text-xs">{user.email || 'No email'}</span>
                        </div>
                      </td>
                      <td className="p-4 text-secondaryText text-sm">
                        <span className="flex items-center gap-1">
                          <MapPin size={13} /> {user.city || 'Unknown'}
                        </span>
                      </td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 bg-highlight/10 text-highlight rounded-full text-xs font-medium">
                          {user.goal || 'Not set'}
                        </span>
                      </td>
                      <td className="p-4 text-secondaryText text-sm">{formatDate(user.created_datetime)}</td>
                      <td className="p-4 text-right">
                        <Link
                          to={`/users/${user.id}`}
                          className="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-primaryBrand border border-primaryBrand rounded-lg hover:bg-blue-50 transition-colors"
                        >
                          <Eye size={15} /> View
                        </Link>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* ── Pagination ── */}
        {!loading && filtered.length > 0 && (
          <div className="px-4 py-4 border-t border-border flex flex-wrap items-center justify-between gap-3 bg-gray-50/30">
            <p className="text-sm text-secondaryText">
              Showing{' '}
              <span className="font-semibold text-primaryText">
                {(safePage - 1) * pageSize + 1}–{Math.min(safePage * pageSize, filtered.length)}
              </span>{' '}
              of{' '}
              <span className="font-semibold text-primaryText">{filtered.length}</span> users
            </p>

            {/* Page size — centered */}
            <div className="flex items-center gap-2">
              <span className="text-sm text-secondaryText">Show</span>
              <select
                value={pageSize}
                onChange={(e) => handlePageSizeChange(Number(e.target.value))}
                className="px-3 py-1.5 rounded-lg border border-border bg-white text-sm text-primaryText focus:outline-none focus:ring-2 focus:ring-primaryBrand/30"
              >
                {PAGE_SIZE_OPTIONS.map((s) => (
                  <option key={s} value={s}>{s} items</option>
                ))}
              </select>
            </div>

            <div className="flex items-center gap-1.5">
              {/* Previous */}
              <button
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                disabled={safePage === 1}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-border text-sm font-medium text-secondaryText hover:bg-backgroundLight disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft size={16} /> Prev
              </button>

              {/* Page numbers */}
              {getPageNumbers().map((pg, i) =>
                pg === '...' ? (
                  <span key={`ellipsis-${i}`} className="px-2 text-secondaryText select-none">…</span>
                ) : (
                  <button
                    key={pg}
                    onClick={() => setCurrentPage(pg as number)}
                    className={`w-9 h-9 rounded-lg text-sm font-semibold transition-colors ${
                      pg === safePage
                        ? 'bg-primaryBrand text-white shadow-sm'
                        : 'border border-border text-secondaryText hover:bg-backgroundLight'
                    }`}
                  >
                    {pg}
                  </button>
                )
              )}

              {/* Next */}
              <button
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                disabled={safePage === totalPages}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-border text-sm font-medium text-secondaryText hover:bg-backgroundLight disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                Next <ChevronRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Users;
