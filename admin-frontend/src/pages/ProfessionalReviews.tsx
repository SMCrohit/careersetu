import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Edit2, Trash2, Search, Plus } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';

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
  const [search, setSearch] = useState('');
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  useEffect(() => {
    fetchData();
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

  const filteredReviews = reviews.filter(r => {
    const searchString = search.toLowerCase();
    return (
      (r.professional?.name?.toLowerCase().includes(searchString) || '') ||
      (r.user?.full_name?.toLowerCase().includes(searchString) || '') ||
      (r.comment?.toLowerCase().includes(searchString) || '')
    );
  });

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

  return (
    <div className="card h-[calc(100vh-4rem)] flex flex-col">
      <div className="p-6 border-b border-border flex flex-wrap gap-4 items-center justify-between bg-white">
        <div>
          <h2 className="text-xl font-bold text-primaryText">Professional Reviews</h2>
          <p className="text-sm text-secondaryText mt-1">Manage user reviews for professionals</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text" 
              placeholder="Search reviews..." 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primaryBrand/30 transition-all"
            />
          </div>
          <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
            <Plus size={18} />
            Add Review
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-auto bg-gray-50/30">
        <table className="w-full text-sm text-left">
          <thead className="text-xs text-secondaryText uppercase bg-gray-50 sticky top-0 z-10 shadow-sm">
            <tr>
              <th className="px-6 py-4 font-semibold">Professional</th>
              <th className="px-6 py-4 font-semibold">User</th>
              <th className="px-6 py-4 font-semibold">Rating</th>
              <th className="px-6 py-4 font-semibold">Comment</th>
              <th className="px-6 py-4 font-semibold text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {loading ? (
              [...Array(5)].map((_, i) => (
                <tr key={i} className="animate-pulse bg-white">
                  <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-3/4"></div></td>
                  <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-1/2"></div></td>
                  <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-1/4"></div></td>
                  <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-full"></div></td>
                  <td className="px-6 py-4"></td>
                </tr>
              ))
            ) : filteredReviews.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-12 text-center bg-white">
                  <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gray-100 mb-3">
                    <Search className="text-gray-400" size={20} />
                  </div>
                  <h3 className="text-sm font-medium text-primaryText">No reviews found</h3>
                </td>
              </tr>
            ) : (
              filteredReviews.map((review) => (
                <tr key={review.id} className="bg-white hover:bg-gray-50/50 transition-colors group">
                  <td className="px-6 py-4 font-medium text-primaryText">{review.professional?.name || 'Unknown'}</td>
                  <td className="px-6 py-4 text-secondaryText">{review.user?.full_name || review.user?.mobile_number || 'Unknown User'}</td>
                  <td className="px-6 py-4">
                    <span className="px-2.5 py-1 bg-yellow-100 text-yellow-700 rounded-full text-xs font-bold flex items-center w-fit gap-1">
                      ★ {review.rating}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-secondaryText truncate max-w-xs" title={review.comment}>{review.comment || '-'}</td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-3 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button onClick={() => openEditModal(review)} className="text-secondaryText hover:text-primaryBrand transition-colors p-1"><Edit2 size={16} /></button>
                      <button onClick={() => { setItemToDelete(review.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors p-1"><Trash2 size={16} /></button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

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
