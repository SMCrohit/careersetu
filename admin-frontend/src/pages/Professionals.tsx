import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Search } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';

interface Professional {
  id: string;
  name: string;
  profession: string;
  specialty: string;
  clinic: string;
  experience: string;
  consultation_fee: number;
  image_url?: string;
}

const defaultFormData = {
  name: '', profession: 'Doctor', specialty: '', clinic: '', experience: '', consultation_fee: 500, image_url: ''
};

const Professionals = () => {
  const { showToast } = useToast();
  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  useEffect(() => {
    fetchProfessionals();
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

  const openEditModal = (doc: Professional) => {
    setFormData({
      name: doc.name,
      profession: doc.profession || 'Doctor',
      specialty: doc.specialty,
      clinic: doc.clinic,
      experience: doc.experience,
      consultation_fee: doc.consultation_fee,
      image_url: doc.image_url || ''
    });
    setEditingId(doc.id);
    setIsModalOpen(true);
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
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
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add Professional
        </button>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex justify-between items-center bg-gray-50/50">
          <div className="relative w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input type="text" placeholder="Search professionals..." className="input-field pl-10 bg-white" />
          </div>
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
                <tr><td colSpan={6} className="text-center p-8 text-secondaryText">Loading professionals...</td></tr>
              ) : professionals.length === 0 ? (
                <tr><td colSpan={6} className="text-center p-8 text-secondaryText">No professionals found.</td></tr>
              ) : (
                professionals.map((doc) => (
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
                <label className="block text-sm font-medium text-primaryText mb-1">Professional Photo</label>
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
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Experience (Years)</label>
              <input required type="text" className="input-field" value={formData.experience} onChange={e => setFormData({...formData, experience: e.target.value})} placeholder="10+ Years" />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Consultation Fee (₹)</label>
              <input required type="number" min="0" className="input-field" value={formData.consultation_fee} onChange={e => setFormData({...formData, consultation_fee: parseFloat(e.target.value) || 0})} />
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
