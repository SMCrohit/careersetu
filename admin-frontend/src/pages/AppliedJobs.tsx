import { useState, useEffect, useRef } from 'react';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { 
  Briefcase, FileText, Calendar, 
  ExternalLink, Mail,
  XCircle, Download, FileUp, Filter, FileSpreadsheet, FileDown, ChevronDown
} from 'lucide-react';
import api from '../api/axios';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';

interface Applicant {
  full_name: string;
  email: string;
  mobile_number: string;
}

interface JobInfo {
  title: string;
  company_name: string;
  application_routing_mode: string;
}

interface JobApplication {
  id: string;
  applicant: Applicant;
  job: JobInfo;
  status: string;
  applied_datetime: string;
  resume_snapshot_url: string | null;
  has_resume?: boolean;
  resume_filename?: string | null;
  resume_source?: 'submitted' | 'profile' | null;
  cover_letter: string | null;
  screening_responses: Record<string, string> | null;
  ai_match_score: number | null;
  notes_by_admin: string | null;
  employer_feedback: string | null;
  interview_datetime: string | null;
}

const AppliedJobs = () => {
  const { showToast } = useToast();
  const [applications, setApplications] = useState<JobApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedApp, setSelectedApp] = useState<JobApplication | null>(null);
  const [resumeLoading, setResumeLoading] = useState<'view' | 'download' | null>(null);

  // The resume endpoint needs the admin token, so fetch it as a blob instead of linking to it.
  const openResume = async (app: JobApplication, mode: 'view' | 'download') => {
    setResumeLoading(mode);
    try {
      const res = await api.get(`/job-applications/${app.id}/resume`, { responseType: 'blob' });
      const url = URL.createObjectURL(new Blob([res.data], { type: 'application/pdf' }));
      if (mode === 'view') {
        window.open(url, '_blank', 'noopener');
      } else {
        const link = document.createElement('a');
        link.href = url;
        link.download = app.resume_filename || `${app.applicant.full_name || 'resume'}.pdf`;
        link.click();
      }
      setTimeout(() => URL.revokeObjectURL(url), 60_000);
    } catch {
      showToast('Could not load the resume', 'error');
    } finally {
      setResumeLoading(null);
    }
  };
  
  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [updating, setUpdating] = useState(false);
  const [editStatus, setEditStatus] = useState('');
  const [editNotes, setEditNotes] = useState('');
  const [editInterviewDate, setEditInterviewDate] = useState('');

  
  const [availableCompanies, setAvailableCompanies] = useState<string[]>([]);
  const [serverTotal, setServerTotal] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [currentLimit, setCurrentLimit] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  
  useEffect(() => {
    const fetchCompanies = async () => {
      try {
        const res = await api.get('/jobs/companies');
        setAvailableCompanies(res.data);
      } catch (err) {
        console.error("Failed to fetch companies", err);
      }
    };
    fetchCompanies();
  }, []);

  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [filters, setFilters] = useState({
    status: '',
    company_name: '',
    applied_start: '',
    applied_end: '',
    min_match: '',
    max_match: ''
  });

  const fetchApplicationsWithParams = async (overrideFilters: any = null, page: number = currentPage, search: string = searchTerm, limit: number = currentLimit) => {
    try {
      const current = overrideFilters || filters;
      const params = new URLSearchParams();
      if(current.status) params.append('status', current.status);
      if(current.company_name) params.append('company_name', current.company_name);
      if(current.applied_start) params.append('applied_start', current.applied_start);
      if(current.applied_end) params.append('applied_end', current.applied_end);
      if(current.min_match) params.append('min_match', current.min_match);
      if(current.max_match) params.append('max_match', current.max_match);
      
      params.append('page', page.toString());
      params.append('limit', limit.toString());
      if (search) params.append('search', search);
      
      const res = await api.get(`/job-applications?${params.toString()}`);
      setApplications(res.data?.data || []);
      setServerTotal(res.data?.total || 0);
    } catch {
      showToast('Failed to fetch job applications', 'error');
    } finally {
      setLoading(false);
    }
  };


  useEffect(() => {
    setCurrentPage(1);
                fetchApplicationsWithParams(filters, 1, searchTerm);
  }, []);

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
  
  // ─── Export helpers ────────────────────────────────────────────────────────
  const exportRows = (applications || []).map((a, i) => ({
    '#': i + 1,
    'Applicant Name': a.applicant.full_name || '—',
    'Applicant Email': a.applicant.email || '—',
    'Applicant Phone': a.applicant.mobile_number || '—',
    'Job Title': a.job.title || '—',
    'Company': a.job.company_name || '—',
    'Routing Mode': a.job.application_routing_mode || '—',
    'Status': a.status || '—',
    'AI Match %': a.ai_match_score || '—',
    'Applied On': a.applied_datetime ? new Date(a.applied_datetime).toLocaleDateString('en-IN') : '—',
  }));

  const exportToCSV = () => {
    const headers = Object.keys(exportRows[0] || {});
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'applied_jobs.csv';
    a.click();
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
    doc.text('Applied Jobs Directory', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${applications.length} applications`, 14, 22);

    autoTable(doc, {
      startY: 28,
      head: [['#', 'Name', 'Email', 'Job Title', 'Company', 'Mode', 'Status', 'Match', 'Applied On']],
      body: exportRows.map((r) => [
        r['#'], r['Applicant Name'], r['Applicant Email'], r['Job Title'], r['Company'], r['Routing Mode'], r['Status'], r['AI Match %'], r['Applied On']
      ]),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });

    doc.save('applied_jobs.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };



  const handleReview = (app: JobApplication) => {
    setSelectedApp(app);
    setEditStatus(app.status);
    setEditNotes(app.notes_by_admin || '');
    setEditInterviewDate(app.interview_datetime ? new Date(app.interview_datetime).toISOString().slice(0, 16) : '');
    setIsModalOpen(true);
  };

  const handleUpdate = async () => {
    if (!selectedApp) return;
    setUpdating(true);
    try {
      const payload: any = {
        status: editStatus,
        notes_by_admin: editNotes
      };
      if (editStatus === 'interview_scheduled') {
        payload.interview_datetime = new Date(editInterviewDate).toISOString();
      }
      
      await api.put(`/job-applications/${selectedApp.id}`, payload);
      
      // Update local state
      setApplications(applications.map(a => {
        if (a.id === selectedApp.id) {
          return {
            ...a,
            status: editStatus,
            notes_by_admin: editNotes,
            interview_datetime: editStatus === 'interview_scheduled' ? payload.interview_datetime : a.interview_datetime
          };
        }
        return a;
      }));
      
      showToast('Application updated successfully', 'success');
      setIsModalOpen(false);
    } catch (error) {
      showToast('Failed to update application', 'error');
    } finally {
      setUpdating(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'applied': return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">Applied</span>;
      case 'shortlisted': return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700">Shortlisted</span>;
      case 'interview_scheduled': return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-700">Interview Scheduled</span>;
      case 'offered': return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">Offered</span>;
      case 'rejected': return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">Rejected</span>;
      case 'email_sent': return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700">Email Sent</span>;
      case 'redirected': return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-indigo-100 text-indigo-700">Redirected</span>;
      default: return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">{status}</span>;
    }
  };

  const getRoutingBadge = (mode: string) => {
    switch (mode) {
      case 'manual_review': return <span className="flex items-center gap-1 text-[10px] font-bold tracking-wider uppercase text-blue-600 bg-blue-50 px-2 py-0.5 rounded border border-blue-100"><Briefcase size={10} /> ATS</span>;
      case 'direct_email': return <span className="flex items-center gap-1 text-[10px] font-bold tracking-wider uppercase text-purple-600 bg-purple-50 px-2 py-0.5 rounded border border-purple-100"><Mail size={10} /> Email</span>;
      case 'external_link': return <span className="flex items-center gap-1 text-[10px] font-bold tracking-wider uppercase text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded border border-indigo-100"><ExternalLink size={10} /> External</span>;
      default: return null;
    }
  };

  const formatDate = (iso: string) => {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric'
    });
  };

  const formatDateTime = (iso: string) => {
    if (!iso) return '—';
    return new Date(iso).toLocaleString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  };

  const columns: Column<JobApplication>[] = [
    {
      header: 'Applicant',
      accessorKey: 'applicant.full_name',
      sortable: true,
      cell: (app) => (
        <div className="flex flex-col gap-0.5">
          <span className="font-medium text-primaryText">{app.applicant.full_name || 'N/A'}</span>
          <span className="text-xs text-secondaryText">{app.applicant.email}</span>
        </div>
      )
    },
    {
      header: 'Job Applied For',
      accessorKey: 'job.title',
      sortable: true,
      cell: (app) => (
        <div className="flex flex-col gap-1.5 items-start">
          <div className="flex flex-col gap-0.5">
            <span className="font-medium text-primaryText text-sm">{app.job.title}</span>
            <span className="text-xs text-secondaryText">{app.job.company_name}</span>
          </div>
          {getRoutingBadge(app.job.application_routing_mode)}
        </div>
      )
    },
    {
      header: 'Status & Timeline',
      accessorKey: 'status',
      sortable: true,
      cell: (app) => (
        <div className="flex flex-col gap-2 items-start">
          {getStatusBadge(app.status)}
          {app.status === 'interview_scheduled' && app.interview_datetime && (
            <span className="flex items-center gap-1 text-xs font-medium text-orange-600 bg-orange-50 px-1.5 py-0.5 rounded border border-orange-100">
              <Calendar size={10} />
              {formatDateTime(app.interview_datetime)}
            </span>
          )}
        </div>
      )
    },
    {
      header: 'AI Match',
      accessorKey: 'ai_match_score',
      sortable: true,
      cell: (app) => (
        app.ai_match_score ? (
          <div className="flex items-center gap-2">
            <div className={`text-sm font-bold ${app.ai_match_score >= 80 ? 'text-green-600' : app.ai_match_score >= 60 ? 'text-orange-500' : 'text-red-500'}`}>
              {app.ai_match_score}%
            </div>
          </div>
        ) : <span className="text-secondaryText text-sm">—</span>
      )
    },
    {
      header: 'Applied On',
      accessorKey: 'applied_datetime',
      sortable: true,
      cell: (app) => <span className="text-secondaryText text-sm">{formatDate(app.applied_datetime)}</span>
    },
    {
      header: 'Actions',
      cell: (app) => (
        <div className="text-right">
          {app.job.application_routing_mode === 'manual_review' ? (
            <button
              onClick={() => handleReview(app)}
              className="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-primaryBrand border border-primaryBrand rounded-lg hover:bg-blue-50 transition-colors"
            >
              <FileText size={15} /> Review
            </button>
          ) : (
            <span className="text-xs text-secondaryText italic px-2">No ATS Profile</span>
          )}
        </div>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
        <div className="flex flex-wrap items-center justify-between gap-4 mb-8">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primaryBrand/10 rounded-xl flex items-center justify-center">
            <FileUp size={20} className="text-primaryBrand" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-primaryText">
              Applied Jobs
              <span className="text-sm font-medium bg-primaryBrand/10 text-primaryBrand px-2.5 py-1 rounded-lg ml-3 align-middle">
                {serverTotal} Total
              </span>
            </h1>
            <p className="text-sm text-secondaryText">Review and manage student job applications and interviews.</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
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
      </div>

      <DataTable
        data={applications}
        columns={columns}
        searchPlaceholder="Search applicant name, email, or job title..."
        searchableKeys={['applicant.full_name', 'applicant.email', 'job.title', 'job.company_name']}
        loading={loading}
        emptyStateMessage="No applications found."
        emptyStateIcon={<FileUp size={36} className="text-border" />}
        serverSideMode={true}
        serverSideTotal={serverTotal}
        serverSidePage={currentPage}
        onPageChange={(page) => {
          setCurrentPage(page);
          fetchApplicationsWithParams(null, page, searchTerm, currentLimit);
        }}
        onSearchChange={(s) => {
          setSearchTerm(s);
          setCurrentPage(1);
          fetchApplicationsWithParams(null, 1, s, currentLimit);
        }}
        onPageSizeChange={(size) => {
          setCurrentLimit(size);
          setCurrentPage(1);
          fetchApplicationsWithParams(null, 1, searchTerm, size);
        }}
        toolbarExtras={
          <button onClick={() => setIsFilterOpen(true)} className="flex items-center gap-2 px-3 py-1.5 border border-border rounded-lg text-sm font-medium hover:bg-gray-50 transition-colors bg-white shrink-0 h-[38px]">
            <Filter size={16} /> 
            Filters {Object.values(filters).filter(v => v !== '').length > 0 && <span className="w-5 h-5 bg-primaryBrand text-white text-[10px] flex items-center justify-center rounded-full">{Object.values(filters).filter(v => v !== '').length}</span>}
          </button>
        }
      />


      {/* Filter Side Drawer */}
      {isFilterOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="absolute inset-0 bg-black/20" onClick={() => setIsFilterOpen(false)}></div>
          <div className="relative w-96 bg-white h-full shadow-2xl flex flex-col animate-slide-in-right">
            <div className="p-6 border-b border-border flex justify-between items-center">
              <h2 className="text-lg font-bold text-primaryText">Advanced Filters</h2>
              <button onClick={() => setIsFilterOpen(false)} className="text-gray-400 hover:text-gray-600"><XCircle size={20}/></button>
            </div>
            <div className="p-6 flex-1 overflow-y-auto space-y-6">
              
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Company</label>
                <select
                  value={filters.company_name}
                  onChange={(e) => setFilters({ ...filters, company_name: e.target.value })}
                  className="input-field bg-white"
                >
                  <option value="">All Companies</option>
                  {availableCompanies.map(company => (
                    <option key={company} value={company}>{company}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Status</label>
                <select
                  value={filters.status}
                  onChange={(e) => setFilters({ ...filters, status: e.target.value })}
                  className="input-field bg-white"
                >
                  <option value="">All Statuses</option>
                  <option value="applied">Applied</option>
                  <option value="shortlisted">Shortlisted</option>
                  <option value="interview_scheduled">Interview Scheduled</option>
                  <option value="offered">Offered</option>
                  <option value="rejected">Rejected</option>
                  <option value="email_sent">Email Sent</option>
                  <option value="redirected">Redirected</option>
                </select>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-2">Applied From</label>
                  <input
                    type="date"
                    value={filters.applied_start}
                    onChange={(e) => setFilters({ ...filters, applied_start: e.target.value })}
                    className="input-field bg-white px-2"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-2">Applied To</label>
                  <input
                    type="date"
                    value={filters.applied_end}
                    onChange={(e) => setFilters({ ...filters, applied_end: e.target.value })}
                    className="input-field bg-white px-2"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-2">Min Match %</label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={filters.min_match}
                    onChange={(e) => setFilters({ ...filters, min_match: e.target.value })}
                    className="input-field bg-white px-2"
                    placeholder="0"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-2">Max Match %</label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={filters.max_match}
                    onChange={(e) => setFilters({ ...filters, max_match: e.target.value })}
                    className="input-field bg-white px-2"
                    placeholder="100"
                  />
                </div>
              </div>

            </div>
            <div className="p-6 border-t border-border flex gap-3">
              <button onClick={() => {
                const empty = {status: '', company_name: '', applied_start: '', applied_end: '', min_match: '', max_match: ''};
                setFilters(empty);
                setCurrentPage(1);
                fetchApplicationsWithParams(empty, 1, searchTerm);
              }} className="flex-1 py-2 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200">Clear All</button>
              <button onClick={() => {
                setIsFilterOpen(false);
                setCurrentPage(1);
                fetchApplicationsWithParams(filters, 1, searchTerm);
              }} className="flex-1 py-2 bg-primaryBrand text-white rounded-xl font-medium hover:bg-blue-700">Apply Filters</button>
            </div>
          </div>
        </div>
      )}

      {/* Review Modal */}
      {isModalOpen && selectedApp && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-3xl flex flex-col max-h-[90vh] animate-scale-in">
            
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-border">
              <div>
                <h2 className="text-xl font-bold text-primaryText">Review Application</h2>
                <p className="text-sm text-secondaryText mt-1">
                  {selectedApp.applicant.full_name} applied for <span className="font-medium text-primaryText">{selectedApp.job.title}</span> at {selectedApp.job.company_name}
                </p>
              </div>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-backgroundLight text-secondaryText transition-colors"
              >
                <XCircle size={20} />
              </button>
            </div>

            {/* Body */}
            <div className="p-6 overflow-y-auto flex-1 bg-gray-50/50 space-y-6">
              
              {/* Top Controls */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="bg-white p-4 rounded-xl border border-border shadow-sm">
                  <label className="block text-sm font-semibold text-primaryText mb-2">Application Status</label>
                  <select 
                    value={editStatus}
                    onChange={(e) => setEditStatus(e.target.value)}
                    className="w-full h-10 px-3 border border-border rounded-lg bg-white text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none transition-all"
                  >
                    <option value="applied">Applied</option>
                    <option value="shortlisted">Shortlisted</option>
                    <option value="interview_scheduled">Interview Scheduled</option>
                    <option value="offered">Offered</option>
                    <option value="rejected">Rejected</option>
                  </select>

                  {editStatus === 'interview_scheduled' && (
                    <div className="mt-4 animate-fade-in">
                      <label className="block text-sm font-semibold text-primaryText mb-2">Interview Date & Time</label>
                      <input 
                        type="datetime-local"
                        value={editInterviewDate}
                        onChange={(e) => setEditInterviewDate(e.target.value)}
                        className="w-full h-10 px-3 border border-border rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none transition-all"
                      />
                    </div>
                  )}
                </div>

                <div className="bg-white p-4 rounded-xl border border-border shadow-sm">
                  <label className="block text-sm font-semibold text-primaryText mb-2">AI Match Score</label>
                  {selectedApp.ai_match_score ? (
                    <div className="flex items-center gap-3">
                      <div className={`text-3xl font-black ${selectedApp.ai_match_score >= 80 ? 'text-green-600' : selectedApp.ai_match_score >= 60 ? 'text-orange-500' : 'text-red-500'}`}>
                        {selectedApp.ai_match_score}%
                      </div>
                      <div className="text-xs text-secondaryText leading-relaxed">
                        Score based on candidate's skills vs job requirements.
                      </div>
                    </div>
                  ) : (
                    <div className="text-sm text-secondaryText italic">No AI evaluation available.</div>
                  )}
                </div>
              </div>

              {/* Submission Data */}
              <div className="bg-white p-5 rounded-xl border border-border shadow-sm space-y-6">
                <h3 className="text-sm font-bold text-primaryText uppercase tracking-wider border-b border-border pb-2">Candidate Submission</h3>
                
                {/* Resume */}
                <div>
                  <h4 className="text-sm font-semibold text-primaryText mb-2 flex items-center gap-2"><FileText size={16} className="text-blue-500"/> Resume</h4>
                  {selectedApp.has_resume ? (
                    <div className="space-y-3">
                      <div className="flex items-center gap-3 p-3 bg-backgroundLight rounded-lg border border-border">
                        <FileText size={28} className="text-red-500 shrink-0" />
                        <div className="min-w-0">
                          <p className="text-sm font-medium text-primaryText truncate">{selectedApp.resume_filename || 'resume.pdf'}</p>
                          <p className="text-xs text-secondaryText">
                            {selectedApp.resume_source === 'submitted'
                              ? 'Submitted with this application'
                              : "Candidate's current profile resume (no copy was saved when they applied)"}
                          </p>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <button
                          type="button"
                          onClick={() => openResume(selectedApp, 'view')}
                          disabled={resumeLoading !== null}
                          className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors disabled:opacity-60"
                        >
                          <ExternalLink size={16} /> {resumeLoading === 'view' ? 'Opening…' : 'View Resume'}
                        </button>
                        <button
                          type="button"
                          onClick={() => openResume(selectedApp, 'download')}
                          disabled={resumeLoading !== null}
                          className="inline-flex items-center gap-2 px-4 py-2 bg-blue-50 text-blue-700 rounded-lg text-sm font-medium hover:bg-blue-100 transition-colors border border-blue-100 disabled:opacity-60"
                        >
                          <Download size={16} /> {resumeLoading === 'download' ? 'Downloading…' : 'Download'}
                        </button>
                      </div>
                    </div>
                  ) : selectedApp.resume_snapshot_url ? (
                    <a 
                      href={selectedApp.resume_snapshot_url} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-2 px-4 py-2 bg-blue-50 text-blue-700 rounded-lg text-sm font-medium hover:bg-blue-100 transition-colors border border-blue-100"
                    >
                      <Download size={16} /> Download Submitted Resume
                    </a>
                  ) : (
                    <p className="text-sm text-secondaryText italic">No resume attached. The candidate hasn't uploaded one to their profile.</p>
                  )}
                </div>

                {/* Cover Letter */}
                {selectedApp.cover_letter && (
                  <div>
                    <h4 className="text-sm font-semibold text-primaryText mb-2">Cover Letter</h4>
                    <div className="p-4 bg-backgroundLight rounded-lg text-sm text-primaryText whitespace-pre-wrap border border-border">
                      {selectedApp.cover_letter}
                    </div>
                  </div>
                )}

                {/* Screening Questions */}
                {selectedApp.screening_responses && Object.keys(selectedApp.screening_responses).length > 0 && (
                  <div>
                    <h4 className="text-sm font-semibold text-primaryText mb-3">Screening Responses</h4>
                    <div className="space-y-4">
                      {Object.entries(selectedApp.screening_responses).map(([question, answer], idx) => (
                        <div key={idx} className="bg-backgroundLight p-4 rounded-lg border border-border">
                          <p className="text-sm font-medium text-primaryText mb-1">Q: {question}</p>
                          <p className="text-sm text-secondaryText">A: {answer}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Admin Notes */}
              <div className="bg-white p-5 rounded-xl border border-border shadow-sm">
                <h3 className="text-sm font-bold text-primaryText uppercase tracking-wider border-b border-border pb-2 mb-4">Internal Notes</h3>
                <textarea 
                  value={editNotes}
                  onChange={(e) => setEditNotes(e.target.value)}
                  placeholder="Add private notes about this candidate..."
                  className="w-full h-24 p-3 border border-border rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none transition-all resize-none"
                />
              </div>

            </div>

            {/* Footer */}
            <div className="p-6 border-t border-border bg-gray-50 rounded-b-2xl flex justify-end gap-3">
              <button 
                type="button" 
                onClick={() => setIsModalOpen(false)}
                className="px-6 py-2 text-secondaryText hover:text-primaryText font-medium bg-white border border-border rounded-xl transition-colors"
              >
                Cancel
              </button>
              <button 
                onClick={handleUpdate} 
                disabled={updating}
                className="btn-primary px-8 flex items-center justify-center min-w-[120px]"
              >
                {updating ? 'Saving...' : 'Save Changes'}
              </button>
            </div>

          </div>
        </div>
      )}

    </div>
  );
};

export default AppliedJobs;
