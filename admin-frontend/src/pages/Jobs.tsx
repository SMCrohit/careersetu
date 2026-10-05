import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, Briefcase } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

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
  experience: string;
  profession: string;
}

const defaultFormData = {
  title: '', company: '', location: '', salary: '', 
  type: 'Full-time', level: 'Entry level', description: '', 
  posted_time: 'Just now', applicants: '0', requirements: [],
  experience: '0-1 Years', profession: 'Professional'
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
  
  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchJobs();
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

  // ─── Export helpers ────────────────────────────────────────────────────────
  const exportRows = jobs.map((j, i) => ({
    '#': i + 1,
    Title: j.title || '—',
    Company: j.company || '—',
    Location: j.location || '—',
    Type: j.type || '—',
    Level: j.level || '—',
    Salary: j.salary || '—',
    Experience: j.experience || '—',
  }));

  const exportToCSV = () => {
    const headers = Object.keys(exportRows[0] || {});
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'jobs.csv';
    a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Jobs');
    XLSX.writeFile(wb, 'jobs.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Jobs Directory', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${jobs.length} jobs`, 14, 22);

    autoTable(doc, {
      startY: 28,
      head: [['#', 'Title', 'Company', 'Location', 'Type', 'Level', 'Salary', 'Experience']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });

    doc.save('jobs.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
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
      requirements: [],
      experience: job.experience || '0-1 Years',
      profession: job.profession || 'Professional'
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

  const columns: Column<Job>[] = [
    {
      header: 'Job Title',
      accessorKey: 'title',
      sortable: true,
      cell: (job) => <span className="font-medium text-primaryBrand">{job.title}</span>
    },
    {
      header: 'Company',
      accessorKey: 'company',
      sortable: true,
      cell: (job) => <span className="text-primaryText">{job.company}</span>
    },
    {
      header: 'Location',
      accessorKey: 'location',
      sortable: true,
      cell: (job) => <span className="text-secondaryText">{job.location}</span>
    },
    {
      header: 'Type',
      accessorKey: 'type',
      sortable: true,
      cell: (job) => <span className="px-2.5 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium border border-gray-200">{job.type}</span>
    },
    {
      header: 'Level',
      accessorKey: 'level',
      sortable: true,
      cell: (job) => <span className="text-secondaryText">{job.level}</span>
    },
    {
      header: 'Actions',
      cell: (job) => (
        <div className="flex items-center justify-end gap-3">
          <button onClick={() => openEditModal(job)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
          <button onClick={() => { setItemToDelete(job.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
        </div>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Jobs Management</h1>
          <p className="text-secondaryText">Manage all listed jobs on the platform.</p>
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
            <Plus size={18} /> Add New Job
          </button>
        </div>
      </div>

      <DataTable
        data={jobs}
        columns={columns}
        searchPlaceholder="Search by title, company, location…"
        searchableKeys={['title', 'company', 'location', 'type']}
        loading={loading}
        emptyStateMessage="No jobs found."
        emptyStateIcon={<Briefcase size={36} className="text-border" />}
      />

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
                <option>Remote</option>
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
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Experience</label>
              <select className="input-field bg-white" value={formData.experience} onChange={e => setFormData({...formData, experience: e.target.value})}>
                <option>0-1 Years</option>
                <option>1-3 Years</option>
                <option>3-5 Years</option>
                <option>5+ Years</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Profession</label>
              <select className="input-field bg-white" value={formData.profession} onChange={e => setFormData({...formData, profession: e.target.value})}>
                <option>Professional</option>
                <option>Engineer</option>
                <option>IAS</option>
                <option>IPS</option>
                <option>Teacher</option>
                <option>Lawyer</option>
                <option>Nurse</option>
                <option>Software Developer</option>
                <option>Accountant</option>
                <option>Banker</option>
                <option>Other</option>
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
