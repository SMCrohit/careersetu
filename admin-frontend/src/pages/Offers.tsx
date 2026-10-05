import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, Tag } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface Offer {
  id: string;
  title: string;
  subtitle: string;
  type: string;
  action: string;
  description: string;
  city?: string;
  discount_code?: string;
  valid_until?: string;
}

const defaultFormData = {
  title: '', subtitle: '', type: 'Education', action: 'Claim', description: '',
  city: '', discount_code: '', valid_until: ''
};

const Offers = () => {
  const { showToast } = useToast();
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchOffers();
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

  const fetchOffers = async () => {
    try {
      const res = await api.get('/offers');
      setOffers(res.data);
    } catch (error) {
      showToast("Failed to fetch offers", "error");
    } finally {
      setLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!itemToDelete) return;
    try {
      await api.delete(`/offers/${itemToDelete}`);
      setOffers(offers.filter(o => o.id !== itemToDelete));
      showToast("Offer deleted successfully", "success");
    } catch (error) {
      showToast("Failed to delete offer", "error");
    }
    setItemToDelete(null);
  };

  const openEditModal = (offer: Offer) => {
    setFormData({
      title: offer.title,
      subtitle: offer.subtitle,
      type: offer.type,
      action: offer.action,
      description: offer.description || '',
      city: offer.city || '',
      discount_code: offer.discount_code || '',
      valid_until: offer.valid_until ? new Date(offer.valid_until).toISOString().split('T')[0] : ''
    });
    setEditingId(offer.id);
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
        const res = await api.put(`/offers/${editingId}`, formData);
        setOffers(offers.map(o => o.id === editingId ? res.data : o));
        showToast("Offer updated successfully", "success");
      } else {
        const res = await api.post('/offers', formData);
        setOffers([res.data, ...offers]);
        showToast("Offer created successfully", "success");
      }
      setIsModalOpen(false);
      setFormData(defaultFormData);
      setEditingId(null);
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} offer`, "error");
    }
  };

  // ── Export helpers ─────────────────────────────────────────────────────────
  const exportRows = offers.map((offer, i) => ({
    '#': i + 1,
    'Title': offer.title || '—',
    'Subtitle': offer.subtitle || '—',
    'Type': offer.type || '—',
    'City': offer.city || 'All',
    'Code': offer.discount_code || 'N/A',
  }));

  const exportToCSV = () => {
    if (exportRows.length === 0) return;
    const headers = Object.keys(exportRows[0]);
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'offers.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Offers');
    XLSX.writeFile(wb, 'offers.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Offers & Promotions', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${offers.length} offers`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'Title', 'Subtitle', 'Type', 'City', 'Code']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('offers.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const columns: Column<Offer>[] = [
    {
      header: 'Title',
      accessorKey: 'title',
      sortable: true,
      cell: (offer) => <span className="font-medium text-primaryBrand">{offer.title}</span>
    },
    {
      header: 'Subtitle',
      accessorKey: 'subtitle',
      sortable: true,
      cell: (offer) => <span className="text-primaryText">{offer.subtitle}</span>
    },
    {
      header: 'Type',
      accessorKey: 'type',
      sortable: true,
      cell: (offer) => <span className="px-2.5 py-1 bg-highlight/10 text-highlight rounded-full text-xs font-medium">{offer.type}</span>
    },
    {
      header: 'City',
      accessorKey: 'city',
      sortable: true,
      cell: (offer) => <span className="text-secondaryText">{offer.city || 'All'}</span>
    },
    {
      header: 'Code',
      accessorKey: 'discount_code',
      sortable: true,
      cell: (offer) => <span className="text-secondaryText font-mono">{offer.discount_code || 'N/A'}</span>
    },
    {
      header: 'Actions',
      cell: (offer) => (
        <div className="flex items-center justify-end gap-3">
          <button onClick={() => openEditModal(offer)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
          <button onClick={() => { setItemToDelete(offer.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
        </div>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
      <div className="flex flex-wrap justify-between items-center gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Offers & Promotions</h1>
          <p className="text-secondaryText">Manage platform discounts and partner offers.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
            {offers.length} Offers
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

          <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
            <Plus size={18} /> Add Offer
          </button>
        </div>
      </div>

      <DataTable
        data={offers}
        columns={columns}
        searchPlaceholder="Search offers..."
        searchableKeys={['title', 'subtitle', 'type', 'city']}
        loading={loading}
        emptyStateMessage="No offers found."
        emptyStateIcon={<Tag size={36} className="text-border" />}
      />

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Offer" : "Add New Offer"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Offer Title</label>
              <input required type="text" className="input-field" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} placeholder="e.g. State Bank of India" />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Subtitle</label>
              <input required type="text" className="input-field" value={formData.subtitle} onChange={e => setFormData({...formData, subtitle: e.target.value})} placeholder="e.g. Education Loan at 8%" />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Type/Category</label>
              <select className="input-field bg-white" value={formData.type} onChange={e => setFormData({...formData, type: e.target.value})}>
                <option>Education</option>
                <option>Loans</option>
                <option>Services</option>
                <option>Health</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Call to Action text</label>
              <input required type="text" className="input-field" value={formData.action} onChange={e => setFormData({...formData, action: e.target.value})} placeholder="e.g. Apply, Claim" />
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">City (Optional)</label>
              <input type="text" className="input-field" value={formData.city} onChange={e => setFormData({...formData, city: e.target.value})} placeholder="e.g. Mumbai, Delhi (Leave blank for all)" />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Discount Code</label>
              <input required type="text" className="input-field" value={formData.discount_code} onChange={e => setFormData({...formData, discount_code: e.target.value})} placeholder="e.g. SAVE50" />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Valid Until (Optional)</label>
              <input type="date" className="input-field" value={formData.valid_until} onChange={e => setFormData({...formData, valid_until: e.target.value})} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Description</label>
            <textarea required rows={4} className="input-field" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
          </div>
          <div className="flex justify-end gap-3 mt-6">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium">Cancel</button>
            <button type="submit" className="btn-primary">{editingId ? 'Update Offer' : 'Save Offer'}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Offer" 
        message="Are you sure you want to delete this offer? This action cannot be undone." 
      />
    </div>
  );
};

export default Offers;
