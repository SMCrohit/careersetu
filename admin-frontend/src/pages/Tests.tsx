import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Search, ListOrdered, ChevronDown, Download, FileText, FileSpreadsheet, FileDown, Filter, ChevronLeft, ChevronRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const PAGE_SIZE_OPTIONS = [10, 50, 100];

interface TestModel {
  id: string;
  title: string;
  tag: string;
  description: string;
  difficulty: string;
  duration_mins: number;
  provider_name: string;
}

const defaultFormData = {
  title: '', tag: '', description: '', duration_mins: 60, 
  difficulty: 'Medium', provider_name: 'CareerSetu', max_discount_percentage: 0, questions: []
};

const TAG_OPTIONS = [
  'PROFESSIONAL', 'ENGINEER', 'IAS', 'IPS', 'TEACHER', 
  'LAWYER', 'NURSE', 'SOFTWARE_DEVELOPER', 'ACCOUNTANT', 
  'BANKER', 'OTHER'
];

const Tests = () => {
  const { showToast } = useToast();
  const [tests, setTests] = useState<TestModel[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  const [tagDropdownOpen, setTagDropdownOpen] = useState(false);
  const tagDropdownRef = useRef<HTMLDivElement>(null);

  const [search, setSearch] = useState('');
  const [tagFilter, setTagFilter] = useState('All');
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchTests();
  }, []);

  // Close tag multi-select dropdown
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (tagDropdownRef.current && !tagDropdownRef.current.contains(e.target as Node)) {
        setTagDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
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

  const fetchTests = async () => {
    try {
      const res = await api.get('/tests');
      setTests(res.data);
    } catch (error) {
      showToast("Failed to fetch tests", "error");
    } finally {
      setLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!itemToDelete) return;
    try {
      await api.delete(`/tests/${itemToDelete}`);
      setTests(tests.filter(t => t.id !== itemToDelete));
      showToast("Test deleted successfully", "success");
    } catch (error) {
      showToast("Failed to delete test", "error");
    }
    setItemToDelete(null);
  };

  const filteredTests = tests.filter((t) => {
    const matchesSearch = t.title.toLowerCase().includes(search.toLowerCase()) || 
                          (t.description || '').toLowerCase().includes(search.toLowerCase());
    const matchesTag = tagFilter === 'All' || (t.tag && t.tag.split(',').map(tag => tag.trim()).includes(tagFilter));
    return matchesSearch && matchesTag;
  });

  // Pagination
  const totalPages = Math.max(1, Math.ceil(filteredTests.length / pageSize));
  const safePage = Math.min(currentPage, totalPages);
  const paginated = filteredTests.slice((safePage - 1) * pageSize, safePage * pageSize);

  const handleSearchChange = (val: string) => {
    setSearch(val);
    setCurrentPage(1);
  };

  const handleTagFilterChange = (val: string) => {
    setTagFilter(val);
    setCurrentPage(1);
  };

  const handlePageSizeChange = (val: number) => {
    setPageSize(val);
    setCurrentPage(1);
  };

  // ─── Export helpers ────────────────────────────────────────────────────────
  const exportRows = filteredTests.map((t, i) => ({
    '#': i + 1,
    Title: t.title || '—',
    Tags: t.tag || '—',
    Difficulty: t.difficulty || '—',
    Duration: `${t.duration_mins} mins` || '—',
    Provider: t.provider_name || '—',
  }));

  const exportToCSV = () => {
    const headers = Object.keys(exportRows[0] || {});
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'tests.csv';
    a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Tests');
    XLSX.writeFile(wb, 'tests.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Tests Directory', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${filteredTests.length} tests`, 14, 22);

    autoTable(doc, {
      startY: 28,
      head: [['#', 'Title', 'Tags', 'Difficulty', 'Duration', 'Provider']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });

    doc.save('tests.pdf');
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

  const handleTagToggle = (option: string) => {
    const currentTags = formData.tag ? formData.tag.split(',').map(t => t.trim()).filter(Boolean) : [];
    if (currentTags.includes(option)) {
      setFormData({ ...formData, tag: currentTags.filter(t => t !== option).join(', ') });
    } else {
      setFormData({ ...formData, tag: [...currentTags, option].join(', ') });
    }
  };

  const openEditModal = (test: TestModel) => {
    setFormData({
      title: test.title,
      tag: test.tag,
      description: test.description,
      duration_mins: test.duration_mins,
      difficulty: test.difficulty,
      provider_name: test.provider_name || 'CareerSetu',
      max_discount_percentage: 0,
      questions: []
    });
    setEditingId(test.id);
    setIsModalOpen(true);
  };

  const openAddModal = () => {
    setFormData(defaultFormData);
    setEditingId(null);
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingId) {
        const res = await api.put(`/tests/${editingId}`, formData);
        setTests(tests.map(t => t.id === editingId ? res.data : t));
        showToast("Test updated successfully", "success");
      } else {
        const res = await api.post('/tests', formData);
        setTests([res.data, ...tests]);
        showToast("Test created successfully", "success");
      }
      setIsModalOpen(false);
      setFormData(defaultFormData);
      setEditingId(null);
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} test`, "error");
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Tests Management</h1>
          <p className="text-secondaryText">Manage all assessments and mock tests.</p>
        </div>
        <div className="flex items-center gap-3">
          {/* Export Button */}
          <div className="relative" ref={exportRef}>
            <button
              onClick={() => setExportOpen((o) => !o)}
              className="flex items-center gap-2 px-4 py-2.5 bg-white border border-border text-primaryText rounded-xl text-sm font-semibold hover:bg-gray-50 transition-colors shadow-sm"
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
          <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
            <Plus size={18} /> Add New Test
          </button>
        </div>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex flex-wrap justify-between items-center gap-3 bg-gray-50/50">
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative w-72">
              <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
              <input 
                type="text" 
                placeholder="Search tests..." 
                className="input-field pl-10 bg-white w-full" 
                value={search}
                onChange={(e) => handleSearchChange(e.target.value)}
              />
            </div>
            <div className="relative w-48">
              <Filter className="absolute left-3 top-2.5 text-borderDark" size={18} />
              <select
                value={tagFilter}
                onChange={(e) => handleTagFilterChange(e.target.value)}
                className="input-field pl-10 pr-8 bg-white appearance-none cursor-pointer w-full"
              >
                <option value="All">All Tags</option>
                {TAG_OPTIONS.map(opt => <option key={opt} value={opt}>{opt}</option>)}
              </select>
              <ChevronDown className="absolute right-3 top-3 text-borderDark pointer-events-none" size={16} />
            </div>
          </div>
          <span className="text-sm font-medium text-secondaryText">
            {filteredTests.length} {filteredTests.length === 1 ? 'test' : 'tests'}
          </span>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium">Test Title</th>
                <th className="p-4 font-medium">Tag</th>
                <th className="p-4 font-medium">Difficulty</th>
                <th className="p-4 font-medium">Description</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} className="text-center p-8 text-secondaryText">Loading tests...</td></tr>
              ) : paginated.length === 0 ? (
                <tr><td colSpan={5} className="text-center p-8 text-secondaryText">No tests found.</td></tr>
              ) : (
                paginated.map((test) => (
                  <tr key={test.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4 font-medium text-primaryBrand">{test.title}</td>
                    <td className="p-4 w-64 max-w-[16rem]">
                      <div className="line-clamp-2" style={{ lineHeight: '1.8' }}>
                        {test.tag ? test.tag.split(',').map(t => t.trim()).filter(Boolean).map(tag => (
                          <span key={tag} className="inline-block px-2 py-0.5 bg-highlight/10 text-highlight rounded-full text-xs font-medium mr-1 mb-1 whitespace-nowrap">
                            {tag}
                          </span>
                        )) : <span className="text-secondaryText text-xs">—</span>}
                      </div>
                    </td>
                    <td className="p-4 text-secondaryText">{test.difficulty}</td>
                    <td className="p-4 text-secondaryText truncate max-w-xs">{test.description}</td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <Link to={`/tests/${test.id}/questions`} title="Manage Questions" className="text-secondaryText hover:text-highlight transition-colors">
                          <ListOrdered size={16} />
                        </Link>
                        <button onClick={() => openEditModal(test)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
                        <button onClick={() => { setItemToDelete(test.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* ── Pagination ── */}
        {!loading && filteredTests.length > 0 && (
          <div className="px-4 py-4 border-t border-border flex flex-wrap items-center justify-between gap-3 bg-gray-50/30">
            <p className="text-sm text-secondaryText">
              Showing{' '}
              <span className="font-semibold text-primaryText">
                {(safePage - 1) * pageSize + 1}–{Math.min(safePage * pageSize, filteredTests.length)}
              </span>{' '}
              of{' '}
              <span className="font-semibold text-primaryText">{filteredTests.length}</span> tests
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

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Test" : "Add New Test"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">Test Title</label>
              <input required type="text" className="input-field" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} />
            </div>
            <div className="relative" ref={tagDropdownRef}>
              <label className="block text-sm font-medium text-secondaryText mb-1">Tags</label>
              <div 
                className="input-field flex flex-wrap gap-1 cursor-pointer min-h-[42px] items-center bg-white pr-8"
                onClick={() => setTagDropdownOpen(!tagDropdownOpen)}
              >
                {formData.tag ? (
                  formData.tag.split(',').map(t => t.trim()).filter(Boolean).map(tag => (
                    <span key={tag} className="px-2 py-0.5 bg-primaryBrand/10 text-primaryBrand rounded text-xs font-medium">
                      {tag}
                    </span>
                  ))
                ) : (
                  <span className="text-secondaryText text-sm opacity-70">Select tags...</span>
                )}
                <ChevronDown className="absolute right-3 top-[38px] text-borderDark pointer-events-none" size={16} />
              </div>
              {tagDropdownOpen && (
                <div className="absolute z-50 w-full mt-1 bg-white border border-border rounded-xl shadow-lg max-h-60 overflow-y-auto animate-fade-in py-1">
                  {TAG_OPTIONS.map(option => {
                    const isSelected = formData.tag ? formData.tag.split(',').map(t => t.trim()).includes(option) : false;
                    return (
                      <div 
                        key={option}
                        className="flex items-center gap-3 px-3 py-2 hover:bg-backgroundLight cursor-pointer"
                        onClick={() => handleTagToggle(option)}
                      >
                        <input type="checkbox" checked={isSelected} readOnly className="w-4 h-4 rounded text-primaryBrand focus:ring-primaryBrand/30 border-gray-300" />
                        <span className="text-sm text-primaryText font-medium">{option}</span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Difficulty</label>
              <select className="input-field bg-white" value={formData.difficulty} onChange={e => setFormData({...formData, difficulty: e.target.value})}>
                <option>Easy</option>
                <option>Medium</option>
                <option>Hard</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Duration (Minutes)</label>
              <input required type="number" min="1" className="input-field" value={formData.duration_mins} onChange={e => setFormData({...formData, duration_mins: parseInt(e.target.value) || 0})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Provider Name</label>
              <input required type="text" className="input-field" value={formData.provider_name} onChange={e => setFormData({...formData, provider_name: e.target.value})} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Description</label>
            <textarea required rows={4} className="input-field" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
          </div>
          <div className="flex justify-end gap-3 mt-6">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium">Cancel</button>
            <button type="submit" className="btn-primary">{editingId ? 'Update Test' : 'Save Test'}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Test" 
        message="Are you sure you want to permanently delete this test? This action cannot be undone." 
      />
    </div>
  );
};

export default Tests;
