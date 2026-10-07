import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, ChevronDown, Download, FileText, FileSpreadsheet, FileDown, Filter, ListOrdered, ArrowLeft, X } from 'lucide-react';
import { Link } from 'react-router-dom';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface TestModel {
  id: string;
  title: string;
  description: string;
  test_type: string;
  category: string;
  tag: string;
  difficulty: string;
  duration_mins: number;
  test_mode: string;
  default_per_question_seconds: number;
  provider_name: string;
  provider_logo_url?: string;
  is_open: boolean;
  open_link_token?: string;
  max_attempts: number;
  show_result_mode: string;
  pass_percentage: number;
  negative_marking: boolean;
  negative_marks_per_wrong: number;
  shuffle_questions: boolean;
  shuffle_options: boolean;
  show_answer_after: string;
  instructions?: string;
  status: string;
  scheduled_start_at?: string;
  scheduled_end_at?: string;
  certificate_on_pass: boolean;
  questions?: any[];
  created_datetime?: string;
}

const defaultFormData = {
  title: '', description: '', test_type: 'practice', category: 'aptitude', tag: '',
  difficulty: 'Medium', duration_mins: 60, test_mode: 'overall', default_per_question_seconds: 60, provider_name: 'CareerSetu',
  provider_logo_url: '', is_open: false, max_attempts: 0, show_result_mode: 'best_score',
  pass_percentage: 60, negative_marking: false, negative_marks_per_wrong: 0.25,
  shuffle_questions: false, shuffle_options: false, show_answer_after: 'after_submit',
  instructions: '', status: 'draft', certificate_on_pass: false,
  questions: [] as any[], open_link_token: ''
};

interface Goal {
  id: string;
  name: string;
}

interface TestCategory {
  id: string;
  name: string;
}

const TEST_TYPES = ['company_hiring', 'practice'];

const Tests = () => {
  const { showToast } = useToast();
  const [tests, setTests] = useState<TestModel[]>([]);
  const [goals, setGoals] = useState<Goal[]>([]);
  const [categories, setCategories] = useState<TestCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  const [isFormView, setIsFormView] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  const [tagDropdownOpen, setTagDropdownOpen] = useState(false);
  const tagDropdownRef = useRef<HTMLDivElement>(null);
  const [isFilterPanelOpen, setIsFilterPanelOpen] = useState(false);
  const [filterProfession, setFilterProfession] = useState('All');
  const [filterType, setFilterType] = useState('All');
  const [filterCategory, setFilterCategory] = useState('All');
  const [filterStatus, setFilterStatus] = useState('All');
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  const [currentPage, setCurrentPage] = useState(1);
  const [currentLimit, setCurrentLimit] = useState(10);
  const [serverTotal, setServerTotal] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const fetchMetadata = async () => {
      try {
        const [goalsRes, categoriesRes] = await Promise.all([
          api.get('/goals'),
          api.get('/test-categories')
        ]);
        setGoals(goalsRes.data);
        setCategories(categoriesRes.data);
      } catch (error) {
        console.error("Failed to fetch metadata", error);
      }
    };
    fetchMetadata();
    fetchTestsWithParams(1, '', 10, 'All', 'All', 'All', 'All');
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

  const fetchTestsWithParams = async (
    page: number = currentPage, 
    search: string = searchTerm, 
    limit: number = currentLimit,
    prof: string = filterProfession,
    type: string = filterType,
    cat: string = filterCategory,
    stat: string = filterStatus
  ) => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      params.append('page', page.toString());
      params.append('limit', limit.toString());
      if (search) params.append('search', search);
      if (prof !== 'All') params.append('profession', prof);
      if (type !== 'All') params.append('test_type', type);
      if (cat !== 'All') params.append('category', cat);
      if (stat !== 'All') params.append('status', stat);
      
      const res = await api.get(`/admin/tests?${params.toString()}`);
      setTests(res.data.data);
      setServerTotal(res.data.total);
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
      showToast("Test deleted successfully", "success");
      fetchTestsWithParams();
    } catch (error) {
      showToast("Failed to delete test", "error");
    }
    setItemToDelete(null);
    setDeleteDialogOpen(false);
  };

  const exportRows = tests.map((t, i) => ({
    '#': i + 1,
    Title: t.title || '—',
    Type: t.test_type || '—',
    Tags: t.tag || '—',
    Difficulty: t.difficulty || '—',
    Duration: t.test_mode === 'per_question' ? 'Per Q' : (t.duration_mins ? `${t.duration_mins} mins` : '—'),
    Provider: t.provider_name || '—',
    Status: t.status || '—',
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
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${serverTotal} tests`, 14, 22);

    autoTable(doc, {
      startY: 28,
      head: [['#', 'Title', 'Type', 'Tags', 'Difficulty', 'Duration', 'Provider', 'Status']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });

    doc.save('tests.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const handleTagToggle = (option: string) => {
    const currentTags = formData.tag ? formData.tag.split(',').map(t => t.trim()).filter(Boolean) : [];
    if (currentTags.includes(option)) {
      setFormData({ ...formData, tag: currentTags.filter(t => t !== option).join(', ') });
    } else {
      setFormData({ ...formData, tag: [...currentTags, option].join(', ') });
    }
  };

  const openEditForm = (test: TestModel) => {
    setFormData({
      title: test.title || '',
      description: test.description || '',
      test_type: test.test_type || 'practice',
      category: test.category || 'aptitude',
      tag: test.tag || '',
      difficulty: test.difficulty || 'Medium',
      duration_mins: test.duration_mins || 60,
      test_mode: test.test_mode || 'overall',
      default_per_question_seconds: test.default_per_question_seconds || 60,
      provider_name: test.provider_name || 'CareerSetu',
      provider_logo_url: test.provider_logo_url || '',
      is_open: test.is_open || false,
      max_attempts: test.max_attempts || 0,
      show_result_mode: test.show_result_mode || 'best_score',
      pass_percentage: test.pass_percentage || 60,
      negative_marking: test.negative_marking || false,
      negative_marks_per_wrong: test.negative_marks_per_wrong || 0.25,
      shuffle_questions: test.shuffle_questions || false,
      shuffle_options: test.shuffle_options || false,
      show_answer_after: test.show_answer_after || 'after_submit',
      instructions: test.instructions || '',
      status: test.questions && test.questions.length > 0 ? (test.status || 'draft') : 'draft',
      certificate_on_pass: test.certificate_on_pass || false,
      questions: test.questions || [],
      open_link_token: test.open_link_token || ''
    });
    setEditingId(test.id);
    setIsFormView(true);
  };

  const openAddForm = () => {
    setFormData(defaultFormData);
    setEditingId(null);
    setIsFormView(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
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
      setIsFormView(false);
      setFormData(defaultFormData);
      setEditingId(null);
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} test`, "error");
    } finally {
      setSaving(false);
    }
  };

  const columns: Column<TestModel>[] = [
    {
      header: 'Test Info',
      accessorKey: 'title',
      sortable: true,
      cell: (test) => (
        <div>
          <span className="font-medium text-primaryBrand block">{test.title}</span>
          <div className="flex flex-wrap gap-1 mt-1">
            {test.tag ? test.tag.split(',').map(tag => (
              <span key={tag} className="px-1.5 py-0.5 bg-gray-100 text-gray-700 rounded text-[10px] font-medium border border-gray-200">
                {tag.trim()}
              </span>
            )) : <span className="text-secondaryText italic text-xs">No tag</span>}
          </div>
        </div>
      )
    },
    {
      header: 'Type & Category',
      accessorKey: 'test_type',
      sortable: true,
      cell: (test) => (
        <div>
          <span className="capitalize text-sm font-medium">{test.test_type?.replace('_', ' ')}</span>
          <span className="text-xs text-secondaryText block capitalize">{test.category}</span>
        </div>
      )
    },
    {
      header: 'Difficulty',
      accessorKey: 'difficulty',
      sortable: true,
      cell: (test) => (
        <span className={`px-2 py-1 rounded-full text-xs font-medium border ${
          test.difficulty === 'Easy' ? 'bg-green-50 text-green-700 border-green-200' : 
          test.difficulty === 'Hard' ? 'bg-red-50 text-red-700 border-red-200' : 
          'bg-orange-50 text-orange-700 border-orange-200'
        }`}>
          {test.difficulty}
        </span>
      )
    },
    {
      header: 'Status',
      accessorKey: 'status',
      sortable: true,
      cell: (test) => (
        <span className={`px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
          test.status === 'published' ? 'bg-green-100 text-green-800' : 
          test.status === 'archived' ? 'bg-gray-200 text-gray-800' :
          'bg-yellow-100 text-yellow-800'
        }`}>
          {test.status || 'draft'}
        </span>
      )
    },
    {
      header: 'Details',
      cell: (test) => (
        <div className="text-xs">
          <p><span className="text-secondaryText">Dur:</span> <span className="font-medium">{test.test_mode === 'per_question' ? 'Per Q' : (test.duration_mins ? `${test.duration_mins}m` : '—')}</span></p>
          <p><span className="text-secondaryText">By:</span> <span className="font-medium">{test.provider_name}</span></p>
        </div>
      )
    },
    {
      header: 'Actions',
      cell: (test) => (
        <div className="flex items-center justify-end gap-3">
          <Link to={`/tests/${test.id}/questions`} className="text-primaryBrand hover:text-blue-700 transition-colors flex items-center gap-1 text-sm font-medium mr-2">
            <ListOrdered size={16} /> Manage Qs
          </Link>
          <button onClick={() => openEditForm(test)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
          <button onClick={() => { setItemToDelete(test.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
        </div>
      )
    }
  ];

  const activeFiltersCount = [filterProfession, filterType, filterCategory, filterStatus].filter(f => f !== 'All').length;

  const toolbarExtras = (
    <button onClick={() => setIsFilterPanelOpen(true)} className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 flex items-center gap-2 font-medium">
      <Filter size={18} /> Filters
      {activeFiltersCount > 0 && (
        <span className="w-5 h-5 bg-primaryBrand text-white text-[10px] flex items-center justify-center rounded-full">
          {activeFiltersCount}
        </span>
      )}
    </button>
  );

  return (
    <div className="animate-fade-in pb-10">
      {!isFormView ? (
        <>
          <div className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-2xl font-bold text-primaryText">Tests Management</h1>
              <p className="text-secondaryText">Manage all assessments and mock tests.</p>
            </div>
            <div className="flex items-center gap-3">
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
              <button onClick={openAddForm} className="btn-primary flex items-center gap-2">
                <Plus size={18} /> Add New Test
              </button>
            </div>
          </div>

          {/* Filters Side Panel */}
          {isFilterPanelOpen && (
            <div className="fixed inset-0 z-50 flex justify-end">
              <div className="absolute inset-0 bg-black/50" onClick={() => setIsFilterPanelOpen(false)}></div>
              <div className="relative w-80 bg-white h-full shadow-2xl flex flex-col animate-slide-in-right">
                <div className="flex justify-between items-center p-4 border-b border-border">
                  <h2 className="text-lg font-bold text-primaryText">Filters</h2>
                  <button onClick={() => setIsFilterPanelOpen(false)} className="text-secondaryText hover:text-primaryText"><X size={20} /></button>
                </div>
                <div className="p-4 flex-1 overflow-y-auto space-y-6">
                  
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Target Profession</label>
                    <div className="relative">
                      <select 
                        value={filterProfession} 
                        onChange={e => setFilterProfession(e.target.value)}
                        className="input-field bg-white appearance-none w-full pr-8"
                      >
                        <option value="All">All Professions</option>
                        {goals.map(g => <option key={g.id} value={g.name}>{g.name}</option>)}
                      </select>
                      <ChevronDown className="absolute right-3 top-3 text-gray-400 pointer-events-none" size={16} />
                    </div>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Test Type</label>
                    <div className="relative">
                      <select 
                        value={filterType} 
                        onChange={e => setFilterType(e.target.value)}
                        className="input-field bg-white appearance-none w-full pr-8"
                      >
                        <option value="All">All Types</option>
                        {TEST_TYPES.map(t => <option key={t} value={t}>{t === 'company_hiring' ? 'Company Hiring' : 'Practice'}</option>)}
                      </select>
                      <ChevronDown className="absolute right-3 top-3 text-gray-400 pointer-events-none" size={16} />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Category</label>
                    <div className="relative">
                      <select 
                        value={filterCategory} 
                        onChange={e => setFilterCategory(e.target.value)}
                        className="input-field bg-white appearance-none w-full pr-8"
                      >
                        <option value="All">All Categories</option>
                        {categories.map(c => <option key={c.id} value={c.name}>{c.name}</option>)}
                      </select>
                      <ChevronDown className="absolute right-3 top-3 text-gray-400 pointer-events-none" size={16} />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Status</label>
                    <div className="relative">
                      <select 
                        value={filterStatus} 
                        onChange={e => setFilterStatus(e.target.value)}
                        className="input-field bg-white appearance-none w-full pr-8"
                      >
                        <option value="All">All Statuses</option>
                        <option value="draft">Draft</option>
                        <option value="published">Published</option>
                        <option value="archived">Archived</option>
                      </select>
                      <ChevronDown className="absolute right-3 top-3 text-gray-400 pointer-events-none" size={16} />
                    </div>
                  </div>

                </div>
                <div className="p-4 border-t border-border flex justify-end gap-3">
                  <button 
                    onClick={() => {
                      setFilterProfession('All');
                      setFilterType('All');
                      setFilterCategory('All');
                      setFilterStatus('All');
                      setCurrentPage(1);
                      fetchTestsWithParams(1, searchTerm, currentLimit, 'All', 'All', 'All', 'All');
                      setIsFilterPanelOpen(false);
                    }}
                    className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 font-medium"
                  >
                    Clear Filters
                  </button>
                  <button 
                    onClick={() => {
                      setCurrentPage(1);
                      fetchTestsWithParams(1, searchTerm, currentLimit, filterProfession, filterType, filterCategory, filterStatus);
                      setIsFilterPanelOpen(false);
                    }} 
                    className="btn-primary"
                  >
                    Apply
                  </button>
                </div>
              </div>
            </div>
          )}

          <DataTable
            data={tests}
            columns={columns}
            searchPlaceholder="Search tests..."
            searchableKeys={['title', 'description', 'tag', 'provider_name']}
            loading={loading}
            emptyStateMessage="No tests found."
            toolbarExtras={toolbarExtras}
            serverSideMode={true}
            serverSideTotal={serverTotal}
            serverSidePage={currentPage}
            onPageChange={(page) => {
              setCurrentPage(page);
              fetchTestsWithParams(page, searchTerm, currentLimit, filterProfession, filterType, filterCategory, filterStatus);
            }}
            onSearchChange={(search) => {
              setSearchTerm(search);
              setCurrentPage(1);
              fetchTestsWithParams(1, search, currentLimit, filterProfession, filterType, filterCategory, filterStatus);
            }}
            onPageSizeChange={(size) => {
              setCurrentLimit(size);
              setCurrentPage(1);
              fetchTestsWithParams(1, searchTerm, size, filterProfession, filterType, filterCategory, filterStatus);
            }}
          />
        </>
      ) : (
        <div className="bg-white rounded-xl shadow-sm border border-border overflow-hidden">
          <div className="flex items-center p-6 border-b border-border bg-gray-50/50">
            <button onClick={() => setIsFormView(false)} className="text-secondaryText hover:text-primaryText transition-colors p-2 -ml-2 rounded-lg hover:bg-gray-100 flex items-center gap-2 font-medium">
              <ArrowLeft size={20} /> Back
            </button>
            <div className="h-6 w-px bg-border mx-2"></div>
            <div>
              <h2 className="text-xl font-bold text-primaryText">{editingId ? "Edit Test" : "Add New Test"}</h2>
            </div>
          </div>
          
          <form onSubmit={handleSubmit} className="p-8 space-y-10">
            
            {/* Section 1: Basic Information */}
            <div className="space-y-6">
              <h3 className="text-lg font-bold text-primaryText border-b border-border pb-2">1. Basic Information</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-secondaryText mb-1">Test Title *</label>
                  <input required type="text" className="input-field" placeholder="e.g. TCS NQT Mock Test" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} />
                </div>
                
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-secondaryText mb-1">Description *</label>
                  <textarea required rows={3} className="input-field" placeholder="Describe the test..." value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
                </div>

                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Test Type</label>
                  <select className="input-field bg-white capitalize" value={formData.test_type} onChange={e => setFormData({...formData, test_type: e.target.value})}>
                    {TEST_TYPES.map(type => <option key={type} value={type}>{type.replace('_', ' ')}</option>)}
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Category</label>
                  <select className="input-field bg-white capitalize" value={formData.category} onChange={e => setFormData({...formData, category: e.target.value})}>
                    {categories.length === 0 && <option value="aptitude">Aptitude</option>}
                    {categories.map(cat => <option key={cat.id} value={cat.name}>{cat.name}</option>)}
                  </select>
                </div>
                
                <div className="col-span-2 relative" ref={tagDropdownRef}>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Tags (Target Professions)</label>
                  <div 
                    className="input-field min-h-[42px] cursor-pointer flex flex-wrap gap-2 items-center"
                    onClick={() => setTagDropdownOpen(!tagDropdownOpen)}
                  >
                    {formData.tag ? (
                      formData.tag.split(',').map(t => t.trim()).filter(Boolean).map(t => (
                        <span key={t} className="px-2 py-1 bg-highlight/10 text-highlight rounded text-xs font-medium border border-highlight/20 flex items-center gap-1">
                          {t}
                          <button 
                            type="button" 
                            onClick={(e) => { e.stopPropagation(); handleTagToggle(t); }}
                            className="hover:text-primaryBrand transition-colors"
                          >
                            ×
                          </button>
                        </span>
                      ))
                    ) : (
                      <span className="text-borderDark">Select tags...</span>
                    )}
                  </div>
                  {tagDropdownOpen && (
                    <div className="absolute z-10 w-full mt-1 bg-white border border-border rounded-lg shadow-lg max-h-60 overflow-y-auto">
                      {goals.map(goal => {
                        const option = goal.name;
                        const isSelected = formData.tag?.split(',').map(t => t.trim()).includes(option);
                        return (
                          <div 
                            key={option}
                            className="flex items-center px-4 py-2 hover:bg-gray-50 cursor-pointer"
                            onClick={() => handleTagToggle(option)}
                          >
                            <input 
                              type="checkbox" 
                              checked={isSelected}
                              readOnly
                              className="mr-3 rounded text-primaryBrand focus:ring-primaryBrand"
                            />
                            <span className="text-sm text-primaryText">{option}</span>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>

                <div className="col-span-2">
                  <label className="block text-sm font-medium text-secondaryText mb-1">Instructions (Optional)</label>
                  <textarea rows={3} className="input-field" placeholder="Pre-test instructions for students..." value={formData.instructions} onChange={e => setFormData({...formData, instructions: e.target.value})}></textarea>
                </div>
              </div>
            </div>

            {/* Section 2: Configuration & Rules */}
            <div className="space-y-6">
              <h3 className="text-lg font-bold text-primaryText border-b border-border pb-2">2. Test Configuration & Rules</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Test Mode</label>
                  <select className="input-field bg-white" value={formData.test_mode} onChange={e => setFormData({...formData, test_mode: e.target.value})}>
                    <option value="overall">Overall Time Limit</option>
                    <option value="per_question">Per-Question Time Limit</option>
                  </select>
                </div>
                
                {formData.test_mode === 'overall' ? (
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Duration (Mins) *</label>
                    <input required type="number" min="1" className="input-field" value={formData.duration_mins} onChange={e => setFormData({...formData, duration_mins: parseInt(e.target.value) || 0})} />
                  </div>
                ) : (
                  <>
                    <div>
                      <label className="block text-sm font-medium text-secondaryText mb-1">Time per question (Seconds) *</label>
                      <input required type="number" min="1" className="input-field border-primaryBrand bg-primaryBrand/5" value={formData.default_per_question_seconds} onChange={e => setFormData({...formData, default_per_question_seconds: parseInt(e.target.value) || 0})} />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-secondaryText mb-1">Duration (Mins)</label>
                      <input type="text" disabled className="input-field bg-gray-100 text-gray-500 cursor-not-allowed" value="Auto-calculated from questions" />
                    </div>
                  </>
                )}

                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Difficulty</label>
                  <select className="input-field bg-white" value={formData.difficulty} onChange={e => setFormData({...formData, difficulty: e.target.value})}>
                    <option>Easy</option>
                    <option>Medium</option>
                    <option>Hard</option>
                  </select>
                </div>

                <div className="col-span-1 md:col-span-2">
                  <label className="block text-sm font-medium text-secondaryText mb-1">Status</label>
                  <div className="flex flex-col gap-2">
                    <select 
                      className={`input-field bg-white ${!(formData.questions && formData.questions.length > 0) ? 'bg-gray-100 cursor-not-allowed text-gray-500' : ''}`} 
                      value={formData.status} 
                      onChange={e => setFormData({...formData, status: e.target.value})}
                      disabled={!(formData.questions && formData.questions.length > 0)}
                    >
                      <option value="draft">Draft (Hidden)</option>
                      <option value="published">Published</option>
                      <option value="archived">Archived</option>
                    </select>
                    {!(formData.questions && formData.questions.length > 0) && (
                      <p className="text-xs text-amber-600 font-medium bg-amber-50 p-2 rounded border border-amber-100 flex items-center gap-1.5">
                        <span className="text-amber-500">ℹ</span> You must add at least one question to this test before you can publish it.
                      </p>
                    )}
                  </div>
                </div>

                <div className="col-span-3 grid grid-cols-1 md:grid-cols-2 gap-4 bg-gray-50 p-4 rounded-lg border border-border mt-2">
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" className="w-4 h-4 rounded text-primaryBrand" checked={formData.shuffle_questions} onChange={e => setFormData({...formData, shuffle_questions: e.target.checked})} />
                    <span className="text-sm font-medium text-primaryText">Shuffle Questions Order</span>
                  </label>
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" className="w-4 h-4 rounded text-primaryBrand" checked={formData.shuffle_options} onChange={e => setFormData({...formData, shuffle_options: e.target.checked})} />
                    <span className="text-sm font-medium text-primaryText">Shuffle MCQ Options</span>
                  </label>
                </div>

              </div>
            </div>

            {/* Section 3: Grading & Results */}
            <div className="space-y-6">
              <h3 className="text-lg font-bold text-primaryText border-b border-border pb-2">3. Grading & Results</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Pass Percentage (%)</label>
                  <input type="number" min="0" max="100" className="input-field" value={formData.pass_percentage} onChange={e => setFormData({...formData, pass_percentage: parseInt(e.target.value) || 0})} />
                </div>

                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Max Attempts (0 = unlimited)</label>
                  <input type="number" min="0" className="input-field" value={formData.max_attempts} onChange={e => setFormData({...formData, max_attempts: parseInt(e.target.value) || 0})} />
                </div>

                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Show Result Mode</label>
                  <select className="input-field bg-white" value={formData.show_result_mode} onChange={e => setFormData({...formData, show_result_mode: e.target.value})}>
                    <option value="best_score">Highest / Best Score</option>
                    <option value="last_attempt">Latest Attempt Only</option>
                    <option value="first_attempt">First Attempt Only</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Show Correct Answers</label>
                  <select className="input-field bg-white" value={formData.show_answer_after} onChange={e => setFormData({...formData, show_answer_after: e.target.value})}>
                    <option value="after_submit">After Submitting Test</option>
                    <option value="immediately">Immediately After Answer</option>
                    <option value="never">Never Show Answers</option>
                  </select>
                </div>

                <div className="col-span-2 bg-red-50/50 p-4 rounded-lg border border-red-100 flex flex-col md:flex-row gap-4 items-center">
                  <label className="flex items-center gap-3 cursor-pointer min-w-max">
                    <input type="checkbox" className="w-4 h-4 rounded text-red-600 focus:ring-red-500" checked={formData.negative_marking} onChange={e => setFormData({...formData, negative_marking: e.target.checked})} />
                    <span className="text-sm font-bold text-red-800">Enable Negative Marking</span>
                  </label>
                  {formData.negative_marking && (
                    <div className="flex-1 flex items-center gap-3 w-full">
                      <span className="text-sm text-red-700 font-medium">Default negative marks per wrong answer:</span>
                      <input type="number" step="0.01" min="0" className="input-field bg-white max-w-[120px]" value={formData.negative_marks_per_wrong} onChange={e => setFormData({...formData, negative_marks_per_wrong: parseFloat(e.target.value) || 0})} />
                    </div>
                  )}
                </div>

                <div className="col-span-2">
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" className="w-4 h-4 rounded text-primaryBrand" checked={formData.certificate_on_pass} onChange={e => setFormData({...formData, certificate_on_pass: e.target.checked})} />
                    <span className="text-sm font-medium text-primaryText">Generate Certificate on Passing</span>
                  </label>
                </div>

              </div>
            </div>

            {/* Section 4: Provider & Access */}
            <div className="space-y-6">
              <h3 className="text-lg font-bold text-primaryText border-b border-border pb-2">4. Provider & Access</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Provider Name *</label>
                  <input required type="text" className="input-field" placeholder="e.g. TCS" value={formData.provider_name} onChange={e => setFormData({...formData, provider_name: e.target.value})} />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Provider Logo URL</label>
                  <input type="url" className="input-field" placeholder="https://..." value={formData.provider_logo_url} onChange={e => setFormData({...formData, provider_logo_url: e.target.value})} />
                </div>

                <div className="col-span-2 bg-blue-50/50 p-5 rounded-lg border border-blue-100 space-y-4">
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" className="w-5 h-5 rounded text-blue-600 focus:ring-blue-500" checked={formData.is_open} onChange={e => setFormData({...formData, is_open: e.target.checked})} />
                    <span className="text-base font-bold text-blue-900">Make this an Open Test (No Login Required)</span>
                  </label>
                  <p className="text-sm text-blue-700 ml-8">Allows anyone with the link to take the test anonymously without creating an account.</p>
                  
                  {formData.is_open && (
                    <div className="ml-8 mt-2">
                      <label className="block text-xs font-medium text-blue-800 mb-1">Deep Link Token (Auto-generated on save)</label>
                      <input 
                        type="text" 
                        readOnly 
                        className="input-field bg-blue-100/50 text-blue-900 font-mono text-sm" 
                        value={formData.open_link_token || 'Will be generated after saving'} 
                      />
                    </div>
                  )}
                </div>

              </div>
            </div>
            
            <div className="flex justify-end gap-3 pt-6 border-t border-border mt-8">
              <button type="button" onClick={() => setIsFormView(false)} className="px-4 py-2 text-secondaryText font-medium hover:bg-gray-100 rounded-lg">Cancel</button>
              <button type="submit" disabled={saving} className="btn-primary">
                {saving ? 'Saving...' : (editingId ? 'Update Test' : 'Save Test')}
              </button>
            </div>
          </form>
        </div>
      )}

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Test" 
        message="Are you sure you want to permanently delete this test and all its questions? This action cannot be undone." 
      />
    </div>
  );
};

export default Tests;
