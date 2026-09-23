import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Search, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, Filter, ChevronLeft, ChevronRight } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const PAGE_SIZE_OPTIONS = [10, 50, 100];

interface Professional {
  id: string;
  name: string;
  profession: string;
  specialty: string;
  clinic: string;
  experience: string;
  consultation_fee: number;
  image_url?: string;
  description?: string;
  default_rating: number;
}

const defaultFormData = {
  name: '', profession: 'Doctor', specialty: '', clinic: '', experience: '', consultation_fee: 500, image_url: '', description: '', default_rating: 4.5
};

const Professionals = () => {
  const { showToast } = useToast();
  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [professionFilter, setProfessionFilter] = useState('All');
  const [pageSize, setPageSize] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  useEffect(() => {
    fetchProfessionals();
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

  const fetchProfessionals = async () => {
    try {
      const res = await api.get('/professionals');
      setProfessionals(res.data);
    } catch (error) {
      showToast("Failed to fetch professionals", "error");
    } finally {
      setLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!itemToDelete) return;
    try {
      await api.delete(`/professionals/${itemToDelete}`);
      setProfessionals(professionals.filter(d => d.id !== itemToDelete));
      showToast("Professional deleted successfully", "success");
    } catch (error) {
      showToast("Failed to delete professional", "error");
    }
    setItemToDelete(null);
  };

  const filteredProfessionals = professionals.filter((p) => {
    const matchesSearch = p.name.toLowerCase().includes(search.toLowerCase()) || 
                          (p.specialty || '').toLowerCase().includes(search.toLowerCase()) || 
                          (p.clinic || '').toLowerCase().includes(search.toLowerCase());
    const matchesProfession = professionFilter === 'All' || p.profession === professionFilter || (!p.profession && professionFilter === 'Doctor');
    return matchesSearch && matchesProfession;
  });

  // Pagination
  const totalPages = Math.max(1, Math.ceil(filteredProfessionals.length / pageSize));
  const safePage = Math.min(currentPage, totalPages);
  const paginated = filteredProfessionals.slice((safePage - 1) * pageSize, safePage * pageSize);

  const handleSearchChange = (val: string) => {
    setSearch(val);
    setCurrentPage(1);
  };

  const handleProfessionChange = (val: string) => {
    setProfessionFilter(val);
    setCurrentPage(1);
  };

  const handlePageSizeChange = (val: number) => {
    setPageSize(val);
    setCurrentPage(1);
  };

  // ─── Export helpers ────────────────────────────────────────────────────────
  const exportRows = filteredProfessionals.map((p, i) => ({
    '#': i + 1,
    Name: p.name || '—',
    Profession: p.profession || 'Doctor',
    'Specialty/Role': p.specialty || '—',
    'Clinic/Firm': p.clinic || '—',
    Experience: p.experience || '—',
    Fee: p.consultation_fee != null ? `₹${p.consultation_fee}` : '—',
  }));

  const exportToCSV = () => {
    const headers = Object.keys(exportRows[0] || {});
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'professionals.csv';
    a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Professionals');
    XLSX.writeFile(wb, 'professionals.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Professionals Directory', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${filteredProfessionals.length} professionals`, 14, 22);

    autoTable(doc, {
      startY: 28,
      head: [['#', 'Name', 'Profession', 'Specialty', 'Clinic', 'Experience', 'Fee']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });

    doc.save('professionals.pdf');
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

  const openEditModal = (doc: Professional) => {
    setFormData({
      name: doc.name,
      profession: doc.profession || 'Doctor',
      specialty: doc.specialty,
      clinic: doc.clinic,
      experience: doc.experience,
      consultation_fee: doc.consultation_fee,
      image_url: doc.image_url || '',
      description: doc.description || '',
      default_rating: doc.default_rating || 0
    });
    setEditingId(doc.id);
    setIsModalOpen(true);
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        showToast("Image must be less than 5MB", "error");
        e.target.value = '';
        return;
      }
      const reader = new FileReader();
      reader.onloadend = () => {
        setFormData({ ...formData, image_url: reader.result as string });
      };
      reader.readAsDataURL(file);
    }
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
        const res = await api.put(`/professionals/${editingId}`, formData);
        setProfessionals(professionals.map(d => d.id === editingId ? res.data : d));
        showToast("Professional updated successfully", "success");
      } else {
        const res = await api.post('/professionals', formData);
        setProfessionals([res.data, ...professionals]);
        showToast("Professional created successfully", "success");
      }
      setIsModalOpen(false);
      setFormData(defaultFormData);
      setEditingId(null);
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} professional`, "error");
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Professionals Directory</h1>
          <p className="text-secondaryText">Manage professionals and clinics available for booking.</p>
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
            <Plus size={18} /> Add Professional
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
                placeholder="Search professionals..." 
                className="input-field pl-10 bg-white w-full"
                value={search}
                onChange={(e) => handleSearchChange(e.target.value)}
              />
            </div>
            <div className="relative w-48">
              <Filter className="absolute left-3 top-2.5 text-borderDark" size={18} />
              <select
                value={professionFilter}
                onChange={(e) => handleProfessionChange(e.target.value)}
                className="input-field pl-10 pr-8 bg-white appearance-none cursor-pointer w-full"
              >
                <option value="All">All Professions</option>
                <option value="Doctor">Doctor</option>
                <option value="CA">CA</option>
                <option value="Developer">Developer</option>
                <option value="Teacher">Teacher</option>
                <option value="Professor">Professor</option>
                <option value="Lawyer">Lawyer</option>
                <option value="Consultant">Consultant</option>
              </select>
              <ChevronDown className="absolute right-3 top-3 text-borderDark pointer-events-none" size={16} />
            </div>
          </div>
          <span className="text-sm font-medium text-secondaryText">
            {filteredProfessionals.length} {filteredProfessionals.length === 1 ? 'professional' : 'professionals'}
          </span>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium">Image</th>
                <th className="p-4 font-medium">Name</th>
                <th className="p-4 font-medium">Profession</th>
                <th className="p-4 font-medium">Specialty/Role</th>
                <th className="p-4 font-medium">Clinic/Firm</th>
                <th className="p-4 font-medium">Experience</th>
                <th className="p-4 font-medium">Fee</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={8} className="text-center p-8 text-secondaryText">Loading professionals...</td></tr>
              ) : paginated.length === 0 ? (
                <tr><td colSpan={8} className="text-center p-8 text-secondaryText">No professionals found.</td></tr>
              ) : (
                paginated.map((doc) => (
                  <tr key={doc.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4">
                      {doc.image_url ? (
                        <img src={doc.image_url} alt={doc.name} className="w-10 h-10 rounded-full object-cover border border-border" />
                      ) : (
                        <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center text-gray-500 font-bold text-sm">
                          {doc.name.charAt(0)}
                        </div>
                      )}
                    </td>
                    <td className="p-4 font-medium text-primaryBrand">{doc.name}</td>
                    <td className="p-4"><span className="px-2.5 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium border border-gray-200">{doc.profession || 'Doctor'}</span></td>
                    <td className="p-4 text-primaryText">{doc.specialty}</td>
                    <td className="p-4 text-secondaryText">{doc.clinic}</td>
                    <td className="p-4 text-secondaryText">{doc.experience}</td>
                    <td className="p-4 text-success font-medium">₹{doc.consultation_fee}</td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button onClick={() => openEditModal(doc)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
                        <button onClick={() => { setItemToDelete(doc.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* ── Pagination ── */}
        {!loading && filteredProfessionals.length > 0 && (
          <div className="px-4 py-4 border-t border-border flex flex-wrap items-center justify-between gap-3 bg-gray-50/30">
            <p className="text-sm text-secondaryText">
              Showing{' '}
              <span className="font-semibold text-primaryText">
                {(safePage - 1) * pageSize + 1}–{Math.min(safePage * pageSize, filteredProfessionals.length)}
              </span>{' '}
              of{' '}
              <span className="font-semibold text-primaryText">{filteredProfessionals.length}</span> professionals
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

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Professional" : "Add New Professional"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2 flex items-center gap-4 mb-2">
              {formData.image_url ? (
                <img src={formData.image_url} alt="Preview" className="w-16 h-16 rounded-full object-cover border border-border" />
              ) : (
                <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center border border-dashed border-gray-300 text-gray-400">
                  <Plus size={20} />
                </div>
              )}
              <div>
                <label className="block text-sm font-medium text-primaryText mb-1">Professional Photo (Max 5MB)</label>
                <input type="file" accept="image/*" onChange={handleImageUpload} className="text-sm text-secondaryText file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:bg-primaryBrand/10 file:text-primaryBrand hover:file:bg-primaryBrand/20 cursor-pointer" />
              </div>
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">Professional Name</label>
              <input required type="text" className="input-field" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} placeholder="Dr. John Doe" />
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">Profession</label>
              <select className="input-field bg-white" value={formData.profession} onChange={e => setFormData({...formData, profession: e.target.value})}>
                <option value="Doctor">Doctor</option>
                <option value="CA">CA</option>
                <option value="Developer">Developer</option>
                <option value="Teacher">Teacher</option>
                <option value="Professor">Professor</option>
                <option value="Lawyer">Lawyer</option>
                <option value="Consultant">Consultant</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">{formData.profession === 'Doctor' ? 'Specialty' : 'Specialty/Role'}</label>
              <input required type="text" className="input-field" value={formData.specialty} onChange={e => setFormData({...formData, specialty: e.target.value})} placeholder={formData.profession === 'Doctor' ? "Cardiologist" : "e.g. Senior Frontend"} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">{formData.profession === 'Doctor' ? 'Clinic/Hospital' : 'Firm Name'}</label>
              <input required type="text" className="input-field" value={formData.clinic} onChange={e => setFormData({...formData, clinic: e.target.value})} placeholder={formData.profession === 'Doctor' ? "City Hospital" : "Tech Corp"} />
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">About / Description</label>
              <textarea className="input-field min-h-[100px]" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} placeholder="Write a short description..." />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Experience (Years)</label>
              <input required type="text" className="input-field" value={formData.experience} onChange={e => setFormData({...formData, experience: e.target.value})} placeholder="10+ Years" />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Consultation Fee (₹)</label>
              <input required type="number" min="0" className="input-field" value={formData.consultation_fee} onChange={e => setFormData({...formData, consultation_fee: parseFloat(e.target.value) || 0})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Default Rating</label>
              <input required type="number" min="1" max="5" step="0.1" className="input-field" value={formData.default_rating} onChange={e => setFormData({...formData, default_rating: parseFloat(e.target.value) || 0})} placeholder="4.5" />
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">Description</label>
              <textarea rows={3} className="input-field" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} placeholder="Professional background, achievements, etc." />
            </div>
          </div>
          <div className="flex justify-end gap-3 mt-6">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium">Cancel</button>
            <button type="submit" className="btn-primary">{editingId ? 'Update Professional' : 'Save Professional'}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Professional" 
        message="Are you sure you want to permanently delete this professional profile? This action cannot be undone." 
      />
    </div>
  );
};

export default Professionals;
