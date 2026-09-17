import { useEffect, useState, useRef } from 'react';
import api from '../api/axios';
import {
  Briefcase, Search, MapPin, Building2, Calendar, Filter,
  Download, ChevronDown, ChevronLeft, ChevronRight,
  FileText, FileSpreadsheet, FileDown
} from 'lucide-react';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useToast } from '../context/ToastContext';

type JobApplication = {
  id: string;
  status: string;
  applied_at: string;
  user: {
    id: string;
    full_name: string;
    mobile_number: string;
    city: string;
  } | null;
  job: {
    id: string;
    title: string;
    company: string;
    location: string;
    type: string;
  } | null;
};

const statusColors: Record<string, string> = {
  applied: 'bg-blue-100 text-blue-700',
  shortlisted: 'bg-yellow-100 text-yellow-700',
  rejected: 'bg-red-100 text-red-700',
  selected: 'bg-green-100 text-green-700',
};

const PAGE_SIZE_OPTIONS = [10, 50, 100];

const AppliedJobs = () => {
  const { showToast } = useToast();
  const [applications, setApplications] = useState<JobApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const fetchApplications = async () => {
      try {
        const { data } = await api.get('/admin/job-applications');
        setApplications(data);
      } catch {
        setError('Failed to load job applications.');
      } finally {
        setLoading(false);
      }
    };
    fetchApplications();
  }, []);

  // Close export dropdown on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (exportRef.current && !exportRef.current.contains(e.target as Node)) {
        setExportOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  // ── Filtering ──────────────────────────────────────────────────────────────
  const filtered = applications.filter((app) => {
    const matchSearch =
      app.user?.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      app.job?.title?.toLowerCase().includes(search.toLowerCase()) ||
      app.job?.company?.toLowerCase().includes(search.toLowerCase()) ||
      app.user?.mobile_number?.includes(search);
    const matchStatus = statusFilter === 'all' || app.status === statusFilter;
    return matchSearch && matchStatus;
  });

  // ── Pagination ─────────────────────────────────────────────────────────────
  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const safePage = Math.min(currentPage, totalPages);
  const paginated = filtered.slice((safePage - 1) * pageSize, safePage * pageSize);

  const handleSearchChange = (val: string) => { setSearch(val); setCurrentPage(1); };
  const handleStatusChange = (val: string) => { setStatusFilter(val); setCurrentPage(1); };
  const handlePageSizeChange = (val: number) => { setPageSize(val); setCurrentPage(1); };

  const formatDate = (iso: string) =>
    iso ? new Date(iso).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—';

  const uniqueStatuses = ['all', ...Array.from(new Set(applications.map((a) => a.status).filter(Boolean)))];

  // ── Export helpers ─────────────────────────────────────────────────────────
  const exportRows = filtered.map((app, i) => ({
    '#': i + 1,
    'Applicant Name': app.user?.full_name || '—',
    'Mobile': app.user?.mobile_number || '—',
    'City': app.user?.city || '—',
    'Job Title': app.job?.title || '—',
    'Company': app.job?.company || '—',
    'Location': app.job?.location || '—',
    'Type': app.job?.type || '—',
    'Status': app.status || '—',
    'Applied On': formatDate(app.applied_at),
  }));

  const exportToCSV = () => {
    const headers = Object.keys(exportRows[0] || {});
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'applied_jobs.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Applied Jobs');
    XLSX.writeFile(wb, 'applied_jobs.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Applied Jobs', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${filtered.length} applications`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'Applicant', 'Mobile', 'City', 'Job Title', 'Company', 'Location', 'Type', 'Status', 'Applied On']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 7.5, cellPadding: 2.5 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('applied_jobs.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  // ── Page numbers ───────────────────────────────────────────────────────────
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
    <div>
      {/* ── Header ── */}
      <div className="flex flex-wrap items-center justify-between gap-4 mb-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primaryBrand/10 rounded-xl flex items-center justify-center">
            <Briefcase className="text-primaryBrand" size={20} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-primaryText">Applied Jobs</h1>
            <p className="text-sm text-secondaryText">All job applications across the platform</p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
            {filtered.length} Applications
          </div>

          {/* Export */}
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
                <button onClick={exportToPDF} className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors">
                  <FileText size={16} className="text-red-500" /> Export as PDF
                </button>
                <button onClick={exportToExcel} className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors border-t border-border">
                  <FileSpreadsheet size={16} className="text-green-600" /> Export as Excel
                </button>
                <button onClick={exportToCSV} className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors border-t border-border">
                  <FileDown size={16} className="text-blue-500" /> Export as CSV
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ── Filters ── */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-secondaryText" />
          <input
            type="text"
            placeholder="Search by user, job or company..."
            value={search}
            onChange={(e) => handleSearchChange(e.target.value)}
            className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-border bg-white text-sm text-primaryText focus:outline-none focus:ring-2 focus:ring-primaryBrand/30"
          />
        </div>
        <div className="flex items-center gap-3">
          <div className="relative">
            <Filter size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-secondaryText" />
            <select
              value={statusFilter}
              onChange={(e) => handleStatusChange(e.target.value)}
              className="pl-8 pr-4 py-2.5 rounded-xl border border-border bg-white text-sm text-primaryText focus:outline-none focus:ring-2 focus:ring-primaryBrand/30"
            >
              {uniqueStatuses.map((s) => (
                <option key={s} value={s}>{s === 'all' ? 'All Statuses' : s.charAt(0).toUpperCase() + s.slice(1)}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* ── Content ── */}
      {loading ? (
        <div className="flex flex-col items-center justify-center py-20 gap-3">
          <div className="w-8 h-8 border-4 border-primaryBrand border-t-transparent rounded-full animate-spin" />
          <span className="text-secondaryText text-sm">Loading applications…</span>
        </div>
      ) : error ? (
        <div className="bg-red-50 text-red-600 p-6 rounded-xl border border-red-200 text-center">{error}</div>
      ) : filtered.length === 0 ? (
        <div className="bg-white rounded-xl border border-border p-16 flex flex-col items-center justify-center text-center">
          <Briefcase size={40} className="text-border mb-3" />
          <p className="text-primaryText font-medium">No applications found</p>
          <p className="text-secondaryText text-sm mt-1">Try changing your search or filter.</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-border overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-backgroundLight border-b border-border">
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">#</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Applicant</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Job</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Company</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Type</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Status</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Applied On</th>
                </tr>
              </thead>
              <tbody>
                {paginated.map((app, idx) => {
                  const rowNum = (safePage - 1) * pageSize + idx + 1;
                  return (
                    <tr key={app.id} className="border-b border-border last:border-0 hover:bg-backgroundLight/50 transition-colors">
                      <td className="px-5 py-4 text-secondaryText">{rowNum}</td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2.5">
                          <div className="w-8 h-8 rounded-full bg-primaryBrand/10 flex items-center justify-center shrink-0 text-primaryBrand font-semibold text-sm">
                            {(app.user?.full_name || '?')[0].toUpperCase()}
                          </div>
                          <div>
                            <p className="font-medium text-primaryText">{app.user?.full_name || '—'}</p>
                            <p className="text-xs text-secondaryText flex items-center gap-1">
                              <MapPin size={10} />
                              {app.user?.city || '—'} &middot; {app.user?.mobile_number || '—'}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4">
                        <p className="font-medium text-primaryText">{app.job?.title || '—'}</p>
                        <p className="text-xs text-secondaryText flex items-center gap-1">
                          <MapPin size={10} /> {app.job?.location || '—'}
                        </p>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-1.5 text-primaryText">
                          <Building2 size={14} className="text-secondaryText" />
                          {app.job?.company || '—'}
                        </div>
                      </td>
                      <td className="px-5 py-4">
                        <span className="px-2 py-1 rounded-md bg-backgroundLight text-secondaryText text-xs font-medium">
                          {app.job?.type || '—'}
                        </span>
                      </td>
                      <td className="px-5 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold capitalize ${statusColors[app.status] || 'bg-gray-100 text-gray-600'}`}>
                          {app.status || '—'}
                        </span>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-1.5 text-secondaryText text-xs">
                          <Calendar size={12} />
                          {formatDate(app.applied_at)}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* ── Pagination ── */}
          <div className="px-5 py-4 border-t border-border flex flex-wrap items-center justify-between gap-3 bg-gray-50/30">
            <p className="text-sm text-secondaryText">
              Showing{' '}
              <span className="font-semibold text-primaryText">
                {(safePage - 1) * pageSize + 1}–{Math.min(safePage * pageSize, filtered.length)}
              </span>{' '}
              of{' '}
              <span className="font-semibold text-primaryText">{filtered.length}</span> applications
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
              <button
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                disabled={safePage === 1}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-border text-sm font-medium text-secondaryText hover:bg-backgroundLight disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft size={16} /> Prev
              </button>

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

              <button
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                disabled={safePage === totalPages}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-border text-sm font-medium text-secondaryText hover:bg-backgroundLight disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                Next <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AppliedJobs;
