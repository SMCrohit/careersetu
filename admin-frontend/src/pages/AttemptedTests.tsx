import { useEffect, useState, useRef } from 'react';
import api from '../api/axios';
import { FileText, User, BookOpen, Calendar, Trophy, Download, ChevronDown, FileSpreadsheet, FileDown, X, Filter, Trash2, Mail } from 'lucide-react';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useToast } from '../context/ToastContext';

type TestAttempt = {
  id: string;
  score: number;
  total_questions: number;
  attempted_at: string;
  status: string;
  time_taken_seconds: number | null;
  guest_info: any;
  ai_report: any;
  user: {
    id: string;
    full_name: string;
    email: string;
    mobile_number: string;
    city: string;
    type?: string;
  } | null;
  test: {
    id: string;
    title: string;
    tag: string;
    difficulty: string;
  } | null;
};

const difficultyColors: Record<string, string> = {
  Easy: 'bg-green-100 text-green-700',
  Medium: 'bg-yellow-100 text-yellow-700',
  Hard: 'bg-red-100 text-red-700',
};

const AttemptedTests = () => {
  const { showToast } = useToast();
  const [attempts, setAttempts] = useState<TestAttempt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  const [currentPage, setCurrentPage] = useState(1);
  const [currentLimit, setCurrentLimit] = useState(10);
  const [serverTotal, setServerTotal] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [filters, setFilters] = useState({
    user_type: '',
    status: '',
    result: '',
    score_above: '',
    date_from: '',
    date_to: ''
  });

  const [selectedAttempt, setSelectedAttempt] = useState<any>(null);

  const fetchAttemptsWithParams = async (overrideFilters: any = null, page: number = currentPage, search: string = searchTerm, limit: number = currentLimit) => {
    setLoading(true);
    try {
      const current = overrideFilters || filters;
      const params = new URLSearchParams();
      params.append('page', page.toString());
      params.append('limit', limit.toString());
      if (search) params.append('search', search);
      if (current.user_type) params.append('user_type', current.user_type);
      if (current.status) params.append('status', current.status);
      if (current.result) params.append('result', current.result);
      if (current.score_above) params.append('score_above', current.score_above);
      if (current.date_from) params.append('date_from', current.date_from);
      if (current.date_to) params.append('date_to', current.date_to);

      const res = await api.get(`/admin/test-attempts?${params.toString()}`);
      setAttempts(res.data.data);
      setServerTotal(res.data.total);
    } catch (err) {
      setError('Failed to load test attempts.');
      showToast('Failed to load test attempts.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAttemptsWithParams(null, 1, '', 10);
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

  const formatDate = (iso: string) => {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  };

  const getScoreColor = (score: number, total: number) => {
    if (total === 0) return 'text-secondaryText';
    const pct = (score / total) * 100;
    if (pct >= 80) return 'text-green-600';
    if (pct >= 50) return 'text-yellow-600';
    return 'text-red-500';
  };

  // ── Export helpers ─────────────────────────────────────────────────────────
  const exportRows = attempts.map((att, i) => ({
    '#': i + 1,
    User: att.user?.full_name || '—',
    Mobile: att.user?.mobile_number || '—',
    City: att.user?.city || '—',
    Test: att.test?.title || '—',
    Tag: att.test?.tag || '—',
    Difficulty: att.test?.difficulty || '—',
    Score: att.score != null ? att.score : '—',
    'Total Questions': att.total_questions || 0,
    'Attempted On': formatDate(att.attempted_at),
  }));

  const exportToCSV = () => {
    if (exportRows.length === 0) return;
    const headers = Object.keys(exportRows[0]);
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'attempted_tests.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Attempted Tests');
    XLSX.writeFile(wb, 'attempted_tests.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Attempted Tests', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${attempts.length} attempts`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'User', 'Mobile', 'City', 'Test', 'Tag', 'Difficulty', 'Score', 'Total Qs', 'Attempted On']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 7.5, cellPadding: 2.5 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('attempted_tests.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const columns: Column<TestAttempt>[] = [
    {
      header: 'User',
      accessorKey: 'user.full_name',
      sortable: true,
      cell: (att) => (
        <div className="flex items-center gap-2.5 cursor-pointer hover:underline" onClick={() => setSelectedAttempt(att)}>
          <div className="w-8 h-8 rounded-full bg-primaryBrand/10 flex items-center justify-center shrink-0">
            <User size={14} className="text-primaryBrand" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <p className="font-medium text-primaryText">{att.user?.full_name || '—'}</p>
              {(att.user as any)?.type === 'Guest' && (
                <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-orange-100 text-orange-700">Guest</span>
              )}
            </div>
            <p className="text-xs text-secondaryText">{att.user?.mobile_number || '—'} &middot; {att.user?.city || '—'}</p>
          </div>
        </div>
      )
    },
    {
      header: 'Test Details',
      accessorKey: 'test.title',
      sortable: true,
      cell: (att) => (
        <div>
          <div className="flex items-center gap-2">
            <BookOpen size={14} className="text-secondaryText shrink-0" />
            <span className="font-semibold text-primaryText text-sm max-w-[200px] truncate block" title={att.test?.title}>
              {att.test?.title || 'Unknown Test'}
            </span>
          </div>
          <div className="flex items-center gap-2 mt-1 ml-5">
            <span className="px-1.5 py-0.5 rounded text-[10px] font-medium bg-backgroundLight text-secondaryText">{att.test?.tag || '—'}</span>
            <span className={`px-1.5 py-0.5 rounded text-[10px] font-semibold ${difficultyColors[att.test?.difficulty || ''] || 'bg-gray-100 text-gray-600'}`}>
              {att.test?.difficulty || '—'}
            </span>
          </div>
        </div>
      )
    },
    {
      header: 'Score & Result',
      accessorKey: 'score',
      sortable: true,
      cell: (att) => {
        const pct = att.total_questions > 0 && att.score != null ? Math.round((att.score / att.total_questions) * 100) : 0;
        let badge = { text: 'Needs Review', color: 'bg-yellow-100 text-yellow-700' };
        if (pct >= 70) badge = { text: 'Passed', color: 'bg-green-100 text-green-700' };
        else if (att.status === 'completed' && pct < 70) badge = { text: 'Failed', color: 'bg-red-100 text-red-700' };
        
        return (
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center gap-1.5">
              <Trophy size={12} className={getScoreColor(att.score, att.total_questions)} />
              <span className={`font-bold text-sm ${getScoreColor(att.score, att.total_questions)}`}>
                {att.score != null ? att.score : '—'} <span className="text-secondaryText text-[10px] font-medium">/ {att.total_questions} ({pct}%)</span>
              </span>
            </div>
            {att.score != null && (
              <span className={`px-1.5 py-0.5 rounded text-[10px] font-bold w-fit tracking-wide uppercase ${badge.color}`}>{badge.text}</span>
            )}
          </div>
        );
      }
    },
    {
      header: 'Time & Status',
      accessorKey: 'time_taken_seconds',
      sortable: true,
      cell: (att) => {
        const mins = att.time_taken_seconds ? Math.floor(att.time_taken_seconds / 60) : 0;
        const secs = att.time_taken_seconds ? att.time_taken_seconds % 60 : 0;
        const timeStr = mins > 0 ? `${mins}m ${secs}s` : `${secs}s`;
        return (
          <div className="flex flex-col gap-1.5">
             <span className="text-xs font-medium text-primaryText">{att.time_taken_seconds ? timeStr : '—'}</span>
             <span className={`px-1.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-wide w-fit ${att.status === 'completed' ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'}`}>
                {att.status || 'unknown'}
             </span>
          </div>
        );
      }
    },
    {
      header: 'Attempted On',
      accessorKey: 'attempted_at',
      sortable: true,
      cell: (att) => (
        <div className="flex items-center gap-1.5 text-secondaryText text-xs">
          <Calendar size={12} />
          {formatDate(att.attempted_at)}
        </div>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-4 mb-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primaryBrand/10 rounded-xl flex items-center justify-center">
            <FileText className="text-primaryBrand" size={20} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-primaryText">Attempted Tests</h1>
            <p className="text-sm text-secondaryText">All test attempts made by users</p>
          </div>
        </div>

        <div className="flex items-center gap-3">
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
        <>
          {/* Advanced Filters Drawer */}
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
                    <label className="block text-sm font-medium text-secondaryText mb-2">User Type</label>
                    <select
                      value={filters.user_type}
                      onChange={(e) => setFilters({ ...filters, user_type: e.target.value })}
                      className="input-field bg-white"
                    >
                      <option value="">All Users</option>
                      <option value="Registered">Registered</option>
                      <option value="Guest">Guest</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-2">Status</label>
                    <select
                      value={filters.status}
                      onChange={(e) => setFilters({ ...filters, status: e.target.value })}
                      className="input-field bg-white"
                    >
                      <option value="">All</option>
                      <option value="completed">Completed</option>
                      <option value="abandoned">Abandoned</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-2">Result</label>
                    <select
                      value={filters.result}
                      onChange={(e) => setFilters({ ...filters, result: e.target.value })}
                      className="input-field bg-white"
                    >
                      <option value="">All</option>
                      <option value="passed">Passed</option>
                      <option value="failed">Failed</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-2">Score Above (%)</label>
                    <input
                      type="number"
                      min="0"
                      max="100"
                      value={filters.score_above}
                      onChange={(e) => setFilters({ ...filters, score_above: e.target.value })}
                      className="input-field bg-white"
                      placeholder="e.g. 60"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-secondaryText mb-2">From Date</label>
                      <input
                        type="date"
                        value={filters.date_from}
                        onChange={(e) => setFilters({ ...filters, date_from: e.target.value })}
                        className="input-field bg-white"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-secondaryText mb-2">To Date</label>
                      <input
                        type="date"
                        value={filters.date_to}
                        onChange={(e) => setFilters({ ...filters, date_to: e.target.value })}
                        className="input-field bg-white"
                      />
                    </div>
                  </div>
                </div>
                <div className="p-4 border-t border-border flex gap-3">
                  <button onClick={() => {
                    const empty = {user_type: '', status: '', result: '', score_above: '', date_from: '', date_to: ''};
                    setFilters(empty);
                    setCurrentPage(1);
                    fetchAttemptsWithParams(empty, 1, searchTerm, currentLimit);
                  }} className="flex-1 py-2 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200">Clear All</button>
                  <button onClick={() => {
                    setIsFilterOpen(false);
                    setCurrentPage(1);
                    fetchAttemptsWithParams(filters, 1, searchTerm, currentLimit);
                  }} className="flex-1 py-2 bg-primaryBrand text-white rounded-xl font-medium hover:bg-blue-700">Apply Filters</button>
                </div>
              </div>
            </div>
          )}

          <DataTable
            data={attempts}
            columns={columns}
            searchPlaceholder="Search by user, email..."
            searchableKeys={['user.full_name', 'user.mobile_number']}
            loading={loading}
            emptyStateMessage="No test attempts found"
            emptyStateIcon={<FileText size={36} className="text-border" />}
            serverSideMode={true}
            serverSideTotal={serverTotal}
            serverSidePage={currentPage}
            onPageChange={(page) => {
              setCurrentPage(page);
              fetchAttemptsWithParams(null, page, searchTerm, currentLimit);
            }}
            onSearchChange={(search) => {
              setSearchTerm(search);
              setCurrentPage(1);
              fetchAttemptsWithParams(null, 1, search, currentLimit);
            }}
            onPageSizeChange={(size) => {
              setCurrentLimit(size);
              setCurrentPage(1);
              fetchAttemptsWithParams(null, 1, searchTerm, size);
            }}
            toolbarExtras={
              <button onClick={() => setIsFilterOpen(true)} className="flex items-center gap-2 px-4 py-2 bg-white border border-border rounded-xl text-secondaryText hover:text-primaryText shadow-sm h-[42px]">
                <Filter size={18} />
                Filters
                {Object.values(filters).filter(v => v).length > 0 && (
                  <span className="w-5 h-5 bg-primaryBrand text-white text-[10px] flex items-center justify-center rounded-full">
                    {Object.values(filters).filter(v => v).length}
                  </span>
                )}
              </button>
            }
          />
        </>
      )}

      {/* Attempt Details Side Panel */}
      {selectedAttempt && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="absolute inset-0 bg-black/20" onClick={() => setSelectedAttempt(null)}></div>
          <div className="relative w-[500px] bg-white h-full shadow-2xl flex flex-col animate-slide-in-right">
            <div className="p-6 border-b border-border flex justify-between items-center bg-gray-50/50">
              <div>
                <h2 className="text-xl font-bold text-primaryText">Attempt Profile</h2>
                <p className="text-sm text-secondaryText">Detailed analysis of {selectedAttempt.user?.full_name}'s performance</p>
              </div>
              <button onClick={() => setSelectedAttempt(null)} className="text-gray-400 hover:text-gray-600 bg-white p-2 rounded-full border border-gray-200"><X size={20}/></button>
            </div>
            
            <div className="flex-1 overflow-y-auto">
              <div className="p-6 space-y-6">
                
                {/* 1. Score Details */}
                <div>
                  <h3 className="text-sm font-bold uppercase tracking-wider text-secondaryText mb-3">Score Details</h3>
                  <div className="bg-white border border-gray-200 rounded-xl shadow-sm p-4 space-y-4">
                    <div>
                      <span className="text-secondaryText text-xs font-medium block mb-1">Test Name</span>
                      <span className="font-semibold text-primaryText text-sm">{selectedAttempt.test?.title || 'Unknown Test'}</span>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <span className="text-secondaryText text-xs font-medium block mb-1">Score & Result</span>
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-lg text-primaryText">{selectedAttempt.score != null ? selectedAttempt.score : '—'}/{selectedAttempt.total_questions}</span>
                          <span className="text-secondaryText text-xs font-medium">
                            ({selectedAttempt.total_questions > 0 && selectedAttempt.score != null ? Math.round((selectedAttempt.score / selectedAttempt.total_questions) * 100) : 0}%)
                          </span>
                        </div>
                        {selectedAttempt.score != null && (() => {
                          const pct = selectedAttempt.total_questions > 0 ? Math.round((selectedAttempt.score / selectedAttempt.total_questions) * 100) : 0;
                          if (pct >= 70) return <span className="inline-block mt-1 px-1.5 py-0.5 bg-green-100 text-green-700 text-[10px] font-bold uppercase tracking-wider rounded">Passed</span>;
                          if (selectedAttempt.status === 'completed') return <span className="inline-block mt-1 px-1.5 py-0.5 bg-red-100 text-red-700 text-[10px] font-bold uppercase tracking-wider rounded">Failed</span>;
                          return <span className="inline-block mt-1 px-1.5 py-0.5 bg-yellow-100 text-yellow-700 text-[10px] font-bold uppercase tracking-wider rounded">Needs Review</span>;
                        })()}
                      </div>
                      <div>
                        <span className="text-secondaryText text-xs font-medium block mb-1">Time & Status</span>
                        <span className="font-semibold text-sm text-primaryText block mb-1">
                          {selectedAttempt.time_taken_seconds ? `${Math.floor(selectedAttempt.time_taken_seconds / 60)}m ${selectedAttempt.time_taken_seconds % 60}s` : '—'}
                        </span>
                        <span className={`inline-block px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wider rounded ${selectedAttempt.status === 'completed' ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'}`}>
                          {selectedAttempt.status || 'unknown'}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                
                {/* 2. Student Details */}
                <div>
                  <h3 className="text-sm font-bold uppercase tracking-wider text-secondaryText mb-3">Student Details</h3>
                  <div className="bg-gray-50 rounded-xl p-4 border border-gray-100 space-y-3">
                    <div className="flex justify-between items-center">
                      <span className="text-secondaryText text-sm">Name</span>
                      <span className="font-medium text-sm text-primaryText flex items-center gap-2">
                        {selectedAttempt.user?.full_name || '—'}
                        {selectedAttempt.user?.type === 'Guest' ? (
                          <span className="bg-orange-100 text-orange-700 text-[10px] px-1.5 py-0.5 rounded font-bold uppercase tracking-wider">Guest</span>
                        ) : (
                          <span className="bg-blue-100 text-blue-700 text-[10px] px-1.5 py-0.5 rounded font-bold uppercase tracking-wider">Registered</span>
                        )}
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-secondaryText text-sm">Email</span>
                      <span className="font-medium text-sm text-primaryText">{selectedAttempt.user?.email || '—'}</span>
                    </div>
                    {(selectedAttempt.user?.mobile_number || selectedAttempt.user?.type !== 'Guest') && (
                      <div className="flex justify-between items-center">
                        <span className="text-secondaryText text-sm">Mobile</span>
                        <span className="font-medium text-sm text-primaryText">{selectedAttempt.user?.mobile_number || '—'}</span>
                      </div>
                    )}
                    {selectedAttempt.user?.type !== 'Guest' && (
                      <div className="flex justify-between items-center">
                        <span className="text-secondaryText text-sm">Location</span>
                        <span className="font-medium text-sm text-primaryText">{selectedAttempt.user?.city || '—'}</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* 3. AI Summary */}
                <div>
                  <h3 className="text-sm font-bold uppercase tracking-wider text-secondaryText mb-3 flex items-center gap-2">
                    <span className="bg-purple-100 text-purple-700 w-5 h-5 flex items-center justify-center rounded-full text-xs">✨</span>
                    AI Summary
                  </h3>
                  {selectedAttempt.ai_report ? (
                    <div className="bg-gradient-to-br from-purple-50 to-white rounded-xl p-5 border border-purple-100 shadow-sm space-y-5">
                      <p className="text-sm text-gray-800 leading-relaxed font-medium">
                        {selectedAttempt.ai_report.overall_insight}
                      </p>
                      
                      {selectedAttempt.ai_report.strong_areas && selectedAttempt.ai_report.strong_areas.length > 0 && (
                        <div>
                          <span className="text-[10px] font-bold text-secondaryText uppercase tracking-wider mb-2 block">Strong Areas</span>
                          <div className="flex flex-wrap gap-2">
                            {selectedAttempt.ai_report.strong_areas.map((area: any, idx: number) => (
                              <span key={idx} className="bg-green-100 text-green-700 border border-green-200 px-2 py-1 rounded-md text-xs font-semibold flex items-center gap-1.5">
                                <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span>
                                {area.topic} {area.subtopic ? `(${area.subtopic})` : ''} — {area.accuracy}%
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                      
                      {selectedAttempt.ai_report.weak_areas && selectedAttempt.ai_report.weak_areas.length > 0 && (
                        <div>
                          <span className="text-[10px] font-bold text-secondaryText uppercase tracking-wider mb-2 block">Areas for Improvement</span>
                          <div className="flex flex-wrap gap-2">
                            {selectedAttempt.ai_report.weak_areas.map((area: any, idx: number) => (
                              <span key={idx} className="bg-red-50 text-red-700 border border-red-100 px-2 py-1 rounded-md text-xs font-semibold flex items-center gap-1.5">
                                <span className="w-1.5 h-1.5 rounded-full bg-red-500"></span>
                                {area.topic} {area.subtopic ? `(${area.subtopic})` : ''} — {area.accuracy}%
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                      
                      {selectedAttempt.ai_report.time_management && (
                        <div className="pt-4 border-t border-purple-100/50">
                          <span className="text-[10px] font-bold text-secondaryText uppercase tracking-wider mb-1 block">Time Management</span>
                          <p className="text-xs text-gray-700">{selectedAttempt.ai_report.time_management}</p>
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="bg-gray-50 rounded-xl p-5 border border-dashed border-gray-200 text-center">
                      <p className="text-sm text-secondaryText">AI Summary is being generated or not available.</p>
                    </div>
                  )}
                </div>

                {/* 4. Device Info (Guest only) */}
                {selectedAttempt.user?.type === 'Guest' && selectedAttempt.guest_info && (
                  <div>
                    <h3 className="text-sm font-bold uppercase tracking-wider text-secondaryText mb-3">Device Info</h3>
                    <div className="bg-white rounded-xl p-4 border border-gray-200 shadow-sm grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span className="block text-[10px] font-bold text-secondaryText uppercase tracking-wider mb-1">Device Type</span>
                        <span className="font-medium text-primaryText">{selectedAttempt.guest_info.device_type || 'Unknown'}</span>
                      </div>
                      <div>
                        <span className="block text-[10px] font-bold text-secondaryText uppercase tracking-wider mb-1">OS</span>
                        <span className="font-medium text-primaryText">{selectedAttempt.guest_info.os || 'Unknown'}</span>
                      </div>
                      <div>
                        <span className="block text-[10px] font-bold text-secondaryText uppercase tracking-wider mb-1">Browser / App</span>
                        <span className="font-medium text-primaryText">{selectedAttempt.guest_info.browser || selectedAttempt.guest_info.user_agent || 'Unknown'}</span>
                      </div>
                      <div>
                        <span className="block text-[10px] font-bold text-secondaryText uppercase tracking-wider mb-1">IP Address</span>
                        <span className="font-medium text-primaryText">{selectedAttempt.guest_info.ip_address || 'Unknown'}</span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div className="p-6 border-t border-border bg-white space-y-3">
              <button className="w-full btn-primary flex justify-center items-center gap-2" onClick={() => showToast('Feature is coming soon', 'info')}>
                <Mail size={16} /> Email Results to Student
              </button>
              <div className="grid grid-cols-2 gap-3">
                <button 
                  className="flex justify-center items-center gap-2 py-2.5 px-4 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl text-sm font-semibold transition-colors"
                  onClick={() => showToast('Feature is coming soon', 'info')}
                >
                  <FileText size={16} /> Export PDF
                </button>
                <button 
                  className="flex justify-center items-center gap-2 py-2.5 px-4 bg-red-50 hover:bg-red-100 text-red-600 rounded-xl text-sm font-semibold transition-colors"
                  onClick={() => showToast('Feature is coming soon', 'info')}
                >
                  <Trash2 size={16} /> Invalidate
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttemptedTests;
