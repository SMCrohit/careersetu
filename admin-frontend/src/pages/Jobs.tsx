import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, FileText, Briefcase, Star, ArrowLeft, Filter, X, Loader2, Mail, ExternalLink } from 'lucide-react';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';

interface Job {
  id: string;
  title: string;
  company_name: string;
  location: string;
  job_type: string;
  work_model: string;
  status: string;
  is_featured: boolean;
  application_routing_mode: string;
  employer_contact_email?: string;
  external_apply_url?: string;
  company_website?: string;
  vacancies_count?: number;
  shift_timing?: string;
  salary_min?: number;
  salary_max?: number;
  salary_type?: string;
  currency?: string;
  experience_required_years?: number;
  education_required?: string;
  skills_required?: string[];
  languages_required?: string[];
  description: string;
  created_datetime: string;
  screening_questions?: string[];
  is_cover_letter_required?: boolean;
}

const defaultFormData = {
  title: '', company_name: '', location: null as any, job_type: 'Full-time', work_model: 'On-Site',
  status: 'published', is_featured: false, application_routing_mode: 'manual_review',
  employer_contact_email: '', external_apply_url: '', company_website: '',
  vacancies_count: 1, shift_timing: 'Day Shift', salary_min: 0, salary_max: 0,
  salary_type: 'Per Year', currency: 'INR', experience_required_years: 0,
  education_required: 'Any Graduate', skills_required: [] as string[], languages_required: [] as string[],
  description: '', screening_questions: [] as string[], is_cover_letter_required: false
};

const Jobs = () => {
  
  const truncateText = (text: string, length: number = 50) => {
    if (!text) return '';
    return text.length > length ? text.substring(0, length) + '...' : text;
  };

  const getRoutingBadge = (mode?: string) => {
    switch (mode) {
      case 'manual_review': return <span className="inline-flex w-fit items-center gap-1 text-[10px] font-bold tracking-wider uppercase text-blue-600 bg-blue-50 px-2 py-0.5 rounded border border-blue-100"><Briefcase size={10} /> ATS</span>;
      case 'direct_email': return <span className="inline-flex w-fit items-center gap-1 text-[10px] font-bold tracking-wider uppercase text-purple-600 bg-purple-50 px-2 py-0.5 rounded border border-purple-100"><Mail size={10} /> Email</span>;
      case 'external_link': return <span className="inline-flex w-fit items-center gap-1 text-[10px] font-bold tracking-wider uppercase text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded border border-indigo-100"><ExternalLink size={10} /> External</span>;
      default: return <span className="inline-flex w-fit items-center gap-1 text-[10px] font-bold tracking-wider uppercase text-blue-600 bg-blue-50 px-2 py-0.5 rounded border border-blue-100"><Briefcase size={10} /> ATS</span>;
    }
  };

  const { showToast } = useToast();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState<any>(defaultFormData);
  const [pincodeLoading, setPincodeLoading] = useState(false);
  const [pincodeData, setPincodeData] = useState<any[]>([]);
  const [skillInput, setSkillInput] = useState('');
  const [skillSuggestions, setSkillSuggestions] = useState<any[]>([]);
  const [showSkillSuggestions, setShowSkillSuggestions] = useState(false);
  
  // Handle Pincode API
  const handlePincodeChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const code = e.target.value;
    // Just update a local string if you want to store it in formData.location, 
    // but formData.location is now an object. 
    setFormData({...formData, location: { ...formData.location, pincode: code }});
    
    if (code.length === 6) {
      setPincodeLoading(true);
      try {
        const res = await api.get(`/pincodes/${code}`);
        setPincodeData(res.data);
      } catch (err) {
        showToast("Invalid Pincode", "error");
      } finally {
        setPincodeLoading(false);
      }
    } else {
      setPincodeData([]);
    }
  };

  // Handle Skills Autocomplete
  useEffect(() => {
    if (skillInput.length > 1) {
      const fetchSkills = async () => {
        try {
          const res = await api.get(`/skills?q=${skillInput}`);
          setSkillSuggestions(res.data);
          setShowSkillSuggestions(true);
        } catch (e) {}
      };
      const debounce = setTimeout(fetchSkills, 300);
      return () => clearTimeout(debounce);
    } else {
      setSkillSuggestions([]);
      setShowSkillSuggestions(false);
    }
  }, [skillInput]);

  const addSkill = (skillName: string) => {
    const currentSkills = Array.isArray(formData.skills_required) ? formData.skills_required : [];
    if (!currentSkills.includes(skillName)) {
      setFormData({...formData, skills_required: [...currentSkills, skillName] as any});
    }
    setSkillInput('');
    setShowSkillSuggestions(false);
  };
  
  const createNewSkill = async () => {
    if (!skillInput.trim()) return;
    try {
      const res = await api.post('/skills', { name: skillInput });
      addSkill(res.data.name);
      showToast(`Created new skill: ${res.data.name}`, "success");
    } catch (e) {
      showToast("Failed to create skill", "error");
    }
  };
  
  const removeSkill = (skillName: string) => {
    setFormData({...formData, skills_required: (formData.skills_required as any).filter((s: string) => s !== skillName)});
  };

  const LANGUAGES_LIST = ["English", "Hindi", "Marathi", "Gujarati", "Tamil", "Telugu", "Bengali", "Kannada", "Malayalam", "French", "German", "Spanish"];
  
  const toggleLanguage = (lang: string) => {
    const currentLangs = Array.isArray(formData.languages_required) ? formData.languages_required : [];
    if (currentLangs.includes(lang)) {
      setFormData({...formData, languages_required: currentLangs.filter((l: string) => l !== lang) as any});
    } else {
      setFormData({...formData, languages_required: [...currentLangs, lang] as any});
    }
  };


  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  const [currentPage, setCurrentPage] = useState(1);
  const [currentLimit, setCurrentLimit] = useState(10);
  const [serverTotal, setServerTotal] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => { fetchJobsWithParams(null, 1, '', 10); }, []);

  // Filter Drawer State
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [availableCities, setAvailableCities] = useState<string[]>([]);
  const [filters, setFilters] = useState({
    status: '',
    type: '',
    city: '',
    min_salary: '',
    max_salary: '',
    experience: '',
    routing_mode: '',
    created_start: '',
    created_end: ''
  });

  const fetchLocations = async () => {
    try {
      const res = await api.get('/jobs/locations');
      setAvailableCities(res.data);
    } catch (error) {
      console.error("Failed to fetch locations");
    }
  };

  useEffect(() => {
    fetchLocations();
  }, []);

  const fetchJobsWithParams = async (overrideFilters: any = null, page: number = currentPage, search: string = searchTerm, limit: number = currentLimit) => {
    setLoading(true);
    try {
      const current = overrideFilters || filters;
      const params = new URLSearchParams();
      if(current.status) params.append('status', current.status);
      if(current.type) params.append('type', current.type);
      if(current.city) params.append('city', current.city);
      if(current.min_salary) params.append('min_salary', current.min_salary);
      if(current.max_salary) params.append('max_salary', current.max_salary);
      if(current.experience) params.append('experience', current.experience);
      if(current.routing_mode) params.append('application_routing_mode', current.routing_mode);
      if(current.created_start) params.append('created_start', current.created_start);
      if(current.created_end) params.append('created_end', current.created_end);
      
      params.append('page', page.toString());
      params.append('limit', limit.toString());
      if (search) params.append('search', search);

      const res = await api.get(`/admin/jobs?${params.toString()}`);
      setJobs(res.data.data);
      setServerTotal(res.data.total);
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
      showToast("Job deleted successfully", "success");
      fetchJobsWithParams();
    } catch (error) {
      showToast("Failed to delete job", "error");
    }
    setItemToDelete(null);
  };

  const openEditModal = (job: any) => {
    // Map existing job fields to form data
    setFormData({
      title: job.title || '',
      company_name: job.company_name || job.company || '',
      location: job.location || '',
      job_type: job.job_type || job.type || 'Full-time',
      work_model: job.work_model || 'On-Site',
      status: job.status || 'published',
      is_featured: job.is_featured || false,
      application_routing_mode: job.application_routing_mode || 'manual_review',
      employer_contact_email: job.employer_contact_email || '',
      external_apply_url: job.external_apply_url || '',
      company_website: job.company_website || '',
      vacancies_count: job.vacancies_count || 1,
      shift_timing: job.shift_timing || 'Day Shift',
      salary_min: job.salary_min || 0,
      salary_max: job.salary_max || 0,
      salary_type: job.salary_type || 'Per Year',
      currency: job.currency || 'INR',
      experience_required_years: job.experience_required_years || 0,
      education_required: job.education_required || 'Any Graduate',
      skills_required: job.skills_required ? (Array.isArray(job.skills_required) ? job.skills_required.join(', ') : job.skills_required) : '',
      languages_required: job.languages_required ? (Array.isArray(job.languages_required) ? job.languages_required.join(', ') : job.languages_required) : '',
      description: job.description || '',
      screening_questions: job.screening_questions || [],
      is_cover_letter_required: job.is_cover_letter_required || false
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
    
    // Fields are already perfectly formatted arrays and objects
    const payload = { ...formData };
    setIsSubmitting(true);

    try {
      if (editingId) {
        const res = await api.put(`/jobs/${editingId}`, payload);
        setJobs(jobs.map(j => j.id === editingId ? res.data : j));
        showToast("Job updated successfully", "success");
      } else {
        const res = await api.post('/jobs', payload);
        setJobs([res.data, ...jobs]);
        showToast("Job created successfully", "success");
      }
      setIsModalOpen(false);
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} job`, "error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns: Column<Job>[] = [
        {
      header: 'Job Title',
      accessorKey: 'title',
      sortable: true,
      cell: (job) => (
        <div className="flex items-center gap-2 whitespace-nowrap" title={job.title}>
          {job.is_featured && <Star size={14} className="text-yellow-400 fill-current" />}
          <span className="font-medium text-primaryBrand cursor-pointer hover:underline" onClick={() => openEditModal(job)}>
            {truncateText(job.title, 50)}
          </span>
        </div>
      )
    },
    {
      header: 'Company',
      accessorKey: 'company_name',
      sortable: true,
      cell: (job) => (
        <span className="whitespace-nowrap" title={job.company_name}>
          {truncateText(job.company_name, 50)}
        </span>
      )
    },
    {
      header: 'Status',
      accessorKey: 'status',
      sortable: true,
      cell: (job) => (
        <span className={`px-2.5 py-1 rounded-full text-xs font-medium border ${job.status === 'published' ? 'bg-green-50 text-green-700 border-green-200' : 'bg-gray-50 text-gray-700 border-gray-200'}`}>
          {(job.status || 'published').toUpperCase()}
        </span>
      )
    },
    {
      header: 'Location',
      accessorKey: 'location.city',
      sortable: true,
      cell: (job) => {
        const loc = typeof job.location === 'object' && job.location ? (job.location as any).city : job.location;
        return (
          <div className="flex flex-col">
            <span className="text-secondaryText">{loc || 'Remote'}</span>
            <span className="text-xs text-gray-400">{job.work_model || 'On-Site'}</span>
          </div>
        );
      }
    },
    {
      header: 'Salary',
      cell: (job) => {
        if (!job.salary_min && !job.salary_max) return <span className="text-gray-400">-</span>;
        return <span className="text-secondaryText text-sm whitespace-nowrap">₹{job.salary_min || 0} - ₹{job.salary_max || 'NA'}</span>;
      }
    },
    {
      header: 'Applicants',
      cell: (job) => (
        <span className="inline-block whitespace-nowrap px-2.5 py-1 bg-blue-50 text-blue-700 rounded-full text-xs font-medium border border-blue-200">
          {(job as any).applicants_count || 0} Applied
        </span>
      )
    },
    {
      header: 'Type',
      accessorKey: 'job_type',
      sortable: true,
      cell: (job) => <span className="inline-block whitespace-nowrap px-2.5 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium border border-gray-200">{job.job_type || (job as any).type}</span>
    },
    {
      header: 'Routing Mode',
      accessorKey: 'application_routing_mode',
      sortable: true,
      cell: (job) => getRoutingBadge(job.application_routing_mode)
    },
    {
      header: 'Created On',
      accessorKey: 'created_datetime',
      sortable: true,
      cell: (job) => (
        <span className="text-secondaryText text-sm whitespace-nowrap">
          {job.created_datetime ? new Date(job.created_datetime).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—'}
        </span>
      )
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
    <div className="animate-fade-in pb-8">
      {!isModalOpen ? (
        <>
          <div className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-2xl font-bold text-primaryText">Jobs Management</h1>
              <p className="text-secondaryText">Manage all listed jobs on the platform.</p>
            </div>
            <div className="flex items-center gap-3">
              <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
                <Plus size={18} /> Add New Job
              </button>
            </div>
          </div>

      {/* Filter Side Drawer */}
      {isFilterOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="absolute inset-0 bg-black/20" onClick={() => setIsFilterOpen(false)}></div>
          <div className="relative w-96 bg-white h-full shadow-2xl flex flex-col animate-slide-in-right">
            <div className="p-6 border-b border-border flex justify-between items-center">
              <h2 className="text-lg font-bold text-primaryText">Advanced Filters</h2>
              <button onClick={() => setIsFilterOpen(false)} className="text-gray-400 hover:text-gray-600"><X size={20}/></button>
            </div>
            <div className="p-6 flex-1 overflow-y-auto space-y-6">
              
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Routing Mode</label>
                <select
                  value={filters.routing_mode}
                  onChange={(e) => setFilters({ ...filters, routing_mode: e.target.value })}
                  className="input-field bg-white"
                >
                  <option value="">All Modes</option>
                  <option value="manual_review">Manual Review (ATS)</option>
                  <option value="direct_email">Direct Email</option>
                  <option value="external_link">External Link</option>
                </select>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-2">Created From</label>
                  <input
                    type="date"
                    value={filters.created_start}
                    onChange={(e) => setFilters({ ...filters, created_start: e.target.value })}
                    className="input-field bg-white px-2"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-2">Created To</label>
                  <input
                    type="date"
                    value={filters.created_end}
                    onChange={(e) => setFilters({ ...filters, created_end: e.target.value })}
                    className="input-field bg-white px-2"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Status</label>
                <select className="input-field bg-white" value={filters.status} onChange={e => setFilters({...filters, status: e.target.value})}>
                  <option value="">All Statuses</option>
                  <option value="published">Published</option>
                  <option value="draft">Draft</option>
                  <option value="closed">Closed</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Job Type</label>
                <select className="input-field bg-white" value={filters.type} onChange={e => setFilters({...filters, type: e.target.value})}>
                  <option value="">All Types</option>
                  <option value="Full-time">Full-time</option>
                  <option value="Part-time">Part-time</option>
                  <option value="Contract">Contract</option>
                  <option value="Internship">Internship</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">City (Location)</label>
                <select className="input-field bg-white" value={filters.city} onChange={e => setFilters({...filters, city: e.target.value})}>
                  <option value="">All Locations</option>
                  {availableCities.map(city => (
                    <option key={city} value={city}>{city}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Experience Level</label>
                <div className="space-y-2">
                  {['Fresher (0 yrs)', '1-3 Years', '3-5 Years', '5+ Years'].map(exp => (
                    <label key={exp} className="flex items-center gap-2 text-sm text-primaryText">
                      <input type="radio" name="exp" checked={filters.experience === exp} onChange={() => setFilters({...filters, experience: exp})} className="text-primaryBrand" />
                      {exp}
                    </label>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-secondaryText mb-2">Minimum Salary (₹)</label>
                <input type="number" className="input-field" placeholder="0" value={filters.min_salary} onChange={e => setFilters({...filters, min_salary: e.target.value})} />
              </div>

            </div>
            <div className="p-6 border-t border-border flex gap-3">
              <button onClick={() => {
                const empty = {status: '', type: '', city: '', min_salary: '', max_salary: '', experience: '', routing_mode: '', created_start: '', created_end: ''};
                setFilters(empty);
                setCurrentPage(1);
                fetchJobsWithParams(empty, 1, searchTerm, currentLimit);
              }} className="flex-1 py-2 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200">Clear All</button>
              <button onClick={() => {
                setIsFilterOpen(false);
                setCurrentPage(1);
                fetchJobsWithParams(filters, 1, searchTerm, currentLimit);
              }} className="flex-1 py-2 bg-primaryBrand text-white rounded-xl font-medium hover:bg-blue-700">Apply Filters</button>
            </div>
          </div>
        </div>
      )}

          <DataTable
            data={jobs}
            columns={columns}
            searchPlaceholder="Search by title, company…"
            searchableKeys={['title', 'company_name', 'company']}
            loading={loading}
            emptyStateMessage="No jobs found."
            emptyStateIcon={<Briefcase size={36} className="text-border" />}
            serverSideMode={true}
            serverSideTotal={serverTotal}
            serverSidePage={currentPage}
            onPageChange={(page) => {
              setCurrentPage(page);
              fetchJobsWithParams(null, page, searchTerm, currentLimit);
            }}
            onSearchChange={(search) => {
              setSearchTerm(search);
              setCurrentPage(1);
              fetchJobsWithParams(null, 1, search, currentLimit);
            }}
            onPageSizeChange={(size) => {
              setCurrentLimit(size);
              setCurrentPage(1);
              fetchJobsWithParams(null, 1, searchTerm, size);
            }}
            toolbarExtras={
              <button onClick={() => setIsFilterOpen(true)} className="flex items-center gap-2 px-4 py-2 bg-white border border-border rounded-xl text-secondaryText hover:text-primaryText shadow-sm h-[42px]">
                <Filter size={18} />
                Filters {Object.values(filters).filter(v => v).length > 0 && <span className="w-5 h-5 bg-primaryBrand text-white text-xs flex items-center justify-center rounded-full">{Object.values(filters).filter(v => v).length}</span>}
              </button>
            }
          />
        </>
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-border animate-fade-in max-w-5xl mx-auto">
          <div className="p-6 border-b border-border bg-white flex items-center gap-4 rounded-t-2xl">
            <button onClick={() => setIsModalOpen(false)} className="text-secondaryText hover:text-primaryText transition-colors p-2 -ml-2 rounded-lg hover:bg-gray-100 flex items-center gap-2 font-medium">
              <ArrowLeft size={20} /> Back
            </button>
            <div className="h-6 w-px bg-border mx-2"></div>
            <div>
              <h2 className="text-xl font-bold text-primaryText">{editingId ? "Edit Job Posting" : "Add New Job"}</h2>
            </div>
          </div>
          
          <form onSubmit={handleSubmit} className="p-8 space-y-10">
              
              {/* Section 1: Basic Info */}
              <div>
                <h3 className="text-md font-semibold text-primaryText mb-4 border-b pb-2">1. Basic Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Job Title</label>
                    <input required type="text" className="input-field" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Company Name</label>
                    <input required type="text" className="input-field" value={formData.company_name} onChange={e => setFormData({...formData, company_name: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Status</label>
                    <select className="input-field bg-white" value={formData.status} onChange={e => setFormData({...formData, status: e.target.value})}>
                      <option value="draft">Draft</option>
                      <option value="published">Published</option>
                      <option value="closed">Closed</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Company Website</label>
                    <input type="url" className="input-field" placeholder="https://..." value={formData.company_website} onChange={e => setFormData({...formData, company_website: e.target.value})} />
                  </div>
                  <div className="flex items-center mt-6 gap-2 col-span-2">
                    <input type="checkbox" id="featured" checked={formData.is_featured} onChange={e => setFormData({...formData, is_featured: e.target.checked})} className="w-5 h-5 rounded border-gray-300 text-primaryBrand" />
                    <label htmlFor="featured" className="text-sm font-medium text-secondaryText">Feature this job (Pins to top)</label>
                  </div>
                </div>
              </div>

              {/* Section 2: Routing */}
              <div>
                <h3 className="text-md font-semibold text-primaryText mb-4 border-b pb-2">2. Application Routing</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Routing Mode</label>
                    <select className="input-field bg-white" value={formData.application_routing_mode} onChange={e => setFormData({...formData, application_routing_mode: e.target.value})}>
                      <option value="manual_review">Manual Review (Admin reviews in CareerSetu)</option>
                      <option value="direct_to_employer">Direct Email to Employer (Auto-forward)</option>
                      <option value="external_link">External Link (Redirect student to URL)</option>
                    </select>
                  </div>
                  
                  {formData.application_routing_mode === 'direct_to_employer' && (
                    <div>
                      <label className="block text-sm font-medium text-secondaryText mb-1">Employer Contact Email</label>
                      <input required type="email" className="input-field" value={formData.employer_contact_email} onChange={e => setFormData({...formData, employer_contact_email: e.target.value})} />
                    </div>
                  )}

                  {formData.application_routing_mode === 'external_link' && (
                    <div>
                      <label className="block text-sm font-medium text-secondaryText mb-1">External Apply URL</label>
                      <input required type="url" className="input-field" value={formData.external_apply_url} onChange={e => setFormData({...formData, external_apply_url: e.target.value})} />
                    </div>
                  )}
                </div>
              </div>

              {/* Section 3: Job Specifics */}
              <div>
                <h3 className="text-md font-semibold text-primaryText mb-4 border-b pb-2">3. Job Details & Compensation</h3>
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Job Type</label>
                    <select className="input-field bg-white" value={formData.job_type} onChange={e => setFormData({...formData, job_type: e.target.value})}>
                      <option>Full-time</option>
                      <option>Part-time</option>
                      <option>Contract</option>
                      <option>Internship</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Work Model</label>
                    <select className="input-field bg-white" value={formData.work_model} onChange={e => setFormData({...formData, work_model: e.target.value})}>
                      <option>On-Site</option>
                      <option>Remote</option>
                      <option>Hybrid</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Shift Timing</label>
                    <select className="input-field bg-white" value={formData.shift_timing} onChange={e => setFormData({...formData, shift_timing: e.target.value})}>
                      <option>Day Shift</option>
                      <option>Night Shift</option>
                      <option>Flexible</option>
                      <option>Rotational</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Vacancies Count</label>
                    <input type="number" min="1" className="input-field" value={formData.vacancies_count} onChange={e => setFormData({...formData, vacancies_count: parseInt(e.target.value) || 1})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Salary Type</label>
                    <select className="input-field bg-white" value={formData.salary_type} onChange={e => setFormData({...formData, salary_type: e.target.value})}>
                      <option>Per Year</option>
                      <option>Per Month</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Min Salary (INR)</label>
                    <input type="number" className="input-field" value={formData.salary_min} onChange={e => setFormData({...formData, salary_min: parseInt(e.target.value) || 0})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Max Salary (INR)</label>
                    <input type="number" className="input-field" value={formData.salary_max} onChange={e => setFormData({...formData, salary_max: parseInt(e.target.value) || 0})} />
                  </div>

                  {/* Standardized Location (Pincode) - Moved to bottom */}
                  <div className="col-span-2 grid grid-cols-2 gap-4 border p-4 rounded-xl bg-gray-50 mt-2">
                    <div className="col-span-2">
                      <p className="text-sm font-semibold text-primaryText mb-1">Standardized Location (Pincode)</p>
                      <p className="text-xs text-secondaryText mb-3">Enter a 6-digit pin code to auto-fetch the city and state.</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-secondaryText mb-1">Pincode</label>
                      <div className="relative">
                        <input type="text" maxLength={6} className="input-field pr-10" value={formData.location?.pincode || ''} onChange={handlePincodeChange} placeholder="e.g. 400001" />
                        {pincodeLoading && <div className="absolute right-3 top-2.5 w-5 h-5 border-2 border-primaryBrand border-t-transparent rounded-full animate-spin"></div>}
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-secondaryText mb-1">Select Area</label>
                      <select 
                        className="input-field bg-white disabled:bg-gray-100" 
                        disabled={pincodeData.length === 0}
                        value={formData.location?.area || ''}
                        onChange={e => {
                          const selected = pincodeData.find(p => p.area === e.target.value);
                          if(selected) setFormData({...formData, location: selected});
                        }}
                      >
                        <option value="">{pincodeData.length > 0 ? "Select Area..." : "Enter valid pincode first"}</option>
                        {pincodeData.map(p => (
                          <option key={p.id} value={p.area}>{p.area}</option>
                        ))}
                      </select>
                    </div>
                    
                    {formData.location?.city && formData.location?.state && (
                      <div className="col-span-2 flex gap-4 mt-1 border-t pt-4">
                        <div className="flex-1">
                           <label className="block text-xs font-medium text-gray-500 mb-1">City</label>
                           <input type="text" disabled className="input-field bg-gray-100 text-gray-600 font-medium" value={formData.location.city} />
                        </div>
                        <div className="flex-1">
                           <label className="block text-xs font-medium text-gray-500 mb-1">State</label>
                           <input type="text" disabled className="input-field bg-gray-100 text-gray-600 font-medium" value={formData.location.state} />
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Section 4: Candidate Requirements */}
              <div>
                <h3 className="text-md font-semibold text-primaryText mb-4 border-b pb-2">4. Candidate Requirements</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Min Experience (Years)</label>
                    <input type="number" step="0.5" className="input-field" value={formData.experience_required_years} onChange={e => setFormData({...formData, experience_required_years: parseFloat(e.target.value) || 0})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-secondaryText mb-1">Education Required</label>
                    <input type="text" className="input-field" placeholder="e.g. B.Tech, Any Graduate" value={formData.education_required} onChange={e => setFormData({...formData, education_required: e.target.value})} />
                  </div>
                  <div className="col-span-2">
                    <label className="block text-sm font-medium text-secondaryText mb-1">Required Skills (Fuzzy Autocomplete)</label>
                    <div className="relative">
                      <input 
                        type="text" 
                        className="input-field" 
                        placeholder="Type to search and add skills..." 
                        value={skillInput} 
                        onChange={e => setSkillInput(e.target.value)} 
                        onFocus={() => setShowSkillSuggestions(true)}
                      />
                      {showSkillSuggestions && skillInput.length > 1 && (
                        <div className="absolute z-10 w-full mt-1 bg-white border border-border rounded-xl shadow-lg max-h-60 overflow-auto">
                          {skillSuggestions.map(s => (
                            <div key={s.id} onClick={() => addSkill(s.name)} className="px-4 py-2 hover:bg-gray-50 cursor-pointer text-sm text-primaryText">
                              {s.name}
                            </div>
                          ))}
                          <div onClick={createNewSkill} className="px-4 py-2 bg-primaryBrand/5 text-primaryBrand hover:bg-primaryBrand/10 cursor-pointer text-sm font-medium border-t border-border flex justify-between">
                            <span>"{skillInput}" not found?</span>
                            <span>+ Create Skill</span>
                          </div>
                        </div>
                      )}
                    </div>
                    <div className="flex flex-wrap gap-2 mt-3">
                      {(Array.isArray(formData.skills_required) ? formData.skills_required : []).map((skill: string) => (
                        <span key={skill} className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm font-medium flex items-center gap-1 border border-blue-200">
                          {skill} <button type="button" onClick={() => removeSkill(skill)} className="hover:text-blue-900 ml-1">✕</button>
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="col-span-2">
                    <label className="block text-sm font-medium text-secondaryText mb-2">Required Languages</label>
                    <div className="flex flex-wrap gap-2">
                      {LANGUAGES_LIST.map(lang => {
                        const isSelected = (Array.isArray(formData.languages_required) ? formData.languages_required : []).includes(lang);
                        return (
                          <button
                            key={lang}
                            type="button"
                            onClick={() => toggleLanguage(lang)}
                            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors border ${isSelected ? 'bg-primaryBrand text-white border-primaryBrand' : 'bg-white text-secondaryText border-border hover:border-primaryBrand'}`}
                          >
                            {lang}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>

              {/* Section 5: Application Requirements (Cover Letter & Screening) */}
              <div className="bg-gray-50/50 p-6 rounded-xl space-y-6 border border-gray-100 mb-6">
                <div className="flex items-center gap-2 mb-4">
                  <FileText size={18} className="text-primaryBrand" />
                  <h3 className="font-semibold text-primaryText">5. Application Requirements</h3>
                </div>
                
                <div className="flex items-center justify-between bg-white p-4 rounded-xl border border-border">
                  <div>
                    <h4 className="font-medium text-primaryText">Cover Letter</h4>
                    <p className="text-sm text-secondaryText">Require candidates to write a cover letter when applying.</p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" className="sr-only peer" checked={formData.is_cover_letter_required} onChange={e => setFormData({...formData, is_cover_letter_required: e.target.checked})} />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primaryBrand"></div>
                  </label>
                </div>

                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <h4 className="font-medium text-primaryText">Screening Questions</h4>
                    <button type="button" onClick={() => setFormData({...formData, screening_questions: [...(formData.screening_questions || []), '']})} className="text-sm font-medium text-primaryBrand hover:text-blue-700 flex items-center gap-1">
                      <Plus size={14} /> Add Question
                    </button>
                  </div>
                  {(formData.screening_questions || []).map((q: string, idx: number) => (
                    <div key={idx} className="flex gap-2 items-start">
                      <div className="bg-gray-100 text-gray-500 w-8 h-[42px] rounded-lg flex items-center justify-center font-medium shrink-0">Q{idx + 1}</div>
                      <input 
                        type="text" 
                        className="input-field bg-white flex-1" 
                        placeholder="e.g. Why do you want to work here?" 
                        value={q} 
                        onChange={(e) => {
                          const newQ = [...formData.screening_questions];
                          newQ[idx] = e.target.value;
                          setFormData({...formData, screening_questions: newQ});
                        }} 
                      />
                      <button type="button" onClick={() => {
                        const newQ = [...formData.screening_questions];
                        newQ.splice(idx, 1);
                        setFormData({...formData, screening_questions: newQ});
                      }} className="w-[42px] h-[42px] flex items-center justify-center text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-xl transition-colors shrink-0">
                        <Trash2 size={18} />
                      </button>
                    </div>
                  ))}
                  {(formData.screening_questions || []).length === 0 && (
                    <p className="text-sm text-secondaryText italic bg-white p-4 rounded-xl border border-border text-center">No screening questions added.</p>
                  )}
                </div>
              </div>

              {/* Section 6: Description */}
              <div>
                <h3 className="text-md font-semibold text-primaryText mb-4 border-b pb-2">6. Full Description</h3>
                <textarea required rows={6} className="input-field w-full" placeholder="Describe the job responsibilities, perks, etc..." value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})}></textarea>
              </div>


            </form>
            <div className="p-6 border-t border-border bg-gray-50 flex justify-end gap-3 rounded-b-2xl">
              <button type="button" onClick={() => setIsModalOpen(false)} className="px-6 py-2.5 text-secondaryText hover:text-primaryText font-medium bg-white border border-border rounded-xl">Cancel</button>
              <button onClick={handleSubmit} disabled={isSubmitting} className="btn-primary px-8 flex items-center justify-center gap-2 min-w-[160px]">
                {isSubmitting ? (
                  <>
                    <Loader2 size={18} className="animate-spin" />
                    Saving...
                  </>
                ) : (
                  editingId ? 'Update Job' : 'Save Job Posting'
                )}
              </button>
            </div>
          </div>
      )}
      
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
