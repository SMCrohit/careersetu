import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, Filter, Stethoscope, ArrowLeft, X } from 'lucide-react';
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
  qualification?: string;
  clinic: string;
  experience: string;
  consultation_fee: number;
  image_url?: string;
  description?: string;
  default_rating: number;
  location_city?: string;
  is_active?: boolean;
  available_days?: string[];
  time_slots?: string[];
  max_bookings_per_slot?: number;
  is_featured?: boolean;
  consultation_mode?: string[];
  languages_spoken?: string[];
}

const defaultFormData = {
  name: '', profession: 'Doctor', specialty: '', qualification: '', clinic: '', experience: '', consultation_fee: 500, image_url: '', description: '', default_rating: 4.5,
  available_days: [] as string[], time_slots: [] as string[], max_bookings_per_slot: 1, is_featured: false, consultation_mode: [] as string[], languages_spoken: [] as string[], location_city: '', is_active: true
};

const Professionals = () => {
  const { showToast } = useToast();

  const toggleArrayItem = (field: string, value: string) => {
    setFormData((prev: any) => {
      const arr = prev[field] || [];
      return { ...prev, [field]: arr.includes(value) ? arr.filter((i: string) => i !== value) : [...arr, value] };
    });
  };

  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({ profession: '', is_active: '' });
  const [currentPage, setCurrentPage] = useState(1);
  const [currentLimit, setCurrentLimit] = useState(10);
  const [serverTotal, setServerTotal] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  useEffect(() => {
    fetchProfessionalsWithParams(null, 1, '', 10);
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

  const fetchProfessionalsWithParams = async (currentFilters: any, page: number, search: string, limit: number) => {
    setLoading(true);
    try {
      const activeFilters = currentFilters || filters;
      const params = new URLSearchParams({
        page: page.toString(),
        limit: limit.toString()
      });
      if (search) params.append('search', search);
      if (activeFilters.profession) params.append('profession', activeFilters.profession);
      if (activeFilters.is_active) params.append('is_active', activeFilters.is_active);

      const res = await api.get(`/admin/professionals?${params.toString()}`);
      setProfessionals(res.data.items);
      setServerTotal(res.data.total);
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

  // ─── Export helpers ────────────────────────────────────────────────────────
  const exportRows = professionals.map((p, i) => ({
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
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${serverTotal} professionals`, 14, 22);

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
      qualification: doc.qualification || '',
      clinic: doc.clinic,
      experience: doc.experience,
      consultation_fee: doc.consultation_fee,
      image_url: doc.image_url || '',
      description: doc.description || '',
      default_rating: doc.default_rating || 0,
      available_days: doc.available_days || [],
      time_slots: doc.time_slots || [],
      max_bookings_per_slot: doc.max_bookings_per_slot || 1,
      is_featured: doc.is_featured || false,
      consultation_mode: doc.consultation_mode || [],
      languages_spoken: doc.languages_spoken || [],
      location_city: doc.location_city || '',
      is_active: doc.is_active !== false // default to true if undefined
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
      header: 'Qualification',
      accessorKey: 'qualification',
      sortable: false,
      cell: (p) => <span className="text-secondaryText text-sm line-clamp-1" title={p.qualification}>{p.qualification || '—'}</span>
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
    <button onClick={() => setIsFilterOpen(true)} className="flex items-center gap-2 px-4 py-2 bg-white border border-border rounded-xl text-secondaryText hover:text-primaryText shadow-sm h-[42px]">
      <Filter size={18} />
      Filters {Object.values(filters).filter(v => v).length > 0 && <span className="w-5 h-5 bg-primaryBrand text-white text-xs flex items-center justify-center rounded-full">{Object.values(filters).filter(v => v).length}</span>}
    </button>
  );

  return (
    <div className="animate-fade-in">
      {!isModalOpen ? (
        <>
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
            data={professionals}
            columns={columns}
            searchPlaceholder="Search professionals..."
            searchableKeys={[]}
            loading={loading}
            emptyStateMessage="No professionals found."
            emptyStateIcon={<Stethoscope size={36} className="text-border" />}
            toolbarExtras={toolbarExtras}
            serverSideMode={true}
            serverSideTotal={serverTotal}
            serverSidePage={currentPage}
            onPageChange={(page) => {
              setCurrentPage(page);
              fetchProfessionalsWithParams(null, page, searchTerm, currentLimit);
            }}
            onSearchChange={(search) => {
              setSearchTerm(search);
              setCurrentPage(1);
              fetchProfessionalsWithParams(null, 1, search, currentLimit);
            }}
            onPageSizeChange={(size) => {
              setCurrentLimit(size);
              setCurrentPage(1);
              fetchProfessionalsWithParams(null, 1, searchTerm, size);
            }}
          />
          {/* Side Panel for Filters */}
          {isFilterOpen && (
            <div className="fixed inset-0 z-50 flex justify-end">
              <div className="absolute inset-0 bg-black/20" onClick={() => setIsFilterOpen(false)}></div>
              <div className="relative w-full max-w-md bg-white h-full shadow-2xl flex flex-col animate-slide-in-right">
                <div className="p-6 border-b border-border flex justify-between items-center bg-gray-50/50">
                  <h2 className="text-xl font-bold text-primaryText">Advanced Filters</h2>
                  <button onClick={() => setIsFilterOpen(false)} className="p-2 hover:bg-gray-200 rounded-full text-secondaryText hover:text-primaryText transition-colors">
                    <X size={20} />
                  </button>
                </div>
                <div className="flex-1 overflow-y-auto p-6 space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-2">Profession</label>
                    <select className="input-field bg-white" value={filters.profession} onChange={e => setFilters({...filters, profession: e.target.value})}>
                      <option value="">All Professions</option>
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
                    <label className="block text-sm font-medium text-secondaryText mb-2">Status</label>
                    <select className="input-field bg-white" value={filters.is_active} onChange={e => setFilters({...filters, is_active: e.target.value})}>
                      <option value="">All Status</option>
                      <option value="Active">Active</option>
                      <option value="Inactive">Inactive</option>
                    </select>
                  </div>
                </div>
                <div className="p-6 border-t border-border flex gap-3">
                  <button onClick={() => {
                    const empty = { profession: '', is_active: '' };
                    setFilters(empty);
                    setCurrentPage(1);
                    fetchProfessionalsWithParams(empty, 1, searchTerm, currentLimit);
                  }} className="flex-1 py-2 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200">Clear All</button>
                  <button onClick={() => {
                    setIsFilterOpen(false);
                    setCurrentPage(1);
                    fetchProfessionalsWithParams(filters, 1, searchTerm, currentLimit);
                  }} className="flex-1 py-2 bg-primaryBrand text-white rounded-xl font-medium hover:bg-blue-700">Apply Filters</button>
                </div>
              </div>
            </div>
          )}
        </>
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-border animate-fade-in max-w-5xl mx-auto">
          <div className="p-6 border-b border-border bg-white flex items-center gap-4 rounded-t-2xl">
            <button onClick={() => setIsModalOpen(false)} className="text-secondaryText hover:text-primaryText transition-colors p-2 -ml-2 rounded-lg hover:bg-gray-100 flex items-center gap-2 font-medium">
              <ArrowLeft size={20} /> Back
            </button>
            <div className="h-6 w-px bg-border mx-2"></div>
            <div>
              <h2 className="text-xl font-bold text-primaryText">{editingId ? "Edit Professional" : "Add New Professional"}</h2>
            </div>
          </div>
          
          <form onSubmit={handleSubmit} className="p-8 space-y-10">
              
              {/* Section 1: Basic Info */}
              <div>
                <h3 className="text-md font-semibold text-primaryText mb-4 border-b pb-2">1. Basic Information</h3>
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
                    <label className="block text-sm font-medium text-secondaryText mb-1">Qualification</label>
                    <input type="text" className="input-field" value={formData.qualification} onChange={e => setFormData({...formData, qualification: e.target.value})} placeholder="e.g. MBBS, MD" />
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
                    <label className="block text-sm font-medium text-secondaryText mb-1">City</label>
                    <input type="text" className="input-field" value={formData.location_city} onChange={e => setFormData({...formData, location_city: e.target.value})} placeholder="e.g. Mumbai" />
                  </div>

                  <div className="flex items-center mt-6 gap-2 col-span-2">
                    <input type="checkbox" id="featured" checked={formData.is_featured} onChange={e => setFormData({...formData, is_featured: e.target.checked})} className="w-5 h-5 rounded border-gray-300 text-primaryBrand" />
                    <label htmlFor="featured" className="text-sm font-medium text-secondaryText">Feature this professional</label>
                  </div>
                  
                  <div className="flex items-center mt-2 gap-2 col-span-2">
                    <input type="checkbox" id="active" checked={formData.is_active} onChange={e => setFormData({...formData, is_active: e.target.checked})} className="w-5 h-5 rounded border-gray-300 text-primaryBrand" />
                    <label htmlFor="active" className="text-sm font-medium text-secondaryText">Is Active</label>
                  </div>
                </div>
              </div>

              {/* Section 2: Availability & Booking */}
              <div>
                <h3 className="text-md font-semibold text-primaryText mb-4 border-b pb-2">2. Availability & Booking</h3>
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Consultation Fee (₹)</label>
                    <input required type="number" min="0" className="input-field" value={formData.consultation_fee} onChange={e => setFormData({...formData, consultation_fee: parseInt(e.target.value) || 0})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Max Bookings Per Slot</label>
                    <input required type="number" min="1" className="input-field" value={formData.max_bookings_per_slot} onChange={e => setFormData({...formData, max_bookings_per_slot: parseInt(e.target.value) || 1})} />
                  </div>
                  
                  <div className="col-span-2">
                    <label className="block text-sm font-medium text-secondaryText mb-2">Available Days</label>
                    <div className="flex flex-wrap gap-2">
                      {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => {
                        const isSelected = (formData.available_days || []).includes(day);
                        return (
                          <button
                            key={day}
                            type="button"
                            onClick={() => toggleArrayItem('available_days', day)}
                            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors border ${isSelected ? 'bg-primaryBrand text-white border-primaryBrand' : 'bg-white text-secondaryText border-border hover:border-primaryBrand'}`}
                          >
                            {day}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                  
                  <div className="col-span-2">
                    <label className="block text-sm font-medium text-secondaryText mb-2">Time Slots</label>
                    <div className="flex flex-wrap gap-2">
                      {['10:00 AM', '11:00 AM', '12:00 PM', '02:00 PM', '04:00 PM', '06:00 PM', '08:00 PM'].map(slot => {
                        const isSelected = (formData.time_slots || []).includes(slot);
                        return (
                          <button
                            key={slot}
                            type="button"
                            onClick={() => toggleArrayItem('time_slots', slot)}
                            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors border ${isSelected ? 'bg-primaryBrand text-white border-primaryBrand' : 'bg-white text-secondaryText border-border hover:border-primaryBrand'}`}
                          >
                            {slot}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>

              {/* Section 3: Additional Details */}
              <div>
                <h3 className="text-md font-semibold text-primaryText mb-4 border-b pb-2">3. Additional Details</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="col-span-2">
                    <label className="block text-sm font-medium text-secondaryText mb-2">Consultation Mode</label>
                    <div className="flex flex-wrap gap-2">
                      {['In-Person', 'Online', 'Phone'].map(mode => {
                        const isSelected = (formData.consultation_mode || []).includes(mode);
                        return (
                          <button
                            key={mode}
                            type="button"
                            onClick={() => toggleArrayItem('consultation_mode', mode)}
                            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors border ${isSelected ? 'bg-primaryBrand text-white border-primaryBrand' : 'bg-white text-secondaryText border-border hover:border-primaryBrand'}`}
                          >
                            {mode}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                  
                  <div className="col-span-2 mt-2">
                    <label className="block text-sm font-medium text-secondaryText mb-2">Languages Spoken</label>
                    <div className="flex flex-wrap gap-2">
                      {['English', 'Hindi', 'Marathi', 'Gujarati', 'Tamil', 'Telugu'].map(lang => {
                        const isSelected = (formData.languages_spoken || []).includes(lang);
                        return (
                          <button
                            key={lang}
                            type="button"
                            onClick={() => toggleArrayItem('languages_spoken', lang)}
                            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors border ${isSelected ? 'bg-primaryBrand text-white border-primaryBrand' : 'bg-white text-secondaryText border-border hover:border-primaryBrand'}`}
                          >
                            {lang}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                  
                  <div className="col-span-2 mt-2">
                    <label className="block text-sm font-medium text-secondaryText mb-1">Default Rating</label>
                    <input required type="number" min="0" max="5" step="0.1" className="input-field w-1/2" value={formData.default_rating} onChange={e => setFormData({...formData, default_rating: parseFloat(e.target.value) || 0})} />
                  </div>
                  
                  <div className="col-span-2 mt-2">
                    <label className="block text-sm font-medium text-secondaryText mb-1">About / Description</label>
                    <textarea rows={4} className="input-field w-full" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
                  </div>
                </div>
              </div>
              
              <div className="flex justify-end gap-3 mt-8 pt-4 border-t border-border">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-6 py-2.5 text-secondaryText hover:text-primaryText font-medium bg-gray-100 hover:bg-gray-200 rounded-xl transition-colors">Cancel</button>
                <button type="submit" className="px-6 py-2.5 bg-primaryBrand text-white font-medium rounded-xl hover:bg-blue-700 transition-colors shadow-sm">{editingId ? 'Update Professional' : 'Save Professional'}</button>
              </div>
          </form>
        </div>
      )}
      
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
