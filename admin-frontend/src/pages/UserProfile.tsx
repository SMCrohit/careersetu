import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { 
  ArrowLeft, User, Phone, Mail, MapPin, Target, Briefcase, 
  GraduationCap, Stethoscope, Download, Eye, Link, 
  Globe, CheckCircle, FileText, Calendar, Clock, Star,
  Check, X, FileCheck, Award
} from 'lucide-react';
import { useToast } from '../context/ToastContext';

const UserProfile = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');
  const [showSuspendModal, setShowSuspendModal] = useState(false);
  const [isSuspending, setIsSuspending] = useState(false);

  useEffect(() => {
    fetchUserDetails();
  }, [id]);

  const fetchUserDetails = async () => {
    try {
      const res = await api.get(`/users/${id}/details`);
      setData(res.data);
    } catch (error) {
      showToast("Failed to load user profile", "error");
      navigate('/users');
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadResume = () => {
    const user = data?.user;
    if (!user?.resume_data?.data) return;
    try {
      const byteCharacters = atob(user.resume_data.data);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: 'application/pdf' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = user.resume_data.filename || 'resume.pdf';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (e) {
      showToast("Error downloading resume", "error");
    }
  };

  const handleViewResume = () => {
    const user = data?.user;
    if (!user?.resume_data?.data) return;
    try {
      const byteCharacters = atob(user.resume_data.data);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: 'application/pdf' });
      const url = URL.createObjectURL(blob);
      window.open(url, '_blank');
    } catch (e) {
      showToast("Error opening resume", "error");
    }
  };

  const handleSuspendUser = async () => {
    setIsSuspending(true);
    try {
      const res = await api.post(`/users/${id}/suspend`);
      showToast(res.data.message, "success");
      // Update local state instead of full refetch to be fast
      setData({
        ...data,
        user: {
          ...data.user,
          is_active: res.data.is_active
        }
      });
      setShowSuspendModal(false);
    } catch (e) {
      showToast("Failed to change user status", "error");
    } finally {
      setIsSuspending(false);
    }
  };

  if (loading) return <div className="p-8 text-secondaryText flex justify-center mt-10">Loading profile...</div>;
  if (!data || !data.user) return <div className="p-8 text-error">User not found.</div>;

  const { user, job_applications, test_attempts, professional_appointments, resume_sessions } = data;

  // Group test attempts by test ID
  const groupedTestAttempts = Object.values((test_attempts || []).reduce((acc: any, att: any) => {
    const tId = att.test_id;
    if (!acc[tId]) {
      acc[tId] = { test: att.test, attempts_count: 0, first_score: att.total_score, latest_attempt: att };
    }
    acc[tId].attempts_count += 1;
    if (new Date(att.completed_at) > new Date(acc[tId].latest_attempt.completed_at)) {
      acc[tId].latest_attempt = att;
    }
    return acc;
  }, {}));

  const getStatusColor = (status: string) => {
    status = status.toLowerCase();
    if (['applied', 'in_progress', 'scheduled'].includes(status)) return 'bg-yellow-100 text-yellow-800 border-yellow-200';
    if (['accepted', 'completed', 'hired', 'passed'].includes(status)) return 'bg-green-100 text-green-800 border-green-200';
    if (['rejected', 'cancelled', 'failed'].includes(status)) return 'bg-red-100 text-red-800 border-red-200';
    return 'bg-gray-100 text-gray-800 border-gray-200';
  };

  // Calculations for profile score logic
  const score = user.profile_completion_score || 0;
  const scoreColor = score >= 80 ? 'bg-green-500' : score >= 50 ? 'bg-orange-500' : 'bg-red-500';

  return (
    <div className="p-8 max-w-7xl mx-auto min-h-screen pb-20">
      <div className="flex items-center gap-4 mb-8 animate-slide-up">
        <button 
          onClick={() => navigate('/users')}
          className="p-2 hover:bg-gray-100 rounded-full transition-colors"
        >
          <ArrowLeft size={24} className="text-secondaryText" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Student Profile Dashboard</h1>
          <p className="text-secondaryText text-sm">Detailed overview, analytics, and activity history</p>
        </div>
      </div>

      {/* Top Analytics */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8 animate-slide-up" style={{animationDelay: '0.1s'}}>
        <div className="card p-5 bg-white border border-border rounded-xl flex items-center gap-4 shadow-sm hover:shadow-md transition-shadow">
          <div className="w-12 h-12 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
            <Briefcase size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-secondaryText">Jobs Applied</p>
            <p className="text-2xl font-bold text-primaryText">{job_applications?.length || 0}</p>
            {(job_applications?.length || 0) > 0 && <p className="text-xs text-green-600 mt-1 flex items-center gap-1"><CheckCircle size={12}/> Active Candidate</p>}
          </div>
        </div>
        <div className="card p-5 bg-white border border-border rounded-xl flex items-center gap-4 shadow-sm hover:shadow-md transition-shadow">
          <div className="w-12 h-12 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center shrink-0">
            <GraduationCap size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-secondaryText">Tests Taken</p>
            <p className="text-2xl font-bold text-primaryText">{groupedTestAttempts.length}</p>
            {groupedTestAttempts.length > 0 && <p className="text-xs text-purple-600 mt-1 flex items-center gap-1"><Star size={12}/> Assessed</p>}
          </div>
        </div>
        <div className="card p-5 bg-white border border-border rounded-xl flex items-center gap-4 shadow-sm hover:shadow-md transition-shadow">
          <div className="w-12 h-12 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
            <Stethoscope size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-secondaryText">Appointments</p>
            <p className="text-2xl font-bold text-primaryText">{professional_appointments?.length || 0}</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        
        {/* Left Sidebar Profile Card */}
        <div className="col-span-1 space-y-6">
          <div className="card p-6 bg-white border border-border shadow-sm rounded-xl animate-slide-up" style={{animationDelay: '0.2s'}}>
            
            {/* Status & Completion */}
            <div className="flex justify-between items-center mb-6">
              <span className={`px-2.5 py-1 text-xs font-bold rounded-full ${user.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                {user.is_active ? 'ACTIVE' : 'SUSPENDED'}
              </span>
              <div className="group relative cursor-pointer">
                <div className="text-xs font-bold text-gray-500">{score}% Complete</div>
                {/* Tooltip Breakdown */}
                <div className="absolute left-0 lg:-left-48 lg:right-auto top-full mt-2 w-48 p-3 bg-gray-900 text-white rounded-lg shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-50 text-xs space-y-2 pointer-events-none">
                  <p className="font-bold border-b border-gray-700 pb-1 mb-2">Score Breakdown</p>
                  <div className="flex justify-between"><span>Email (10%)</span> {user.email ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                  <div className="flex justify-between"><span>Phone (10%)</span> {user.mobile_number ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                  <div className="flex justify-between"><span>Image (10%)</span> {user.profile_image_url ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                  <div className="flex justify-between"><span>Resume (15%)</span> {user.resume_data ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                  <div className="flex justify-between"><span>Education (15%)</span> {user.education_history?.length > 0 ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                  <div className="flex justify-between"><span>Experience (15%)</span> {user.work_experience?.length > 0 ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                  <div className="flex justify-between"><span>Skills (10%)</span> {user.skills?.length > 0 ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                  <div className="flex justify-between"><span>Summary (5%)</span> {user.summary ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                  <div className="flex justify-between"><span>Links (10%)</span> {(user.linkedin_url || user.github_url) ? <Check size={14} className="text-green-400"/> : <X size={14} className="text-red-400"/>}</div>
                </div>
              </div>
            </div>
            <div className="w-full bg-gray-200 h-1.5 rounded-full mb-6 overflow-hidden">
              <div className={`h-full ${scoreColor} transition-all duration-1000`} style={{width: `${score}%`}}></div>
            </div>

            <div className="flex flex-col items-center text-center mb-6">
              {user.profile_image_url ? (
                <img src={user.profile_image_url} alt={user.full_name} className="w-28 h-28 rounded-full object-cover mb-4 shadow-md border-4 border-white" />
              ) : (
                <div className="w-28 h-28 bg-primaryBrand/10 text-primaryBrand rounded-full flex items-center justify-center mb-4 shadow-sm border-4 border-white">
                  <User size={48} />
                </div>
              )}
              <h2 className="text-xl font-bold text-primaryText">{user.full_name || 'N/A'}</h2>
              <p className="text-primaryBrand font-medium text-sm mt-1">{user.goal?.name || 'No career goal set'}</p>
              
              <div className="flex gap-3 mt-4">
                {user.linkedin_url && <a href={user.linkedin_url} target="_blank" rel="noreferrer" className="p-2 bg-gray-100 text-gray-600 rounded-full hover:bg-blue-100 hover:text-blue-600 transition"><Link size={18}/></a>}
                {user.github_url && <a href={user.github_url} target="_blank" rel="noreferrer" className="p-2 bg-gray-100 text-gray-600 rounded-full hover:bg-gray-200 hover:text-gray-900 transition"><Link size={18}/></a>}
                {user.portfolio_url && <a href={user.portfolio_url} target="_blank" rel="noreferrer" className="p-2 bg-gray-100 text-gray-600 rounded-full hover:bg-green-100 hover:text-green-600 transition"><Globe size={18}/></a>}
              </div>
            </div>
            
            <div className="space-y-4 pt-4 border-t border-gray-100">
              {user.years_of_experience !== null && user.years_of_experience !== undefined && (
                <div className="flex items-center justify-between">
                  <span className="text-xs text-secondaryText">Experience</span>
                  <span className="text-sm font-semibold text-primaryText">{user.years_of_experience} yrs</span>
                </div>
              )}
              {user.expected_salary && (
                <div className="flex items-center justify-between">
                  <span className="text-xs text-secondaryText">Expected CTC</span>
                  <span className="text-sm font-semibold text-primaryText">₹{user.expected_salary} LPA</span>
                </div>
              )}
            </div>

            <div className="space-y-3 pt-4 border-t border-gray-100 mt-4">
              <div className="flex items-start gap-3 text-sm">
                <Phone size={16} className="text-gray-400 mt-0.5 shrink-0" />
                <span className="font-medium text-gray-700 break-all">{user.mobile_number}</span>
              </div>
              <div className="flex items-start gap-3 text-sm">
                <Mail size={16} className="text-gray-400 mt-0.5 shrink-0" />
                <span className="font-medium text-gray-700 break-all">{user.email || 'Not provided'}</span>
              </div>
              <div className="flex items-start gap-3 text-sm">
                <MapPin size={16} className="text-gray-400 mt-0.5 shrink-0" />
                <span className="font-medium text-gray-700">{user.city || 'Not provided'}</span>
              </div>
              <div className="flex items-start gap-3 text-sm">
                <Calendar size={16} className="text-gray-400 mt-0.5 shrink-0" />
                <span className="font-medium text-gray-700">Joined {new Date(user.created_datetime).toLocaleDateString()}</span>
              </div>
              {user.acquisition_source && (
                <div className="flex items-start gap-3 text-sm">
                  <Target size={16} className="text-gray-400 mt-0.5 shrink-0" />
                  <span className="font-medium text-gray-700">Source: {user.acquisition_source}</span>
                </div>
              )}
            </div>

            <div className="pt-6 border-t border-gray-100 mt-6 space-y-2">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">Admin Actions</p>
              <button onClick={() => showToast("Feature is coming soon.", "info")} className="w-full py-2 bg-gray-100 text-gray-700 rounded-lg text-sm font-semibold hover:bg-gray-200 transition">Edit Profile Data</button>
              <button onClick={() => setShowSuspendModal(true)} className={`w-full py-2 rounded-lg text-sm font-semibold transition ${user.is_active ? 'bg-red-50 text-red-600 hover:bg-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100'}`}>
                {user.is_active ? 'Suspend User' : 'Activate User'}
              </button>
            </div>
          </div>
        </div>

        {/* Right Content Area */}
        <div className="col-span-1 lg:col-span-3">
          <div className="card bg-white border border-border shadow-sm rounded-xl overflow-hidden animate-slide-up" style={{animationDelay: '0.3s'}}>
            
            <div className="flex border-b border-border overflow-x-auto hide-scrollbar">
              <button onClick={() => setActiveTab('overview')} className={`px-6 py-4 text-sm font-semibold whitespace-nowrap transition-colors ${activeTab === 'overview' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-blue-50/30' : 'text-secondaryText hover:text-primaryText hover:bg-gray-50'}`}>Profile Overview</button>
              <button onClick={() => setActiveTab('resume')} className={`px-6 py-4 text-sm font-semibold whitespace-nowrap transition-colors flex items-center gap-2 ${activeTab === 'resume' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-blue-50/30' : 'text-secondaryText hover:text-primaryText hover:bg-gray-50'}`}>Resumes & Docs</button>
              <button onClick={() => setActiveTab('jobs')} className={`px-6 py-4 text-sm font-semibold whitespace-nowrap transition-colors flex items-center gap-2 ${activeTab === 'jobs' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-blue-50/30' : 'text-secondaryText hover:text-primaryText hover:bg-gray-50'}`}>
                Job Applications <span className="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full text-xs">{job_applications?.length || 0}</span>
              </button>
              <button onClick={() => setActiveTab('tests')} className={`px-6 py-4 text-sm font-semibold whitespace-nowrap transition-colors flex items-center gap-2 ${activeTab === 'tests' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-blue-50/30' : 'text-secondaryText hover:text-primaryText hover:bg-gray-50'}`}>
                Test Attempts <span className="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full text-xs">{groupedTestAttempts.length}</span>
              </button>
              <button onClick={() => setActiveTab('doctors')} className={`px-6 py-4 text-sm font-semibold whitespace-nowrap transition-colors flex items-center gap-2 ${activeTab === 'doctors' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-blue-50/30' : 'text-secondaryText hover:text-primaryText hover:bg-gray-50'}`}>
                Appointments <span className="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full text-xs">{professional_appointments?.length || 0}</span>
              </button>
            </div>
            
            <div className="p-6 md:p-8 overflow-y-auto" style={{minHeight: '500px'}}>
              
              {/* PROFILE OVERVIEW TAB */}
              {activeTab === 'overview' && (
                <div className="space-y-10 animate-fade-in">
                  
                  {/* Summary section */}
                  {user.summary ? (
                    <div>
                      <h3 className="text-lg font-bold text-gray-900 mb-3 flex items-center gap-2"><User size={20} className="text-primaryBrand"/> About Me</h3>
                      <p className="text-gray-600 leading-relaxed bg-gray-50 p-4 rounded-xl border border-gray-100">{user.summary}</p>
                    </div>
                  ) : (
                    <div className="bg-yellow-50 text-yellow-800 p-4 rounded-xl border border-yellow-100 text-sm">No bio or summary provided yet.</div>
                  )}

                  {/* Skills Section */}
                  {user.skills && user.skills.length > 0 && (
                    <div>
                      <h3 className="text-lg font-bold text-gray-900 mb-3 flex items-center gap-2"><Target size={20} className="text-primaryBrand"/> Top Skills</h3>
                      <div className="flex flex-wrap gap-2">
                        {user.skills.map((skill: string, i: number) => (
                          <span key={i} className="px-3 py-1.5 bg-blue-50 text-blue-700 rounded-lg text-sm font-medium border border-blue-100">{skill}</span>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Experience Timeline */}
                  {user.work_experience && user.work_experience.length > 0 && (
                    <div>
                      <h3 className="text-lg font-bold text-gray-900 mb-5 flex items-center gap-2"><Briefcase size={20} className="text-primaryBrand"/> Work Experience</h3>
                      <div className="relative border-l-2 border-gray-200 ml-3 space-y-8">
                        {user.work_experience.map((exp: any, i: number) => (
                          <div key={i} className="pl-6 relative">
                            <div className="absolute w-4 h-4 bg-primaryBrand rounded-full -left-[9px] top-1 border-4 border-white shadow-sm"></div>
                            <h4 className="text-base font-bold text-gray-900">{exp.title}</h4>
                            <p className="text-sm font-semibold text-primaryBrand mb-1">{exp.company}</p>
                            <p className="text-xs text-gray-500 mb-2 flex items-center gap-1"><Calendar size={12}/> {exp.duration || 'Duration not specified'}</p>
                            {exp.description && <p className="text-sm text-gray-600">{exp.description}</p>}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Education Timeline */}
                  {user.education_history && user.education_history.length > 0 && (
                    <div>
                      <h3 className="text-lg font-bold text-gray-900 mb-5 flex items-center gap-2"><GraduationCap size={20} className="text-primaryBrand"/> Education</h3>
                      <div className="relative border-l-2 border-gray-200 ml-3 space-y-8">
                        {user.education_history.map((edu: any, i: number) => (
                          <div key={i} className="pl-6 relative">
                            <div className="absolute w-4 h-4 bg-gray-400 rounded-full -left-[9px] top-1 border-4 border-white shadow-sm"></div>
                            <h4 className="text-base font-bold text-gray-900">{edu.degree}</h4>
                            <p className="text-sm font-medium text-gray-700 mb-1">{edu.institution}</p>
                            <p className="text-xs text-gray-500 flex items-center gap-1"><Calendar size={12}/> {edu.year || 'Year not specified'}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                </div>
              )}

              {/* RESUMES & DOCS TAB */}
              {activeTab === 'resume' && (
                <div className="space-y-8 animate-fade-in">
                  
                  {/* AI Resume Section */}
                  <div>
                    <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2"><FileCheck size={20} className="text-purple-600"/> AI Generated Resumes</h3>
                    {resume_sessions && resume_sessions.length > 0 ? (
                      <div className="grid gap-4">
                        {resume_sessions.map((sess: any) => (
                          <div key={sess.id} className="border border-purple-100 bg-purple-50/30 rounded-xl p-5">
                            <div className="flex justify-between items-start mb-4">
                              <div>
                                <span className={`px-2 py-1 text-xs font-bold rounded uppercase ${sess.status === 'completed' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}>{sess.status}</span>
                                <p className="text-sm text-gray-500 mt-2">Started on {new Date(sess.created_datetime).toLocaleDateString()}</p>
                              </div>
                              <button className="px-4 py-2 bg-purple-600 text-white rounded-lg text-sm font-semibold hover:bg-purple-700 transition shadow-sm">View AI Resume</button>
                            </div>
                            {sess.extracted_data && Object.keys(sess.extracted_data).length > 0 && (
                              <div className="bg-white p-4 rounded-lg border border-purple-100 text-sm text-gray-700">
                                <p className="font-semibold mb-2">AI Extraction Preview:</p>
                                <pre className="whitespace-pre-wrap font-mono text-xs overflow-hidden max-h-32 text-gray-500">{JSON.stringify(sess.extracted_data, null, 2)}</pre>
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="bg-gray-50 p-6 rounded-xl border border-gray-200 text-center">
                        <p className="text-gray-500 text-sm">The user has not built any resumes using the AI Builder.</p>
                      </div>
                    )}
                  </div>

                  {/* Uploaded PDF Section */}
                  <div>
                    <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2"><FileText size={20} className="text-blue-600"/> Original Uploaded Document</h3>
                    {!user.resume_data || Object.keys(user.resume_data).length === 0 ? (
                      <div className="bg-gray-50 p-6 rounded-xl border border-gray-200 text-center">
                        <p className="text-gray-500 text-sm">No original resume PDF has been uploaded.</p>
                      </div>
                    ) : (
                      <div className="border border-blue-100 bg-blue-50/30 rounded-xl p-6">
                        <div className="flex items-center gap-4 mb-6">
                          <div className="w-14 h-14 bg-blue-100 text-blue-600 rounded-xl flex items-center justify-center shrink-0 shadow-sm">
                            <Briefcase size={28} />
                          </div>
                          <div className="flex-1">
                            <h3 className="text-lg font-bold text-gray-900">{user.resume_data.filename || 'Uploaded_Resume.pdf'}</h3>
                            <p className="text-sm text-gray-500">Stored in raw format.</p>
                          </div>
                          <div className="flex items-center gap-3">
                            <button onClick={handleViewResume} className="p-2.5 bg-white border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50 hover:text-blue-600 transition shadow-sm" title="Preview"><Eye size={20} /></button>
                            <button onClick={handleDownloadResume} className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition shadow-sm"><Download size={16} /> Download</button>
                          </div>
                        </div>
                        <div className="bg-white p-4 rounded-lg border border-blue-100 text-sm text-gray-700">
                          <p className="font-semibold mb-2">Raw Parsed JSON (Debug View):</p>
                          <pre className="whitespace-pre-wrap font-mono text-xs overflow-y-auto max-h-40 text-gray-500">{JSON.stringify(user.resume_data, null, 2)}</pre>
                        </div>
                      </div>
                    )}
                  </div>

                </div>
              )}

              {/* JOB APPLICATIONS TAB */}
              {activeTab === 'jobs' && (
                <div className="space-y-4 animate-fade-in">
                  {!job_applications || job_applications.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-12 text-gray-400">
                      <Briefcase size={48} className="mb-4 opacity-20" />
                      <p>No job applications yet.</p>
                    </div>
                  ) : (
                    job_applications.map((app: any) => (
                      <div key={app.id} className="p-5 border border-border rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4 hover:shadow-md transition bg-white group">
                        <div className="flex-1">
                          <div className="flex items-center gap-3 mb-1">
                            <h4 className="text-lg font-bold text-primaryText group-hover:text-primaryBrand transition">{app.job?.title || 'Unknown Job'}</h4>
                            <span className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-wide border ${getStatusColor(app.status)}`}>{app.status}</span>
                          </div>
                          <p className="text-sm text-secondaryText flex items-center gap-2">
                            <span className="font-medium text-gray-700">{app.job?.company_name || 'Unknown Company'}</span> 
                            <span className="w-1 h-1 bg-gray-300 rounded-full"></span> 
                            {app.job?.location?.city || 'Remote'}
                          </p>
                        </div>
                        <div className="flex flex-col items-end gap-2 shrink-0">
                          {app.ai_match_score !== null && app.ai_match_score !== undefined && (
                            <div className="flex items-center gap-1.5 bg-blue-50 px-3 py-1.5 rounded-lg border border-blue-100">
                              <Award size={16} className="text-blue-600"/>
                              <span className="text-sm font-bold text-blue-700">{app.ai_match_score}% AI Match</span>
                            </div>
                          )}
                          <p className="text-xs text-gray-400">Applied {new Date(app.created_datetime).toLocaleDateString()}</p>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* TESTS TAB */}
              {activeTab === 'tests' && (
                <div className="space-y-5 animate-fade-in">
                  {groupedTestAttempts.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-12 text-gray-400">
                      <GraduationCap size={48} className="mb-4 opacity-20" />
                      <p>No test attempts yet.</p>
                    </div>
                  ) : (
                    groupedTestAttempts.map((group: any) => {
                      const latest = group.latest_attempt;
                      const dateStr = latest.completed_at || latest.created_datetime;
                      const formattedDate = dateStr ? new Date(dateStr).toLocaleDateString() : 'Unknown Date';
                      
                      return (
                        <div key={group.test.id} className="border border-border rounded-xl bg-white overflow-hidden hover:shadow-md transition">
                          <div className="p-5 flex flex-col md:flex-row justify-between md:items-center gap-4">
                            <div>
                              <div className="flex items-center gap-3 mb-1">
                                <h4 className="text-lg font-bold text-primaryText">{group.test.title || 'Unknown Test'}</h4>
                                {group.attempts_count > 1 && (
                                  <span className="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full font-bold">{group.attempts_count} ATTEMPTS</span>
                                )}
                              </div>
                              <p className="text-sm text-secondaryText flex items-center gap-2">
                                <span className="font-medium text-gray-700">{group.test.difficulty || 'Standard'}</span>
                                <span className="w-1 h-1 bg-gray-300 rounded-full"></span> 
                                Last Attempt: {formattedDate}
                              </p>
                            </div>
                            <div className="flex items-center gap-4 shrink-0 bg-gray-50 px-4 py-2 rounded-xl border border-gray-100">
                              <div className="text-center">
                                <p className="text-xs text-gray-500 font-medium uppercase mb-0.5">Time</p>
                                <p className="text-sm font-bold text-gray-800 flex items-center justify-center gap-1"><Clock size={14} className="text-gray-400"/> {Math.floor(latest.time_taken_seconds / 60)}m</p>
                              </div>
                              <div className="w-px h-8 bg-gray-200"></div>
                              <div className="text-center">
                                <p className="text-xs text-gray-500 font-medium uppercase mb-0.5">Score</p>
                                <p className="text-lg font-black text-primaryBrand">{latest.total_score}%</p>
                              </div>
                            </div>
                          </div>
                          
                          {/* AI Report Section */}
                          {latest.ai_report && (
                            <div className="bg-purple-50/50 p-4 border-t border-purple-100 text-sm text-gray-700">
                              <p className="font-bold text-purple-700 flex items-center gap-1.5 mb-2"><Star size={16}/> AI Performance Insights</p>
                              <div className="pl-5 border-l-2 border-purple-200">
                                {typeof latest.ai_report === 'string' ? latest.ai_report : (
                                  <pre className="whitespace-pre-wrap font-mono text-xs">{JSON.stringify(latest.ai_report, null, 2)}</pre>
                                )}
                              </div>
                            </div>
                          )}
                        </div>
                      )
                    })
                  )}
                </div>
              )}

              {/* APPOINTMENTS TAB */}
              {activeTab === 'doctors' && (
                <div className="space-y-4 animate-fade-in">
                  {!professional_appointments || professional_appointments.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-12 text-gray-400">
                      <Stethoscope size={48} className="mb-4 opacity-20" />
                      <p>No professional appointments booked.</p>
                    </div>
                  ) : (
                    professional_appointments.map((apt: any) => (
                      <div key={apt.id} className="p-5 border border-border rounded-xl flex justify-between items-center bg-white hover:shadow-md transition">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center shadow-sm">
                            <Stethoscope size={24}/>
                          </div>
                          <div>
                            <h4 className="text-lg font-bold text-primaryText">{apt.doctor?.name || 'Unknown Professional'}</h4>
                            <p className="text-sm text-secondaryText flex items-center gap-1"><Calendar size={14}/> {apt.appointment_date} at <Clock size={14} className="ml-2"/> {apt.appointment_time}</p>
                          </div>
                        </div>
                        <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide border ${getStatusColor(apt.status)}`}>
                          {apt.status}
                        </span>
                      </div>
                    ))
                  )}
                </div>
              )}

            </div>
          </div>
        </div>

      </div>
      
      {/* Custom Suspend Modal */}
      {showSuspendModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 animate-fade-in">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden animate-slide-up">
            <div className="p-6">
              <h3 className="text-xl font-bold text-gray-900 mb-2">
                {user.is_active ? 'Suspend User Account' : 'Activate User Account'}
              </h3>
              <p className="text-sm text-gray-500 mb-6">
                {user.is_active 
                  ? "Are you sure you want to suspend this user? They will immediately lose access to the platform, and their active job applications will be hidden." 
                  : "Are you sure you want to reactivate this user? They will instantly regain access to all platform features."}
              </p>
              <div className="flex gap-3 justify-end">
                <button 
                  onClick={() => setShowSuspendModal(false)}
                  disabled={isSuspending}
                  className="px-4 py-2 text-sm font-semibold text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition"
                >
                  Cancel
                </button>
                <button 
                  onClick={handleSuspendUser}
                  disabled={isSuspending}
                  className={`px-4 py-2 text-sm font-semibold text-white rounded-lg transition flex items-center gap-2 ${
                    user.is_active ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'
                  } ${isSuspending ? 'opacity-70 cursor-not-allowed' : ''}`}
                >
                  {isSuspending ? 'Processing...' : (user.is_active ? 'Yes, Suspend' : 'Yes, Activate')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserProfile;
