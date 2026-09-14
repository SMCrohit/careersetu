import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Search, MoreVertical } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';

interface Job {
  id: string;
  title: string;
  company: string;
  location: string;
  type: string;
  level: string;
  posted_time: string;
  salary: string;
  description: string;
}

const defaultFormData = {
  title: '', company: '', location: '', salary: '', 
  type: 'Full-time', level: 'Entry level', description: '', 
  posted_time: 'Just now', applicants: '0', requirements: []
};

const Jobs = () => {
  const { showToast } = useToast();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  useEffect(() => {
    fetchJobs();
  }, []);

  const fetchJobs = async () => {
    try {
      const res = await api.get('/jobs');
      setJobs(res.data);
    } catch (error) {
      showToast("Failed to fetch jobs", "error");
    } finally {
      setLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!itemToDelete) return;
    try {
      await api.delete(`/jobs/${itemToDelete}`);
      setJobs(jobs.filter(j => j.id !== itemToDelete));
      showToast("Job deleted successfully", "success");
    } catch (error) {
      showToast("Failed to delete job", "error");
    }
    setItemToDelete(null);
  };

  const openEditModal = (job: Job) => {
    setFormData({
      title: job.title,
      company: job.company,
      location: job.location,
      salary: job.salary || '',
      type: job.type,
      level: job.level,
      description: job.description || '',
      posted_time: job.posted_time,
      applicants: '0',
      requirements: []
    });
    setEditingId(job.id);
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
        const res = await api.put(`/jobs/${editingId}`, formData);
        setJobs(jobs.map(j => j.id === editingId ? res.data : j));
        showToast("Job updated successfully", "success");
      } else {
        const res = await api.post('/jobs', formData);
        setJobs([res.data, ...jobs]);
        showToast("Job created successfully", "success");
      }
      setIsModalOpen(false);
      setFormData(defaultFormData);
      setEditingId(null);
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} job`, "error");
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Jobs Management</h1>
          <p className="text-secondaryText">Manage all listed jobs on the platform.</p>
        </div>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add New Job
        </button>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex justify-between items-center bg-gray-50/50">
          <div className="relative w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input type="text" placeholder="Search jobs..." className="input-field pl-10 bg-white" />
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium">Job Title</th>
                <th className="p-4 font-medium">Company</th>
                <th className="p-4 font-medium">Location</th>
                <th className="p-4 font-medium">Type</th>
                <th className="p-4 font-medium">Level</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} className="text-center p-8 text-secondaryText">Loading jobs...</td></tr>
              ) : jobs.length === 0 ? (
                <tr><td colSpan={6} className="text-center p-8 text-secondaryText">No jobs found.</td></tr>
              ) : (
                jobs.map((job) => (
                  <tr key={job.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4 font-medium text-primaryBrand">{job.title}</td>
                    <td className="p-4 text-primaryText">{job.company}</td>
                    <td className="p-4 text-secondaryText">{job.location}</td>
                    <td className="p-4"><span className="px-2.5 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium border border-gray-200">{job.type}</span></td>
                    <td className="p-4 text-secondaryText">{job.level}</td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button onClick={() => openEditModal(job)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
                        <button onClick={() => { setItemToDelete(job.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Job" : "Add New Job"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Job Title</label>
              <input required type="text" className="input-field" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Company</label>
              <input required type="text" className="input-field" value={formData.company} onChange={e => setFormData({...formData, company: e.target.value})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Location</label>
              <input required type="text" className="input-field" value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Salary</label>
              <input required type="text" className="input-field" value={formData.salary} onChange={e => setFormData({...formData, salary: e.target.value})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Type</label>
              <select className="input-field bg-white" value={formData.type} onChange={e => setFormData({...formData, type: e.target.value})}>
                <option>Full-time</option>
                <option>Part-time</option>
                <option>Contract</option>
                <option>Internship</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Level</label>
              <select className="input-field bg-white" value={formData.level} onChange={e => setFormData({...formData, level: e.target.value})}>
                <option>Entry level</option>
                <option>Mid-Senior level</option>
                <option>Director</option>
                <option>Executive</option>
              </select>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Description</label>
            <textarea required rows={4} className="input-field" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
          </div>
          <div className="flex justify-end gap-3 mt-6">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium">Cancel</button>
            <button type="submit" className="btn-primary">{editingId ? 'Update Job' : 'Save Job'}</button>
          </div>
        </form>
      </Modal>
      
      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Job" 
        message="Are you sure you want to permanently delete this job listing? This action cannot be undone." 
      />
    </div>
  );
};

export default Jobs;
