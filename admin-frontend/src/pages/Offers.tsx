import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Search } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';

interface Offer {
  id: string;
  title: string;
  subtitle: string;
  type: string;
  action: string;
  description: string;
}

const defaultFormData = {
  title: '', subtitle: '', type: 'Education', action: 'Claim', description: ''
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

  useEffect(() => {
    fetchOffers();
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
      description: offer.description || ''
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

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Offers & Promotions</h1>
          <p className="text-secondaryText">Manage platform discounts and partner offers.</p>
        </div>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add Offer
        </button>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex justify-between items-center bg-gray-50/50">
          <div className="relative w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input type="text" placeholder="Search offers..." className="input-field pl-10 bg-white" />
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium">Title</th>
                <th className="p-4 font-medium">Subtitle</th>
                <th className="p-4 font-medium">Type</th>
                <th className="p-4 font-medium">Call to Action</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} className="text-center p-8 text-secondaryText">Loading offers...</td></tr>
              ) : offers.length === 0 ? (
                <tr><td colSpan={5} className="text-center p-8 text-secondaryText">No offers found.</td></tr>
              ) : (
                offers.map((offer) => (
                  <tr key={offer.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4 font-medium text-primaryBrand">{offer.title}</td>
                    <td className="p-4 text-primaryText">{offer.subtitle}</td>
                    <td className="p-4"><span className="px-2.5 py-1 bg-highlight/10 text-highlight rounded-full text-xs font-medium">{offer.type}</span></td>
                    <td className="p-4 text-secondaryText">{offer.action}</td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button onClick={() => openEditModal(offer)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
                        <button onClick={() => { setItemToDelete(offer.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

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
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Description / Details</label>
            <textarea required rows={3} className="input-field" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} placeholder="Zero processing fee..."></textarea>
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
        message="Are you sure you want to permanently delete this offer? This action cannot be undone." 
      />
    </div>
  );
};

export default Offers;
