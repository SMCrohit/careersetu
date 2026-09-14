import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { ArrowLeft, User, Phone, Mail, MapPin, Target, Briefcase, GraduationCap, Stethoscope } from 'lucide-react';
import { useToast } from '../context/ToastContext';

const UserProfile = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');

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

  const { user, job_applications, test_attempts, doctor_appointments } = data;

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
                <p className="text-2xl font-bold text-primaryText">{doctor_appointments.length}</p>
                <p className="text-xs text-secondaryText uppercase tracking-wider font-semibold">Appointments</p>
              </div>
            </div>
          </div>

          <div className="card flex-1 bg-white overflow-hidden flex flex-col">
            <div className="flex border-b border-border bg-gray-50/50">
              <button onClick={() => setActiveTab('jobs')} className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'jobs' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-white' : 'text-secondaryText hover:text-primaryText'}`}>Job Applications</button>
              <button onClick={() => setActiveTab('tests')} className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'tests' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-white' : 'text-secondaryText hover:text-primaryText'}`}>Test Attempts</button>
              <button onClick={() => setActiveTab('doctors')} className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'doctors' ? 'text-primaryBrand border-b-2 border-primaryBrand bg-white' : 'text-secondaryText hover:text-primaryText'}`}>Doctor Appointments</button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 max-h-[500px]">
              {activeTab === 'jobs' && (
                <div className="space-y-4 animate-fade-in">
                  {job_applications.length === 0 ? <p className="text-secondaryText text-center py-8">No job applications yet.</p> : (
                    job_applications.map((app: any) => (
                      <div key={app.id} className="p-4 border border-border rounded-lg flex justify-between items-center hover:bg-gray-50 transition-colors">
                        <div>
                          <h4 className="font-bold text-primaryText">{app.job?.title || 'Unknown Job'}</h4>
                          <p className="text-sm text-secondaryText">{app.job?.company || ''} • {app.job?.location || ''}</p>
                        </div>
                        <span className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium border border-gray-200">{app.status}</span>
                      </div>
                    ))
                  )}
                </div>
              )}

              {activeTab === 'tests' && (
                <div className="space-y-4 animate-fade-in">
                  {test_attempts.length === 0 ? <p className="text-secondaryText text-center py-8">No test attempts yet.</p> : (
                    test_attempts.map((att: any) => (
                      <div key={att.id} className="p-4 border border-border rounded-lg flex justify-between items-center hover:bg-gray-50 transition-colors">
                        <div>
                          <h4 className="font-bold text-primaryText">{att.test?.title || 'Unknown Test'}</h4>
                          <p className="text-sm text-secondaryText">{att.test?.tag || ''} • {att.test?.difficulty || ''}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-2xl font-bold text-primaryBrand">{att.score}%</p>
                          <p className="text-xs text-secondaryText">Score</p>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}

              {activeTab === 'doctors' && (
                <div className="space-y-4 animate-fade-in">
                  {doctor_appointments.length === 0 ? <p className="text-secondaryText text-center py-8">No doctor appointments yet.</p> : (
                    doctor_appointments.map((apt: any) => (
                      <div key={apt.id} className="p-4 border border-border rounded-lg flex justify-between items-center hover:bg-gray-50 transition-colors">
                        <div>
                          <h4 className="font-bold text-primaryText">{apt.doctor?.name || 'Unknown Doctor'}</h4>
                          <p className="text-sm text-secondaryText">{apt.appointment_date} at {apt.appointment_time}</p>
                        </div>
                        <span className={`px-3 py-1 rounded-full text-xs font-medium border ${
                          apt.status === 'Confirmed' ? 'bg-success/10 text-success border-success/20' : 
                          apt.status === 'Cancelled' ? 'bg-error/10 text-error border-error/20' : 
                          'bg-highlight/10 text-highlight border-highlight/20'
                        }`}>{apt.status}</span>
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
