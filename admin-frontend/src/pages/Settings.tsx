import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Trash2, Users, Target, Megaphone, Edit2, X, Image as ImageIcon } from 'lucide-react';
import { useToast } from '../context/ToastContext';
import Banners from './Banners';

const Settings = () => {
  const [activeTab, setActiveTab] = useState<'staff' | 'goals' | 'sources' | 'skills' | 'test_categories' | 'test_taxonomy' | 'home_banners'>('staff');
  const { showToast } = useToast();
  
  // Staff State
  const [staffList, setStaffList] = useState<any[]>([]);
  const [isStaffModalOpen, setIsStaffModalOpen] = useState(false);
  const [staffForm, setStaffForm] = useState({ full_name: '', email: '', password: '', role: 'staff' });
  const [staffError, setStaffError] = useState('');
  
  // Goals State
  const [goals, setGoals] = useState<any[]>([]);
  const [isGoalModalOpen, setIsGoalModalOpen] = useState(false);
  const [goalName, setGoalName] = useState('');
  const [goalError, setGoalError] = useState('');
  
  // Test Categories State
  const [testCategories, setTestCategories] = useState<any[]>([]);
  const [isTestCategoryModalOpen, setIsTestCategoryModalOpen] = useState(false);
  const [testCategoryName, setTestCategoryName] = useState('');
  const [testCategoryError, setTestCategoryError] = useState('');
  
  // Acquisition Sources State
  const [sources, setSources] = useState<any[]>([]);
  const [isSourceModalOpen, setIsSourceModalOpen] = useState(false);
  const [sourceName, setSourceName] = useState('');
  const [sourceError, setSourceError] = useState('');

  // Skills State
  const [skills, setSkills] = useState<any[]>([]);
  const [isSkillModalOpen, setIsSkillModalOpen] = useState(false);
  const [skillForm, setSkillForm] = useState({ id: '', name: '', is_approved: true });
  const [skillError, setSkillError] = useState('');
  
  // Merge Skills State
  const [isMergeModalOpen, setIsMergeModalOpen] = useState(false);
  const [mergeForm, setMergeForm] = useState({ target_skill_id: '', source_skill_id: '' });
  const [mergeError, setMergeError] = useState('');

  // Taxonomy State
  const [taxonomies, setTaxonomies] = useState<any[]>([]);
  const [taxonomyTypeFilter, setTaxonomyTypeFilter] = useState<'section'|'topic'|'subtopic'>('section');
  const [isTaxonomyModalOpen, setIsTaxonomyModalOpen] = useState(false);
  const [taxonomyForm, setTaxonomyForm] = useState({ id: '', type: 'section', name: '' });
  
  const [isMergeTaxonomyModalOpen, setIsMergeTaxonomyModalOpen] = useState(false);
  const [mergeTaxonomyForm, setMergeTaxonomyForm] = useState({ type: 'section', target_name: '', source_name: '' });


  useEffect(() => {
    if (activeTab === 'staff') fetchStaff();
    else if (activeTab === 'goals') fetchGoals();
    else if (activeTab === 'sources') fetchSources();
    else if (activeTab === 'skills') fetchSkills();
    else if (activeTab === 'test_categories') fetchTestCategories();
    else if (activeTab === 'test_taxonomy') fetchTaxonomies();
  }, [activeTab]);

  
  const fetchTaxonomies = async () => {
    try {
      const response = await api.get('/test-taxonomy');
      setTaxonomies(response.data);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchSkills = async () => {
    try {
      const response = await api.get('/skills?limit=500'); // fetch all or many
      setSkills(response.data);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchStaff = async () => {
    try {
      const response = await api.get('/users'); // Assuming /users returns all users, we filter locally or should use a dedicated endpoint. 
      // For now we'll filter locally
      const staff = response.data.filter((u: any) => ['admin', 'manager', 'staff'].includes(u.role));
      setStaffList(staff);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchGoals = async () => {
    try {
      const response = await api.get('/goals');
      setGoals(response.data);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchTestCategories = async () => {
    try {
      const response = await api.get('/test-categories');
      setTestCategories(response.data);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchSources = async () => {
    try {
      const response = await api.get('/acquisition-sources');
      setSources(response.data);
    } catch (err) {
      console.error(err);
    }
  };

  const handleCreateStaff = async (e: React.FormEvent) => {
    e.preventDefault();
    setStaffError('');
    try {
      await api.post('/settings/staff', staffForm);
      setIsStaffModalOpen(false);
      setStaffForm({ full_name: '', email: '', password: '', role: 'staff' });
      fetchStaff();
    } catch (err: any) {
      setStaffError(err.response?.data?.detail || 'Failed to create staff');
    }
  };

  const handleCreateGoal = async (e: React.FormEvent) => {
    e.preventDefault();
    setGoalError('');
    try {
      await api.post('/settings/goals', { name: goalName });
      setIsGoalModalOpen(false);
      setGoalName('');
      fetchGoals();
    } catch (err: any) {
      setGoalError(err.response?.data?.detail || 'Failed to create goal');
    }
  };

  const handleDeleteGoal = async (id: string) => {
    if (!window.confirm("Are you sure you want to delete this goal?")) return;
    try {
      await api.delete(`/settings/goals/${id}`);
      fetchGoals();
    } catch (err) {
      console.error(err);
    }
  };

  const handleCreateTestCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    setTestCategoryError('');
    try {
      await api.post('/settings/test-categories', { name: testCategoryName });
      setIsTestCategoryModalOpen(false);
      setTestCategoryName('');
      fetchTestCategories();
    } catch (err: any) {
      setTestCategoryError(err.response?.data?.detail || 'Failed to create category');
    }
  };

  const handleDeleteTestCategory = async (id: string) => {
    if (!window.confirm("Are you sure you want to delete this category?")) return;
    try {
      await api.delete(`/settings/test-categories/${id}`);
      fetchTestCategories();
    } catch (err) {
      console.error(err);
    }
  };

  const handleCreateSource = async (e: React.FormEvent) => {
    e.preventDefault();
    setSourceError('');
    try {
      await api.post('/settings/acquisition-sources', { name: sourceName });
      setIsSourceModalOpen(false);
      setSourceName('');
      fetchSources();
    } catch (err: any) {
      setSourceError(err.response?.data?.detail || 'Failed to create source');
    }
  };

  const handleDeleteSource = async (id: string) => {
    if (!window.confirm("Are you sure you want to delete this source?")) return;
    try {
      await api.delete(`/settings/acquisition-sources/${id}`);
      fetchSources();
    } catch (err) {
      console.error(err);
    }
  };

  const handleSaveSkill = async (e: React.FormEvent) => {
    e.preventDefault();
    setSkillError('');
    try {
      if (skillForm.id) {
        await api.put(`/skills/${skillForm.id}`, { name: skillForm.name, is_approved: skillForm.is_approved });
      } else {
        await api.post('/skills', { name: skillForm.name, is_approved: skillForm.is_approved });
      }
      setIsSkillModalOpen(false);
      setSkillForm({ id: '', name: '', is_approved: true });
      fetchSkills();
    } catch (err: any) {
      setSkillError(err.response?.data?.detail || 'Failed to save skill');
    }
  };

  
  const handleCreateTaxonomy = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (taxonomyForm.id) {
        await api.put(`/test-taxonomy/${taxonomyForm.id}`, { name: taxonomyForm.name });
        showToast("Taxonomy updated", "success");
      } else {
        await api.post('/test-taxonomy', { type: taxonomyForm.type, name: taxonomyForm.name });
        showToast("Taxonomy created", "success");
      }
      setIsTaxonomyModalOpen(false);
      fetchTaxonomies();
    } catch (err) {
      showToast("Error saving taxonomy", "error");
    }
  };

  const handleDeleteTaxonomy = async (id: string) => {
    try {
      await api.delete(`/test-taxonomy/${id}`);
      showToast("Taxonomy deleted", "success");
      fetchTaxonomies();
    } catch (err) {
      showToast("Error deleting taxonomy", "error");
    }
  };

  const handleMergeTaxonomy = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.post('/test-taxonomy/merge', {
        type: mergeTaxonomyForm.type,
        source_name: mergeTaxonomyForm.source_name,
        target_name: mergeTaxonomyForm.target_name
      });
      showToast("Merged successfully", "success");
      setIsMergeTaxonomyModalOpen(false);
      fetchTaxonomies();
    } catch (err) {
      showToast("Error merging", "error");
    }
  };

  const handleMergeSkills = async (e: React.FormEvent) => {
    e.preventDefault();
    setMergeError('');
    if (mergeForm.source_skill_id === mergeForm.target_skill_id) {
      setMergeError('Cannot merge a skill into itself');
      return;
    }
    try {
      const sourceSkill = skills.find(s => s.id === mergeForm.source_skill_id);
      const targetSkill = skills.find(s => s.id === mergeForm.target_skill_id);
      if (!sourceSkill || !targetSkill) {
        setMergeError('Could not find selected skills.');
        return;
      }

      await api.post('/skills/merge', { 
        target_skill_name: targetSkill.name, 
        source_skill_names: [sourceSkill.name]
      });
      setIsMergeModalOpen(false);
      setMergeForm({ target_skill_id: '', source_skill_id: '' });
      fetchSkills();
    } catch (err: any) {
      setMergeError(err.response?.data?.detail || 'Failed to merge skills');
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-primaryText mb-6">Settings</h1>
      
      {/* Tabs */}
      <div className="flex overflow-x-auto border-b border-borderDark mb-6 scrollbar-hide w-full">
        <button 
          className={`flex items-center gap-2 px-6 py-3 font-medium whitespace-nowrap shrink-0 transition-colors ${activeTab === 'staff' ? 'border-b-2 border-primaryBrand text-primaryBrand' : 'text-secondaryText hover:text-primaryText'}`}
          onClick={() => setActiveTab('staff')}
        >
          <Users size={18} /> Staff Management
        </button>
        <button 
          className={`flex items-center gap-2 px-6 py-3 font-medium whitespace-nowrap shrink-0 transition-colors ${activeTab === 'goals' ? 'border-b-2 border-primaryBrand text-primaryBrand' : 'text-secondaryText hover:text-primaryText'}`}
          onClick={() => setActiveTab('goals')}
        >
          <Target size={18} /> Student Goals
        </button>
        <button 
          className={`flex items-center gap-2 px-6 py-3 font-medium whitespace-nowrap shrink-0 transition-colors ${activeTab === 'sources' ? 'border-b-2 border-primaryBrand text-primaryBrand' : 'text-secondaryText hover:text-primaryText'}`}
          onClick={() => setActiveTab('sources')}
        >
          <Megaphone size={18} /> Acquisition Sources
        </button>
        <button 
          className={`flex items-center gap-2 px-6 py-3 font-medium whitespace-nowrap shrink-0 transition-colors ${activeTab === 'skills' ? 'border-b-2 border-primaryBrand text-primaryBrand' : 'text-secondaryText hover:text-primaryText'}`}
          onClick={() => setActiveTab('skills')}
        >
          <Target size={18} /> Skills Dictionary
        </button>
        <button 
          className={`flex items-center gap-2 px-6 py-3 font-medium whitespace-nowrap shrink-0 transition-colors ${activeTab === 'test_categories' ? 'border-b-2 border-primaryBrand text-primaryBrand' : 'text-secondaryText hover:text-primaryText'}`}
          onClick={() => setActiveTab('test_categories')}
        >
          <Target size={18} /> Test Categories
        </button>
        <button 
          className={`flex items-center gap-2 px-6 py-3 font-medium whitespace-nowrap shrink-0 transition-colors ${activeTab === 'test_taxonomy' ? 'border-b-2 border-primaryBrand text-primaryBrand' : 'text-secondaryText hover:text-primaryText'}`}
          onClick={() => setActiveTab('test_taxonomy')}
        >
          <Target size={18} /> Question Taxonomy
        </button>
        <button 
          className={`flex items-center gap-2 px-6 py-3 font-medium whitespace-nowrap shrink-0 transition-colors ${activeTab === 'home_banners' ? 'border-b-2 border-primaryBrand text-primaryBrand' : 'text-secondaryText hover:text-primaryText'}`}
          onClick={() => setActiveTab('home_banners')}
        >
          <ImageIcon size={18} /> Home Banners
        </button>
      </div>


      {/* Taxonomy Tab */}
      {activeTab === 'test_taxonomy' && (
        <div className="animate-fade-in">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-primaryText">Question Taxonomy</h2>
            <div className="flex gap-2 shrink-0">
              <select 
                className="input-field bg-white py-2 min-w-[140px]" 
                value={taxonomyTypeFilter} 
                onChange={(e: any) => setTaxonomyTypeFilter(e.target.value)}
              >
                <option value="section">Sections</option>
                <option value="topic">Topics</option>
                <option value="subtopic">Sub-Topics</option>
              </select>
              <button onClick={() => setIsMergeTaxonomyModalOpen(true)} className="px-4 py-2 border border-gray-300 text-secondaryText font-medium rounded-md hover:bg-gray-50 transition-colors whitespace-nowrap">
                Merge Tool
              </button>
              <button onClick={() => { setTaxonomyForm({ id: '', type: taxonomyTypeFilter, name: '' }); setIsTaxonomyModalOpen(true); }} className="btn-primary flex items-center gap-2 whitespace-nowrap">
                <Plus size={16} /> Add New
              </button>
            </div>
          </div>
          
          <div className="card overflow-hidden">
            <table className="w-full text-left">
              <thead className="bg-background">
                <tr>
                  <th className="px-6 py-4 font-medium text-secondaryText">Name</th>
                  <th className="px-6 py-4 font-medium text-secondaryText text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-borderDark">
                {taxonomies.filter(t => t.type === taxonomyTypeFilter).map((tax) => (
                  <tr key={tax.id} className="hover:bg-background/50 transition-colors">
                    <td className="px-6 py-4 text-primaryText font-medium">{tax.name}</td>
                    <td className="px-6 py-4 text-right">
                      <button onClick={() => { setTaxonomyForm(tax); setIsTaxonomyModalOpen(true); }} className="text-secondaryText hover:text-primaryBrand mr-3"><Edit2 size={16} /></button>
                      <button onClick={() => handleDeleteTaxonomy(tax.id)} className="text-error hover:text-red-700"><Trash2 size={16} /></button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Staff Tab */}
      {activeTab === 'staff' && (
        <div className="animate-fade-in">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-primaryText">Staff Members</h2>
            <button onClick={() => setIsStaffModalOpen(true)} className="btn-primary flex items-center gap-2">
              <Plus size={16} /> Add Staff
            </button>
          </div>
          
          <div className="card overflow-hidden">
            <table className="w-full text-left">
              <thead className="bg-background">
                <tr>
                  <th className="px-6 py-4 font-medium text-secondaryText">Name</th>
                  <th className="px-6 py-4 font-medium text-secondaryText">Email</th>
                  <th className="px-6 py-4 font-medium text-secondaryText">Role</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-borderDark">
                {staffList.map((staff) => (
                  <tr key={staff.id} className="hover:bg-background/50 transition-colors">
                    <td className="px-6 py-4 text-primaryText font-medium">{staff.full_name}</td>
                    <td className="px-6 py-4 text-secondaryText">{staff.email}</td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 bg-primaryBrand/10 text-primaryBrand rounded-full text-xs font-medium uppercase tracking-wider">
                        {staff.role}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Goals Tab */}
      {activeTab === 'goals' && (
        <div className="animate-fade-in">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-primaryText">Student Goals</h2>
            <button onClick={() => setIsGoalModalOpen(true)} className="btn-primary flex items-center gap-2">
              <Plus size={16} /> Add Goal
            </button>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {goals.map((goal) => (
              <div key={goal.id} className="card p-4 flex justify-between items-center group">
                <span className="font-medium text-primaryText">{goal.name}</span>
                <button 
                  onClick={() => handleDeleteGoal(goal.id)}
                  className="text-error opacity-0 group-hover:opacity-100 transition-opacity p-2 hover:bg-error/10 rounded-full"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Test Categories Tab */}
      {activeTab === 'test_categories' && (
        <div className="animate-fade-in">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-primaryText">Test Categories</h2>
            <button onClick={() => setIsTestCategoryModalOpen(true)} className="btn-primary flex items-center gap-2">
              <Plus size={16} /> Add Category
            </button>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {testCategories.map((category) => (
              <div key={category.id} className="card p-4 flex justify-between items-center group">
                <span className="font-medium text-primaryText">{category.name}</span>
                <button 
                  onClick={() => handleDeleteTestCategory(category.id)}
                  className="text-error opacity-0 group-hover:opacity-100 transition-opacity p-2 hover:bg-error/10 rounded-full"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Sources Tab */}
      {activeTab === 'sources' && (
        <div className="animate-fade-in">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-primaryText">Acquisition Sources</h2>
            <button onClick={() => setIsSourceModalOpen(true)} className="btn-primary flex items-center gap-2">
              <Plus size={16} /> Add Source
            </button>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {sources.map((source) => (
              <div key={source.id} className="card p-4 flex justify-between items-center group">
                <span className="font-medium text-primaryText">{source.name}</span>
                <button 
                  onClick={() => handleDeleteSource(source.id)}
                  className="text-error opacity-0 group-hover:opacity-100 transition-opacity p-2 hover:bg-error/10 rounded-full"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Skills Tab */}
      {activeTab === 'skills' && (
        <div className="animate-fade-in">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-primaryText">Skills Dictionary</h2>
            <div className="flex gap-2">
              <button onClick={() => setIsMergeModalOpen(true)} className="px-4 py-2 bg-gray-100 text-gray-700 hover:bg-gray-200 rounded-xl font-medium transition-colors flex items-center gap-2">
                Merge Skills
              </button>
              <button onClick={() => { setSkillForm({ id: '', name: '', is_approved: true }); setIsSkillModalOpen(true); }} className="btn-primary flex items-center gap-2">
                <Plus size={16} /> Add Skill
              </button>
            </div>
          </div>
          
          <div className="card overflow-hidden max-h-[600px] overflow-y-auto">
            <table className="w-full text-left">
              <thead className="bg-background sticky top-0 z-10">
                <tr>
                  <th className="px-6 py-4 font-medium text-secondaryText">Name</th>
                  <th className="px-6 py-4 font-medium text-secondaryText">Status</th>
                  <th className="px-6 py-4 font-medium text-secondaryText text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-borderDark">
                {skills.map((skill) => (
                  <tr key={skill.id} className="hover:bg-background/50 transition-colors">
                    <td className="px-6 py-4 text-primaryText font-medium">{skill.name}</td>
                    <td className="px-6 py-4">
                      {skill.is_approved ? (
                        <span className="px-2 py-1 bg-green-100 text-green-700 rounded-full text-xs font-medium uppercase tracking-wider">Verified</span>
                      ) : (
                        <span className="px-2 py-1 bg-yellow-100 text-yellow-700 rounded-full text-xs font-medium uppercase tracking-wider">Unverified</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button onClick={() => {
                        setSkillForm({ id: skill.id, name: skill.name, is_approved: skill.is_approved });
                        setIsSkillModalOpen(true);
                      }} className="text-primaryBrand hover:text-blue-700 font-medium text-sm">
                        Edit
                      </button>
                    </td>
                  </tr>
                ))}
                {skills.length === 0 && (
                  <tr>
                    <td colSpan={3} className="px-6 py-8 text-center text-secondaryText">No skills found.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}


      {/* Taxonomy Modal */}
      {isTaxonomyModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6 animate-slide-up">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-xl font-bold text-primaryText">{taxonomyForm.id ? 'Edit' : 'Add'} Taxonomy</h3>
              <button onClick={() => setIsTaxonomyModalOpen(false)} className="text-secondaryText hover:text-primaryText"><X size={24} /></button>
            </div>
            <form onSubmit={handleCreateTaxonomy} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Type</label>
                <select className="input-field" value={taxonomyForm.type} onChange={(e: any) => setTaxonomyForm({...taxonomyForm, type: e.target.value})} disabled={!!taxonomyForm.id}>
                  <option value="section">Section</option>
                  <option value="topic">Topic</option>
                  <option value="subtopic">Sub-Topic</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Name *</label>
                <input type="text" required className="input-field" value={taxonomyForm.name} onChange={e => setTaxonomyForm({...taxonomyForm, name: e.target.value})} />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button type="button" onClick={() => setIsTaxonomyModalOpen(false)} className="px-4 py-2 text-secondaryText font-medium hover:bg-gray-100 rounded-md transition-colors">Cancel</button>
                <button type="submit" className="btn-primary">Save</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Merge Taxonomy Modal */}
      {isMergeTaxonomyModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6 animate-slide-up">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-xl font-bold text-primaryText">Merge Taxonomy Tool</h3>
              <button onClick={() => setIsMergeTaxonomyModalOpen(false)} className="text-secondaryText hover:text-primaryText"><X size={24} /></button>
            </div>
            <form onSubmit={handleMergeTaxonomy} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Type</label>
                <select className="input-field" value={mergeTaxonomyForm.type} onChange={(e: any) => setMergeTaxonomyForm({...mergeTaxonomyForm, type: e.target.value})}>
                  <option value="section">Section</option>
                  <option value="topic">Topic</option>
                  <option value="subtopic">Sub-Topic</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Duplicate Name (Will be DELETED)</label>
                <input type="text" required placeholder="e.g. maths" className="input-field" value={mergeTaxonomyForm.source_name} onChange={e => setMergeTaxonomyForm({...mergeTaxonomyForm, source_name: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Target Name (Will be KEPT/CREATED)</label>
                <input type="text" required placeholder="e.g. Mathematics" className="input-field" value={mergeTaxonomyForm.target_name} onChange={e => setMergeTaxonomyForm({...mergeTaxonomyForm, target_name: e.target.value})} />
              </div>
              <div className="bg-blue-50 p-3 rounded-lg border border-blue-100 mt-2">
                <p className="text-xs text-blue-800">This action will find all questions using the Duplicate Name and update them to use the Target Name.</p>
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button type="button" onClick={() => setIsMergeTaxonomyModalOpen(false)} className="px-4 py-2 text-secondaryText font-medium hover:bg-gray-100 rounded-md transition-colors">Cancel</button>
                <button type="submit" className="btn-primary">Merge</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Staff Modal */}
      {isStaffModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
          <div className="card p-6 w-full max-w-md animate-slide-up">
            <h3 className="text-xl font-bold text-primaryText mb-4">Create New Staff</h3>
            {staffError && <div className="bg-error/10 text-error p-3 rounded-md mb-4 text-sm">{staffError}</div>}
            <form onSubmit={handleCreateStaff} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Full Name</label>
                <input required type="text" className="input-field" value={staffForm.full_name} onChange={e => setStaffForm({...staffForm, full_name: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Email</label>
                <input required type="email" className="input-field" value={staffForm.email} onChange={e => setStaffForm({...staffForm, email: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Password</label>
                <input required type="password" minLength={6} className="input-field" value={staffForm.password} onChange={e => setStaffForm({...staffForm, password: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Role</label>
                <select className="input-field" value={staffForm.role} onChange={e => setStaffForm({...staffForm, role: e.target.value})}>
                  <option value="admin">Admin</option>
                  <option value="manager">Manager</option>
                  <option value="staff">Staff</option>
                </select>
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setIsStaffModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText transition-colors">Cancel</button>
                <button type="submit" className="btn-primary">Create Staff</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Goal Modal */}
      {isGoalModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
          <div className="card p-6 w-full max-w-sm animate-slide-up">
            <h3 className="text-xl font-bold text-primaryText mb-4">Add New Goal</h3>
            {goalError && <div className="bg-error/10 text-error p-3 rounded-md mb-4 text-sm">{goalError}</div>}
            <form onSubmit={handleCreateGoal} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Goal / Profession Name</label>
                <input required type="text" placeholder="e.g. Software Engineer" className="input-field" value={goalName} onChange={e => setGoalName(e.target.value)} />
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setIsGoalModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText transition-colors">Cancel</button>
                <button type="submit" className="btn-primary">Add Goal</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Test Category Modal */}
      {isTestCategoryModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
          <div className="card p-6 w-full max-w-sm animate-slide-up">
            <h3 className="text-xl font-bold text-primaryText mb-4">Add New Category</h3>
            {testCategoryError && <div className="bg-error/10 text-error p-3 rounded-md mb-4 text-sm">{testCategoryError}</div>}
            <form onSubmit={handleCreateTestCategory} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Category Name</label>
                <input required type="text" placeholder="e.g. Coding, Aptitude" className="input-field" value={testCategoryName} onChange={e => setTestCategoryName(e.target.value)} />
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setIsTestCategoryModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText transition-colors">Cancel</button>
                <button type="submit" className="btn-primary">Add Category</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Source Modal */}
      {isSourceModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
          <div className="card p-6 w-full max-w-sm animate-slide-up">
            <h3 className="text-xl font-bold text-primaryText mb-4">Add New Source</h3>
            {sourceError && <div className="bg-error/10 text-error p-3 rounded-md mb-4 text-sm">{sourceError}</div>}
            <form onSubmit={handleCreateSource} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Acquisition Source Name</label>
                <input required type="text" placeholder="e.g. Social Media" className="input-field" value={sourceName} onChange={e => setSourceName(e.target.value)} />
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setIsSourceModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText transition-colors">Cancel</button>
                <button type="submit" className="btn-primary">Add Source</button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Skill Modal */}
      {isSkillModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
          <div className="card p-6 w-full max-w-sm animate-slide-up">
            <h3 className="text-xl font-bold text-primaryText mb-4">{skillForm.id ? 'Edit Skill' : 'Add New Skill'}</h3>
            {skillError && <div className="bg-error/10 text-error p-3 rounded-md mb-4 text-sm">{skillError}</div>}
            <form onSubmit={handleSaveSkill} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Skill Name</label>
                <input required type="text" placeholder="e.g. React" className="input-field" value={skillForm.name} onChange={e => setSkillForm({...skillForm, name: e.target.value})} />
              </div>
              <div className="flex items-center gap-2">
                <input type="checkbox" id="is_approved" checked={skillForm.is_approved} onChange={e => setSkillForm({...skillForm, is_approved: e.target.checked})} className="rounded text-primaryBrand focus:ring-primaryBrand" />
                <label htmlFor="is_approved" className="text-sm font-medium text-primaryText">Verified (Standardized)</label>
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setIsSkillModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText transition-colors">Cancel</button>
                <button type="submit" className="btn-primary">{skillForm.id ? 'Update' : 'Save'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Merge Skill Modal */}
      {isMergeModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
          <div className="card p-6 w-full max-w-md animate-slide-up overflow-visible">
            <h3 className="text-xl font-bold text-primaryText mb-2">Merge Duplicate Skills</h3>
            <p className="text-sm text-secondaryText mb-4">Combine a duplicate/unverified skill into a target skill. The duplicate will be permanently deleted and all references will be updated.</p>
            
            {mergeError && <div className="bg-error/10 text-error p-3 rounded-md mb-4 text-sm">{mergeError}</div>}
            
            <form onSubmit={handleMergeSkills} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Source Skill (To be deleted)</label>
                <select required className="input-field bg-white" value={mergeForm.source_skill_id} onChange={e => setMergeForm({...mergeForm, source_skill_id: e.target.value})}>
                  <option value="">Select a skill to delete...</option>
                  {skills.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Target Skill (To keep)</label>
                <select required className="input-field bg-white" value={mergeForm.target_skill_id} onChange={e => setMergeForm({...mergeForm, target_skill_id: e.target.value})}>
                  <option value="">Select a skill to keep...</option>
                  {skills.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setIsMergeModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText transition-colors">Cancel</button>
                <button type="submit" className="px-6 py-2 bg-error text-white font-medium rounded-xl hover:bg-red-600 transition-colors">Merge & Delete</button>
              </div>
            </form>
          </div>
        </div>
      )}
      {activeTab === 'home_banners' && (
        <Banners isSettingsTab={true} />
      )}
      
    </div>
  );
};

export default Settings;
