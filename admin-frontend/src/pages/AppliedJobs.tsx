import { useEffect, useState, useRef } from 'react';
import api from '../api/axios';
import {
  Briefcase, MapPin, Building2, Calendar, Filter,
  Download, ChevronDown, FileText, FileSpreadsheet, FileDown
} from 'lucide-react';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';

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

const AppliedJobs = () => {
  const { showToast } = useToast();
  const [applications, setApplications] = useState<JobApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const fetchApplications = async () => {
      try {
        const { data } = await api.get('/admin/job-applications');
        setApplications(data);
      } catch {
        setError('Failed to load job applications.');
        showToast('Failed to load job applications.', 'error');
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
    if (statusFilter === 'all') return true;
    return app.status === statusFilter;
  });

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

  const columns: Column<JobApplication>[] = [
    {
      header: 'Applicant',
      accessorKey: 'user.full_name', // for searching
      cell: (app) => (
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
      )
    },
    {
      header: 'Job',
      accessorKey: 'job.title',
      cell: (app) => (
        <div>
          <p className="font-medium text-primaryText">{app.job?.title || '—'}</p>
          <p className="text-xs text-secondaryText flex items-center gap-1">
            <MapPin size={10} /> {app.job?.location || '—'}
          </p>
        </div>
      )
    },
    {
      header: 'Company',
      accessorKey: 'job.company',
      cell: (app) => (
        <div className="flex items-center gap-1.5 text-primaryText">
          <Building2 size={14} className="text-secondaryText" />
          {app.job?.company || '—'}
        </div>
      )
    },
    {
      header: 'Type',
      accessorKey: 'job.type',
      cell: (app) => (
        <span className="px-2 py-1 rounded-md bg-backgroundLight text-secondaryText text-xs font-medium">
          {app.job?.type || '—'}
        </span>
      )
    },
    {
      header: 'Status',
      accessorKey: 'status',
      cell: (app) => (
        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold capitalize ${statusColors[app.status] || 'bg-gray-100 text-gray-600'}`}>
          {app.status || '—'}
        </span>
      )
    },
    {
      header: 'Applied On',
      accessorKey: 'applied_at',
      cell: (app) => (
        <div className="flex items-center gap-1.5 text-secondaryText text-xs">
          <Calendar size={12} />
          {formatDate(app.applied_at)}
        </div>
      )
    }
  ];

  const toolbarExtras = (
    <div className="relative w-48">
      <Filter className="absolute left-3 top-2.5 text-borderDark" size={18} />
      <select
        value={statusFilter}
        onChange={(e) => setStatusFilter(e.target.value)}
        className="input-field pl-10 pr-8 bg-white appearance-none cursor-pointer w-full"
      >
        {uniqueStatuses.map((s) => (
          <option key={s} value={s}>{s === 'all' ? 'All Statuses' : s.charAt(0).toUpperCase() + s.slice(1)}</option>
        ))}
      </select>
      <ChevronDown className="absolute right-3 top-3 text-borderDark pointer-events-none" size={16} />
    </div>
  );

  return (
    <div className="animate-fade-in">
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

      {error ? (
        <div className="bg-red-50 text-red-600 p-6 rounded-xl border border-red-200 text-center">{error}</div>
      ) : (
        <DataTable
          data={filtered}
          columns={columns}
          searchPlaceholder="Search by user, job, or company..."
          searchableKeys={['user.full_name', 'job.title', 'job.company', 'user.mobile_number']}
          loading={loading}
          emptyStateMessage="No applications found"
          emptyStateIcon={<Briefcase size={36} className="text-border" />}
          toolbarExtras={toolbarExtras}
        />
      )}
    </div>
  );
};

export default AppliedJobs;
