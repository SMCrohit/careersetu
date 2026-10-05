import { useEffect, useState, useRef } from 'react';
import api from '../api/axios';
import { FileText, User, BookOpen, Calendar, Trophy, Download, ChevronDown, FileSpreadsheet, FileDown } from 'lucide-react';
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
  user: {
    id: string;
    full_name: string;
    mobile_number: string;
    city: string;
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

  useEffect(() => {
    const fetchAttempts = async () => {
      try {
        const { data } = await api.get('/admin/test-attempts');
        setAttempts(data);
      } catch (err) {
        setError('Failed to load test attempts.');
        showToast('Failed to load test attempts.', 'error');
      } finally {
        setLoading(false);
      }
    };
    fetchAttempts();
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
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-full bg-primaryBrand/10 flex items-center justify-center shrink-0">
            <User size={14} className="text-primaryBrand" />
          </div>
          <div>
            <p className="font-medium text-primaryText">{att.user?.full_name || '—'}</p>
            <p className="text-xs text-secondaryText">{att.user?.mobile_number || '—'} &middot; {att.user?.city || '—'}</p>
          </div>
        </div>
      )
    },
    {
      header: 'Test',
      accessorKey: 'test.title',
      sortable: true,
      cell: (att) => (
        <div className="flex items-center gap-2">
          <BookOpen size={14} className="text-secondaryText shrink-0" />
          <p className="font-medium text-primaryText">{att.test?.title || '—'}</p>
        </div>
      )
    },
    {
      header: 'Tag',
      accessorKey: 'test.tag',
      sortable: true,
      cell: (att) => (
        <span className="px-2 py-1 rounded-md bg-backgroundLight text-secondaryText text-xs font-medium">
          {att.test?.tag || '—'}
        </span>
      )
    },
    {
      header: 'Difficulty',
      accessorKey: 'test.difficulty',
      sortable: true,
      cell: (att) => (
        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${difficultyColors[att.test?.difficulty || ''] || 'bg-gray-100 text-gray-600'}`}>
          {att.test?.difficulty || '—'}
        </span>
      )
    },
    {
      header: 'Score',
      accessorKey: 'score',
      sortable: true,
      cell: (att) => (
        <div className="flex items-center gap-1.5">
          <Trophy size={14} className={getScoreColor(att.score, att.total_questions)} />
          <span className={`font-bold text-base ${getScoreColor(att.score, att.total_questions)}`}>
            {att.score != null ? att.score : '—'}
          </span>
          {att.total_questions > 0 && (
            <span className="text-secondaryText text-xs">/ {att.total_questions}</span>
          )}
        </div>
      )
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
          <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
            {attempts.length} Attempts
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
          data={attempts}
          columns={columns}
          searchPlaceholder="Search by user, test name or tag..."
          searchableKeys={['user.full_name', 'test.title', 'test.tag', 'user.mobile_number']}
          loading={loading}
          emptyStateMessage="No test attempts found"
          emptyStateIcon={<FileText size={36} className="text-border" />}
        />
      )}
    </div>
  );
};

export default AttemptedTests;
