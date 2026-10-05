import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { ArrowLeft, User, Phone, Mail, MapPin, Target, Briefcase, GraduationCap, Stethoscope, Download, Eye } from 'lucide-react';
import { useToast } from '../context/ToastContext';

const UserProfile = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('resume');

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

  if (loading) return <div className="p-8 text-secondaryText">Loading profile...</div>;
  if (!data || !data.user) return <div className="p-8 text-error">User not found.</div>;

  const { user, job_applications, test_attempts, professional_appointments } = data;

  // Group test attempts by test ID
  const groupedTestAttempts = Object.values((test_attempts || []).reduce((acc: any, att: any) => {
    const testId = att.test?.id;
    if (!testId) return acc;
    if (!acc[testId]) {
      acc[testId] = {
        test: att.test,
        attempts_count: 0,
        latest_attempt: att,
        first_attempt: att,
        first_score: att.total_score ?? att.score ?? 0
      };
    }
    acc[testId].attempts_count += 1;
    
    const newDate = new Date(att.completed_at || att.created_datetime || 0);
    
    // Find latest attempt for AI report and date
    const currentLatestDate = new Date(acc[testId].latest_attempt.completed_at || acc[testId].latest_attempt.created_datetime || 0);
    if (newDate > currentLatestDate) {
      acc[testId].latest_attempt = att;
    }
    
    // Find first attempt for the score
    const currentFirstDate = new Date(acc[testId].first_attempt.completed_at || acc[testId].first_attempt.created_datetime || 9999999999999);
    if (newDate < currentFirstDate) {
      acc[testId].first_attempt = att;
      acc[testId].first_score = att.total_score ?? att.score ?? 0;
    }
    
    return acc;
  }, {}));

  const handleViewResume = () => {
    if (!user.resume_data?.data) return;
    try {
      const byteCharacters = atob(user.resume_data.data);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: 'application/pdf' });
      const fileURL = URL.createObjectURL(blob);
      window.open(fileURL, '_blank');
    } catch (error) {
      showToast("Failed to view resume", "error");
    }
  };

  const handleDownloadResume = () => {
    if (!user.resume_data?.data) return;
    try {
      const byteCharacters = atob(user.resume_data.data);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: 'application/pdf' });
      const fileURL = URL.createObjectURL(blob);
      
      const a = document.createElement('a');
      a.href = fileURL;
      a.download = user.resume_data.filename || 'resume.pdf';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(fileURL);
    } catch (error) {
      showToast("Failed to download resume", "error");
    }
  };

  const getStatusColor = (status: string) => {
    const s = (status || '').toLowerCase();
    if (s.includes('pending') || s.includes('review') || s.includes('progress') || s.includes('wait')) {
      return 'bg-orange-100 text-orange-700 border-orange-200';
    }
    if (s.includes('accept') || s.includes('confirm') || s.includes('success') || s.includes('sent_to')) {
      return 'bg-green-100 text-green-700 border-green-200';
    }
    if (s.includes('reject') || s.includes('cancel') || s.includes('fail')) {
      return 'bg-red-100 text-red-700 border-red-200';
    }
    return 'bg-blue-100 text-blue-700 border-blue-200';
  };

  return (
    <div className="animate-fade-in max-w-6xl mx-auto pb-12">
      <div className="flex items-center gap-4 mb-8">
        <button onClick={() => navigate('/users')} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <ArrowLeft size={24} className="text-secondaryText" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Student Profile</h1>
          <p className="text-secondaryText">Detailed overview and activity history</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {/* Profile Card */}
        <div className="card p-6 col-span-1 bg-white">
          <div className="flex flex-col items-center text-center mb-6">
            <div className="w-24 h-24 bg-primaryBrand/10 text-primaryBrand rounded-full flex items-center justify-center mb-4">
              <User size={40} />
            </div>
            <h2 className="text-xl font-bold text-primaryText">{user.full_name || 'N/A'}</h2>
            <p className="text-secondaryText bg-gray-100 px-3 py-1 rounded-full text-sm mt-2">{user.goal || 'No goal set'}</p>
          </div>
          
          <div className="space-y-4">
            <div className="flex items-center gap-3 text-sm">
              <div className="p-2 bg-gray-50 rounded-md text-secondaryText"><Phone size={16} /></div>
              <div>
                <p className="text-xs text-secondaryText">Mobile Number</p>
                <p className="font-medium text-primaryText">{user.mobile_number}</p>
              </div>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <div className="p-2 bg-gray-50 rounded-md text-secondaryText"><Mail size={16} /></div>
              <div>
                <p className="text-xs text-secondaryText">Email Address</p>
                <p className="font-medium text-primaryText">{user.email || 'Not provided'}</p>
              </div>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <div className="p-2 bg-gray-50 rounded-md text-secondaryText"><MapPin size={16} /></div>
              <div>
                <p className="text-xs text-secondaryText">City / Location</p>
                <p className="font-medium text-primaryText">{user.city || 'Not provided'}</p>
              </div>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <div className="p-2 bg-gray-50 rounded-md text-secondaryText"><Target size={16} /></div>
              <div>
                <p className="text-xs text-secondaryText">Joined Platform</p>
                <p className="font-medium text-primaryText">{new Date(user.created_datetime).toLocaleDateString()}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Stats & Tabs Area */}
        <div className="col-span-1 md:col-span-2 flex flex-col">
          <div className="grid grid-cols-3 gap-4 mb-6">
            <div className="card p-4 flex items-center gap-4 bg-white">
              <div className="p-3 bg-blue-50 text-blue-600 rounded-lg"><Briefcase size={24} /></div>
              <div>
                <p className="text-2xl font-bold text-primaryText">{job_applications.length}</p>
                <p className="text-xs text-secondaryText uppercase tracking-wider font-semibold">Jobs Applied</p>
              </div>
            </div>
            <div className="card p-4 flex items-center gap-4 bg-white">
              <div className="p-3 bg-purple-50 text-purple-600 rounded-lg"><GraduationCap size={24} /></div>
              <div>
                <p className="text-2xl font-bold text-primaryText">{test_attempts.length}</p>
                <p className="text-xs text-secondaryText uppercase tracking-wider font-semibold">Tests Taken</p>
              </div>
            </div>
            <div className="card p-4 flex items-center gap-4 bg-white">
              <div className="p-3 bg-teal-50 text-teal-600 rounded-lg"><Stethoscope size={24} /></div>
              <div>
                <p className="text-2xl font-bold text-primaryText">{professional_appointments.length}</p>
                <p className="text-xs text-secondaryText uppercase tracking-wider font-semibold">Appointments</p>
              </div>
            </div>
          </div>

          <div className="card flex-1 bg-white overflow-hidden flex flex-col">
            <div className="flex border-b border-border bg-gray-50/50">
              <button onClick={() => setActiveTab('resume')} className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'resume' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-white' : 'text-secondaryText hover:text-primaryText'}`}>Resume Data</button>
              <button onClick={() => setActiveTab('jobs')} className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'jobs' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-white' : 'text-secondaryText hover:text-primaryText'}`}>Job Applications</button>
              <button onClick={() => setActiveTab('tests')} className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'tests' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-white' : 'text-secondaryText hover:text-primaryText'}`}>Test Attempts</button>
              <button onClick={() => setActiveTab('doctors')} className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'doctors' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-white' : 'text-secondaryText hover:text-primaryText'}`}>Professional Appointments</button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 max-h-[500px]">
              {activeTab === 'resume' && (
                <div className="space-y-4 animate-fade-in">
                  {!user.resume_data || Object.keys(user.resume_data).length === 0 ? (
                    <p className="text-secondaryText text-center py-8">No resume data extracted yet.</p>
                  ) : user.resume_data.data && user.resume_data.filename ? (
                    <div className="flex flex-col items-center justify-center p-8 border border-border rounded-lg bg-gray-50">
                      <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mb-4">
                        <Briefcase size={32} />
                      </div>
                      <h3 className="text-lg font-semibold text-primaryText mb-1">{user.resume_data.filename}</h3>
                      <p className="text-sm text-secondaryText mb-6">Resume file is available to view or download.</p>
                      <div className="flex items-center gap-4">
                        <button 
                          onClick={handleViewResume}
                          className="flex items-center gap-2 px-4 py-2 bg-white border border-border rounded-lg text-sm font-semibold text-primaryText hover:bg-gray-50 transition-colors"
                        >
                          <Eye size={16} />
                          View Resume
                        </button>
                        <button 
                          onClick={handleDownloadResume}
                          className="flex items-center gap-2 px-4 py-2 bg-primaryBrand text-white rounded-lg text-sm font-semibold hover:bg-primaryBrand/90 transition-colors"
                        >
                          <Download size={16} />
                          Download Resume
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="bg-gray-50 p-4 rounded-lg border border-border">
                      <pre className="text-sm text-secondaryText whitespace-pre-wrap font-mono">
                        {JSON.stringify(user.resume_data, null, 2)}
                      </pre>
                    </div>
                  )}
                </div>
              )}

              {activeTab === 'jobs' && (
                <div className="space-y-4 animate-fade-in">
                  {job_applications.length === 0 ? <p className="text-secondaryText text-center py-8">No job applications yet.</p> : (
                    job_applications.map((app: any) => (
                      <div key={app.id} className="p-4 border border-border rounded-lg flex justify-between items-center hover:bg-gray-50 transition-colors">
                        <div>
                          <h4 className="font-bold text-primaryText">{app.job?.title || 'Unknown Job'}</h4>
                          <p className="text-sm text-secondaryText">{app.job?.company || ''} • {app.job?.location || ''}</p>
                        </div>
                        <span className={`px-3 py-1 rounded-full text-xs font-medium border ${getStatusColor(app.status)}`}>
                          {app.status}
                        </span>
                      </div>
                    ))
                  )}
                </div>
              )}

              {activeTab === 'tests' && (
                <div className="space-y-4 animate-fade-in">
                  {groupedTestAttempts.length === 0 ? <p className="text-secondaryText text-center py-8">No test attempts yet.</p> : (
                    groupedTestAttempts.map((group: any) => {
                      const latest = group.latest_attempt;
                      const dateStr = latest.completed_at || latest.created_datetime;
                      const formattedDate = dateStr ? new Date(dateStr).toLocaleDateString('en-IN', {
                        day: '2-digit', month: 'short', year: 'numeric'
                      }) : 'Unknown Date';
                      
                      return (
                        <div key={group.test.id} className="p-4 border border-border rounded-lg flex flex-col gap-3 hover:bg-gray-50 transition-colors">
                          <div className="flex justify-between items-center">
                            <div>
                              <h4 className="font-bold text-primaryText flex items-center gap-2">
                                {group.test.title || 'Unknown Test'}
                                {group.attempts_count > 1 && (
                                  <span className="bg-highlight/10 text-highlight text-xs px-2 py-0.5 rounded-full font-medium">
                                    {group.attempts_count} Attempts
                                  </span>
                                )}
                              </h4>
                              <p className="text-sm text-secondaryText mt-1">
                                {group.test.tag || ''} • {group.test.difficulty || ''} 
                                <span className="mx-2">|</span> 
                                Last Attempt: {formattedDate}
                              </p>
                            </div>
                            <div className="text-right">
                              <p className="text-2xl font-bold text-primaryBrand">{group.first_score}%</p>
                              <p className="text-xs text-secondaryText">First Score</p>
                            </div>
                          </div>
                          {latest.ai_report && (
                            <div className="bg-blue-50/50 p-3 rounded text-sm text-secondaryText border border-blue-100">
                              <span className="font-semibold text-primaryBrand block mb-1">Latest AI Insights:</span>
                              {typeof latest.ai_report === 'string' ? latest.ai_report : JSON.stringify(latest.ai_report)}
                            </div>
                          )}
                        </div>
                      )
                    })
                  )}
                </div>
              )}

              {activeTab === 'doctors' && (
                <div className="space-y-4 animate-fade-in">
                  {professional_appointments.length === 0 ? <p className="text-secondaryText text-center py-8">No professional appointments yet.</p> : (
                    professional_appointments.map((apt: any) => (
                      <div key={apt.id} className="p-4 border border-border rounded-lg flex justify-between items-center hover:bg-gray-50 transition-colors">
                        <div>
                          <h4 className="font-bold text-primaryText">{apt.doctor?.name || 'Unknown Professional'}</h4>
                          <p className="text-sm text-secondaryText">{apt.appointment_date} at {apt.appointment_time}</p>
                        </div>
                        <span className={`px-3 py-1 rounded-full text-xs font-medium border ${getStatusColor(apt.status)}`}>
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
    </div>
  );
};

export default UserProfile;
