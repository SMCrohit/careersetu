import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Edit2, Trash2, Plus, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, Star } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface ProfessionalReview {
  id: string;
  professional_id: string;
  user_id: string;
  rating: number;
  comment: string;
  created_datetime: string;
  professional?: { name: string };
  user?: { full_name: string, mobile_number: string };
}

const defaultFormData = {
  professional_id: '',
  user_id: '',
  rating: 5,
  comment: ''
};

const ProfessionalReviews = () => {
  const { showToast } = useToast();
  const [reviews, setReviews] = useState<ProfessionalReview[]>([]);
  const [professionals, setProfessionals] = useState<any[]>([]);
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchData();
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

  const fetchData = async () => {
    setLoading(true);
    try {
      const [revRes, profRes, usersRes] = await Promise.all([
        api.get('/admin/professional-reviews'),
        api.get('/professionals'),
        api.get('/users')
      ]);
      setReviews(revRes.data);
      setProfessionals(profRes.data);
      setUsers(usersRes.data);
    } catch (error) {
      showToast('Failed to load data', 'error');
    } finally {
      setLoading(false);
    }
  };

  const openAddModal = () => {
    setEditingId(null);
    setFormData({
      ...defaultFormData,
      professional_id: professionals[0]?.id || '',
      user_id: users[0]?.id || ''
    });
    setIsModalOpen(true);
  };

  const openEditModal = (review: ProfessionalReview) => {
    setEditingId(review.id);
    setFormData({
      professional_id: review.professional_id,
      user_id: review.user_id,
      rating: review.rating,
      comment: review.comment || ''
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingId) {
        await api.put(`/admin/professional-reviews/${editingId}`, formData);
        showToast('Review updated successfully', 'success');
      } else {
        await api.post(`/admin/professional-reviews`, formData);
        showToast('Review added successfully', 'success');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (error: any) {
      showToast(error.response?.data?.detail || 'An error occurred', 'error');
    }
  };

  const confirmDelete = async () => {
    if (!itemToDelete) return;
    try {
      await api.delete(`/admin/professional-reviews/${itemToDelete}`);
      showToast('Review deleted successfully', 'success');
      fetchData();
    } catch (error) {
      showToast('Failed to delete review', 'error');
    } finally {
      setDeleteDialogOpen(false);
      setItemToDelete(null);
    }
  };

  // ── Export helpers ─────────────────────────────────────────────────────────
  const exportRows = reviews.map((review, i) => ({
    '#': i + 1,
    'Professional': review.professional?.name || 'Unknown',
    'User': review.user?.full_name || review.user?.mobile_number || 'Unknown User',
    'Rating': review.rating,
    'Comment': review.comment || '-',
  }));

  const exportToCSV = () => {
    if (exportRows.length === 0) return;
    const headers = Object.keys(exportRows[0]);
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'professional_reviews.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Reviews');
    XLSX.writeFile(wb, 'professional_reviews.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF();
    doc.setFontSize(16);
    doc.text('Professional Reviews', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${reviews.length} reviews`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'Professional', 'User', 'Rating', 'Comment']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('professional_reviews.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const columns: Column<ProfessionalReview>[] = [
    {
      header: 'Professional',
      accessorKey: 'professional.name', // searchable
      sortable: true,
      cell: (r) => <span className="font-medium text-primaryText">{r.professional?.name || 'Unknown'}</span>
    },
    {
      header: 'User',
      accessorKey: 'user.full_name', // searchable
      sortable: true,
      cell: (r) => <span className="text-secondaryText">{r.user?.full_name || r.user?.mobile_number || 'Unknown User'}</span>
    },
    {
      header: 'Rating',
      accessorKey: 'rating',
      sortable: true,
      cell: (r) => (
        <span className="px-2.5 py-1 bg-yellow-100 text-yellow-700 rounded-full text-xs font-bold flex items-center w-fit gap-1">
          ★ {r.rating}
        </span>
      )
    },
    {
      header: 'Comment',
      accessorKey: 'comment',
      sortable: true,
      cell: (r) => <span className="text-secondaryText truncate max-w-xs block" title={r.comment}>{r.comment || '-'}</span>
    },
    {
      header: 'Actions',
      cell: (r) => (
        <div className="flex items-center justify-end gap-3">
          <button onClick={() => openEditModal(r)} className="text-secondaryText hover:text-primaryBrand transition-colors p-1"><Edit2 size={16} /></button>
          <button onClick={() => { setItemToDelete(r.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors p-1"><Trash2 size={16} /></button>
        </div>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
      <div className="flex flex-wrap items-center justify-between gap-4 mb-8">
        <div>
          <h2 className="text-2xl font-bold text-primaryText">Professional Reviews</h2>
          <p className="text-sm text-secondaryText mt-1">Manage user reviews for professionals</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
            {reviews.length} Reviews
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
            <Plus size={18} />
            Add Review
          </button>
        </div>
      </div>

      <DataTable
        data={reviews}
        columns={columns}
        searchPlaceholder="Search reviews..."
        searchableKeys={['professional.name', 'user.full_name', 'comment']}
        loading={loading}
        emptyStateMessage="No reviews found."
        emptyStateIcon={<Star size={36} className="text-border" />}
      />

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Review" : "Add Review"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Professional</label>
            <select 
              required 
              disabled={!!editingId}
              className="input-field bg-white" 
              value={formData.professional_id} 
              onChange={e => setFormData({...formData, professional_id: e.target.value})}
            >
              <option value="" disabled>Select Professional</option>
              {professionals.map(p => (
                <option key={p.id} value={p.id}>{p.name} ({p.profession})</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">User</label>
            <select 
              required 
              disabled={!!editingId}
              className="input-field bg-white" 
              value={formData.user_id} 
              onChange={e => setFormData({...formData, user_id: e.target.value})}
            >
              <option value="" disabled>Select User</option>
              {users.map(u => (
                <option key={u.id} value={u.id}>{u.full_name || u.mobile_number}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Rating</label>
            <input required type="number" min="1" max="5" step="0.1" className="input-field" value={formData.rating} onChange={e => setFormData({...formData, rating: parseFloat(e.target.value) || 0})} />
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Comment</label>
            <textarea rows={3} className="input-field" value={formData.comment} onChange={e => setFormData({...formData, comment: e.target.value})} placeholder="User's review comment" />
          </div>
          <div className="flex justify-end gap-3 mt-6">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium">Cancel</button>
            <button type="submit" className="btn-primary">{editingId ? 'Update Review' : 'Save Review'}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Review" 
        message="Are you sure you want to delete this review?" 
      />
    </div>
  );
};

export default ProfessionalReviews;
