import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, Filter, Stethoscope } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

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
  const [professionFilter, setProfessionFilter] = useState('All');
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
    if (professionFilter === 'All') return true;
    return p.profession === professionFilter || (!p.profession && professionFilter === 'Doctor');
  });

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

  const columns: Column<Professional>[] = [
    {
      header: 'Image',
      cell: (p) => (
        <div className="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden shrink-0 border border-border">
          {p.image_url ? (
            <img src={p.image_url} alt={p.name} className="w-full h-full object-cover" />
          ) : (
            <span className="text-gray-400 font-semibold text-sm">{(p.name || '?')[0].toUpperCase()}</span>
          )}
        </div>
      )
    },
    {
      header: 'Name',
      accessorKey: 'name',
      sortable: true,
      cell: (p) => <span className="font-medium text-primaryText">{p.name}</span>
    },
    {
      header: 'Profession',
      accessorKey: 'profession',
      sortable: true,
      cell: (p) => <span className="text-secondaryText">{p.profession || 'Doctor'}</span>
    },
    {
      header: 'Specialty/Role',
      accessorKey: 'specialty',
      sortable: true,
      cell: (p) => <span className="text-secondaryText">{p.specialty || '—'}</span>
    },
    {
      header: 'Clinic/Firm',
      accessorKey: 'clinic',
      sortable: true,
      cell: (p) => <span className="text-secondaryText">{p.clinic || '—'}</span>
    },
    {
      header: 'Experience',
      accessorKey: 'experience',
      sortable: true,
      cell: (p) => <span className="text-secondaryText">{p.experience || '—'}</span>
    },
    {
      header: 'Fee',
      accessorKey: 'consultation_fee',
      sortable: true,
      cell: (p) => <span className="font-medium text-primaryBrand">₹{p.consultation_fee}</span>
    },
    {
      header: 'Actions',
      cell: (p) => (
        <div className="flex items-center justify-end gap-3">
          <button onClick={() => openEditModal(p)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
          <button onClick={() => { setItemToDelete(p.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
        </div>
      )
    }
  ];

  const toolbarExtras = (
    <div className="relative w-48">
      <Filter className="absolute left-3 top-2.5 text-borderDark" size={18} />
      <select
        value={professionFilter}
        onChange={(e) => setProfessionFilter(e.target.value)}
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
  );

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

      <DataTable
        data={filteredProfessionals}
        columns={columns}
        searchPlaceholder="Search professionals..."
        searchableKeys={['name', 'specialty', 'clinic']}
        loading={loading}
        emptyStateMessage="No professionals found."
        emptyStateIcon={<Stethoscope size={36} className="text-border" />}
        toolbarExtras={toolbarExtras}
      />

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Professional" : "Add Professional"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2 flex items-center gap-4 p-4 border border-border rounded-lg bg-gray-50/50">
              <div className="w-16 h-16 rounded-full bg-white border border-border flex items-center justify-center overflow-hidden">
                {formData.image_url ? (
                  <img src={formData.image_url} alt="Preview" className="w-full h-full object-cover" />
                ) : (
                  <span className="text-secondaryText text-xs text-center px-1">No Image</span>
                )}
              </div>
              <div className="flex-1">
                <label className="block text-sm font-medium text-secondaryText mb-1">Profile Image</label>
                <input 
                  type="file" 
                  accept="image/jpeg,image/png,image/webp"
                  onChange={handleImageUpload}
                  className="w-full text-sm text-secondaryText file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-primaryBrand/10 file:text-primaryBrand hover:file:bg-primaryBrand/20"
                />
                <p className="text-xs text-secondaryText mt-1">Recommended: Square image, max 5MB (JPG, PNG)</p>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Full Name</label>
              <input required type="text" className="input-field" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} />
            </div>

            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Profession</label>
              <select className="input-field bg-white" value={formData.profession} onChange={e => setFormData({...formData, profession: e.target.value})}>
                <option value="Doctor">Doctor</option>
                <option value="CA">CA</option>
                <option value="Developer">Developer</option>
                <option value="Teacher">Teacher</option>
                <option value="Professor">Professor</option>
                <option value="Lawyer">Lawyer</option>
                <option value="Consultant">Consultant</option>
                <option value="Other">Other</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Specialty / Role</label>
              <input required type="text" className="input-field" value={formData.specialty} onChange={e => setFormData({...formData, specialty: e.target.value})} placeholder="e.g. Cardiologist, Civil Lawyer" />
            </div>

            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Clinic / Firm / Company</label>
              <input required type="text" className="input-field" value={formData.clinic} onChange={e => setFormData({...formData, clinic: e.target.value})} />
            </div>

            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Experience (e.g. 10+ Years)</label>
              <input required type="text" className="input-field" value={formData.experience} onChange={e => setFormData({...formData, experience: e.target.value})} />
            </div>

            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Consultation Fee (₹)</label>
              <input required type="number" min="0" className="input-field" value={formData.consultation_fee} onChange={e => setFormData({...formData, consultation_fee: parseInt(e.target.value) || 0})} />
            </div>

            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Default Rating</label>
              <input required type="number" min="0" max="5" step="0.1" className="input-field" value={formData.default_rating} onChange={e => setFormData({...formData, default_rating: parseFloat(e.target.value) || 0})} />
            </div>

            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">About / Description</label>
              <textarea rows={3} className="input-field" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
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
        message="Are you sure you want to permanently delete this professional? This action cannot be undone." 
      />
    </div>
  );
};

export default Professionals;
