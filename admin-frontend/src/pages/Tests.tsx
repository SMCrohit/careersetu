import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Search, ListOrdered } from 'lucide-react';
import { Link } from 'react-router-dom';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';

interface TestModel {
  id: string;
  title: string;
  tag: string;
  description: string;
  difficulty: string;
  duration_mins: number;
  provider_name: string;
}

const defaultFormData = {
  title: '', tag: '', description: '', duration_mins: 60, 
  difficulty: 'Medium', provider_name: 'CareerSetu', max_discount_percentage: 0, questions: []
};

const Tests = () => {
  const { showToast } = useToast();
  const [tests, setTests] = useState<TestModel[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  useEffect(() => {
    fetchTests();
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

  const openEditModal = (test: TestModel) => {
    setFormData({
      title: test.title,
      tag: test.tag,
      description: test.description,
      duration_mins: test.duration_mins,
      difficulty: test.difficulty,
      provider_name: test.provider_name || 'CareerSetu',
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

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Tests Management</h1>
          <p className="text-secondaryText">Manage all assessments and mock tests.</p>
        </div>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add New Test
        </button>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex justify-between items-center bg-gray-50/50">
          <div className="relative w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input type="text" placeholder="Search tests..." className="input-field pl-10 bg-white" />
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium">Test Title</th>
                <th className="p-4 font-medium">Tag</th>
                <th className="p-4 font-medium">Difficulty</th>
                <th className="p-4 font-medium">Description</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} className="text-center p-8 text-secondaryText">Loading tests...</td></tr>
              ) : tests.length === 0 ? (
                <tr><td colSpan={5} className="text-center p-8 text-secondaryText">No tests found.</td></tr>
              ) : (
                tests.map((test) => (
                  <tr key={test.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4 font-medium text-primaryBrand">{test.title}</td>
                    <td className="p-4"><span className="px-2.5 py-1 bg-highlight/10 text-highlight rounded-full text-xs font-medium">{test.tag}</span></td>
                    <td className="p-4 text-secondaryText">{test.difficulty}</td>
                    <td className="p-4 text-secondaryText truncate max-w-xs">{test.description}</td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <Link to={`/tests/${test.id}/questions`} title="Manage Questions" className="text-secondaryText hover:text-highlight transition-colors">
                          <ListOrdered size={16} />
                        </Link>
                        <button onClick={() => openEditModal(test)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
                        <button onClick={() => { setItemToDelete(test.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Test" : "Add New Test"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-secondaryText mb-1">Test Title</label>
              <input required type="text" className="input-field" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Tag (e.g. UPSC, Tech)</label>
              <input required type="text" className="input-field" value={formData.tag} onChange={e => setFormData({...formData, tag: e.target.value})} />
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
              <label className="block text-sm font-medium text-secondaryText mb-1">Duration (Minutes)</label>
              <input required type="number" min="1" className="input-field" value={formData.duration_mins} onChange={e => setFormData({...formData, duration_mins: parseInt(e.target.value) || 0})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Provider Name</label>
              <input required type="text" className="input-field" value={formData.provider_name} onChange={e => setFormData({...formData, provider_name: e.target.value})} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Description</label>
            <textarea required rows={4} className="input-field" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
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
        message="Are you sure you want to permanently delete this test? This action cannot be undone." 
      />
    </div>
  );
};

export default Tests;
