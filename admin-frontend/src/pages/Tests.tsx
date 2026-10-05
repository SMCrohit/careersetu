import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, ChevronDown, Download, FileText, FileSpreadsheet, FileDown, Filter, ListOrdered } from 'lucide-react';
import { Link } from 'react-router-dom';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface TestModel {
  id: string;
  title: string;
  tag: string;
  description: string;
  difficulty: string;
  duration_mins: number;
  provider_name: string;
  test_mode?: string;
}

const defaultFormData = {
  title: '', tag: '', description: '', duration_mins: 60, 
  difficulty: 'Medium', provider_name: 'CareerSetu', test_mode: 'overall', max_discount_percentage: 0, questions: []
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

  const [tagFilter, setTagFilter] = useState('All');
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

  const filteredTestsByTag = tests.filter((t) => {
    if (tagFilter === 'All') return true;
    return t.tag && t.tag.split(',').map(tag => tag.trim()).includes(tagFilter);
  });

  // ─── Export helpers ────────────────────────────────────────────────────────
  const exportRows = filteredTestsByTag.map((t, i) => ({
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
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${filteredTestsByTag.length} tests`, 14, 22);

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
      test_mode: test.test_mode || 'overall',
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

  const columns: Column<TestModel>[] = [
    {
      header: 'Test Title',
      accessorKey: 'title',
      sortable: true,
      cell: (test) => <span className="font-medium text-primaryBrand">{test.title}</span>
    },
    {
      header: 'Tag',
      accessorKey: 'tag',
      sortable: true,
      cell: (test) => (
        <div className="flex flex-wrap gap-1">
          {test.tag ? test.tag.split(',').map(tag => (
            <span key={tag} className="px-2 py-0.5 bg-gray-100 text-gray-700 rounded text-[10px] font-medium border border-gray-200">
              {tag.trim()}
            </span>
          )) : <span className="text-secondaryText italic text-xs">No tag</span>}
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
      header: 'Description',
      accessorKey: 'description',
      sortable: true,
      cell: (test) => (
        <div className="max-w-[300px]">
          <p className="text-secondaryText text-sm truncate" title={test.description}>
            {test.description || 'No description'}
          </p>
          <p className="text-xs text-primaryText mt-1">
            <span className="opacity-70">Duration:</span> <span className="font-medium">{test.duration_mins} mins</span>
          </p>
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
          <button onClick={() => openEditModal(test)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
          <button onClick={() => { setItemToDelete(test.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
        </div>
      )
    }
  ];

  const toolbarExtras = (
    <div className="relative w-48">
      <Filter className="absolute left-3 top-2.5 text-borderDark" size={18} />
      <select
        value={tagFilter}
        onChange={(e) => setTagFilter(e.target.value)}
        className="input-field pl-10 pr-8 bg-white appearance-none cursor-pointer w-full"
      >
        <option value="All">All Tags</option>
        {TAG_OPTIONS.map(opt => <option key={opt} value={opt}>{opt}</option>)}
      </select>
      <ChevronDown className="absolute right-3 top-3 text-borderDark pointer-events-none" size={16} />
    </div>
  );

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

      <DataTable
        data={filteredTestsByTag}
        columns={columns}
        searchPlaceholder="Search tests..."
        searchableKeys={['title', 'description', 'tag']}
        loading={loading}
        emptyStateMessage="No tests found."
        toolbarExtras={toolbarExtras}
      />

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Test" : "Add New Test"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">Test Title</label>
              <input required type="text" className="input-field" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} />
            </div>
            
            <div className="col-span-2 relative" ref={tagDropdownRef}>
              <label className="block text-sm font-medium text-secondaryText mb-1">Tags (Multiple)</label>
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
                  {TAG_OPTIONS.map(option => {
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
              <label className="block text-sm font-medium text-secondaryText mb-1">Description</label>
              <textarea required rows={3} className="input-field" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Duration (Mins)</label>
              <input required type="number" min="1" className="input-field" value={formData.duration_mins} onChange={e => setFormData({...formData, duration_mins: parseInt(e.target.value)})} />
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
              <label className="block text-sm font-medium text-secondaryText mb-1">Test Mode</label>
              <select className="input-field bg-white" value={formData.test_mode} onChange={e => setFormData({...formData, test_mode: e.target.value})}>
                <option value="overall">Overall Time Limit</option>
                <option value="per_question">Per-Question Time Limit</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Provider Name</label>
              <input required type="text" className="input-field" value={formData.provider_name} onChange={e => setFormData({...formData, provider_name: e.target.value})} />
            </div>
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
        message="Are you sure you want to permanently delete this test and all its questions? This action cannot be undone." 
      />
    </div>
  );
};

export default Tests;
