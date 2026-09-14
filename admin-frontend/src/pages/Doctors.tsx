import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Search } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';

interface Doctor {
  id: string;
  name: string;
  specialty: string;
  clinic: string;
  experience: string;
  consultation_fee: number;
}

const defaultFormData = {
  name: '', specialty: '', clinic: '', experience: '', consultation_fee: 500
};

const Doctors = () => {
  const { showToast } = useToast();
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  useEffect(() => {
    fetchDoctors();
  }, []);

  const fetchDoctors = async () => {
    try {
      const res = await api.get('/doctors');
      setDoctors(res.data);
    } catch (error) {
      showToast("Failed to fetch doctors", "error");
    } finally {
      setLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!itemToDelete) return;
    try {
      await api.delete(`/doctors/${itemToDelete}`);
      setDoctors(doctors.filter(d => d.id !== itemToDelete));
      showToast("Doctor deleted successfully", "success");
    } catch (error) {
      showToast("Failed to delete doctor", "error");
    }
    setItemToDelete(null);
  };

  const openEditModal = (doc: Doctor) => {
    setFormData({
      name: doc.name,
      specialty: doc.specialty,
      clinic: doc.clinic,
      experience: doc.experience,
      consultation_fee: doc.consultation_fee
    });
    setEditingId(doc.id);
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
        const res = await api.put(`/doctors/${editingId}`, formData);
        setDoctors(doctors.map(d => d.id === editingId ? res.data : d));
        showToast("Doctor updated successfully", "success");
      } else {
        const res = await api.post('/doctors', formData);
        setDoctors([res.data, ...doctors]);
        showToast("Doctor created successfully", "success");
      }
      setIsModalOpen(false);
      setFormData(defaultFormData);
      setEditingId(null);
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} doctor`, "error");
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Doctors Directory</h1>
          <p className="text-secondaryText">Manage doctors and clinics available for booking.</p>
        </div>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add Doctor
        </button>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex justify-between items-center bg-gray-50/50">
          <div className="relative w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input type="text" placeholder="Search doctors..." className="input-field pl-10 bg-white" />
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium">Name</th>
                <th className="p-4 font-medium">Specialty</th>
                <th className="p-4 font-medium">Clinic</th>
                <th className="p-4 font-medium">Experience</th>
                <th className="p-4 font-medium">Fee</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} className="text-center p-8 text-secondaryText">Loading doctors...</td></tr>
              ) : doctors.length === 0 ? (
                <tr><td colSpan={6} className="text-center p-8 text-secondaryText">No doctors found.</td></tr>
              ) : (
                doctors.map((doc) => (
                  <tr key={doc.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4 font-medium text-primaryBrand">{doc.name}</td>
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

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Doctor" : "Add New Doctor"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">Doctor Name</label>
              <input required type="text" className="input-field" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} placeholder="Dr. John Doe" />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Specialty</label>
              <input required type="text" className="input-field" value={formData.specialty} onChange={e => setFormData({...formData, specialty: e.target.value})} placeholder="Cardiologist" />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Clinic/Hospital</label>
              <input required type="text" className="input-field" value={formData.clinic} onChange={e => setFormData({...formData, clinic: e.target.value})} />
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
            <button type="submit" className="btn-primary">{editingId ? 'Update Doctor' : 'Save Doctor'}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Doctor" 
        message="Are you sure you want to permanently delete this doctor profile? This action cannot be undone." 
      />
    </div>
  );
};

export default Doctors;
