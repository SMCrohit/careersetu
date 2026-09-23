import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Search, CheckCircle, Clock, Send } from 'lucide-react';
import { useToast } from '../context/ToastContext';

interface User {
  full_name: string;
  mobile_number: string;
}

interface Professional {
  name: string;
  profession?: string;
  clinic: string;
}

interface Appointment {
  id: string;
  user_id: string;
  professional_id: string;
  appointment_date: string;
  appointment_time: string;
  status: string;
  user: User;
  professional: Professional;
}

const Appointments = () => {
  const { showToast } = useToast();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterProfession, setFilterProfession] = useState("All");

  useEffect(() => {
    fetchAppointments();
  }, []);

  const fetchAppointments = async () => {
    try {
      const res = await api.get('/admin/appointments');
      setAppointments(res.data);
    } catch (error) {
      showToast("Failed to fetch appointments", "error");
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = async (id: string, newStatus: string) => {
    try {
      const res = await api.put(`/admin/appointments/${id}/status?status=${newStatus}`);
      setAppointments(appointments.map(a => a.id === id ? res.data : a));
      showToast(`Appointment status updated to ${newStatus.replace('_', ' ')}`, "success");
    } catch (error) {
      showToast("Failed to update status", "error");
    }
  };

  const isAppointmentPast = (dateStr: string, timeStr: string) => {
    try {
      let dateToParse = dateStr;
      if (dateStr === 'Today') {
        const today = new Date();
        dateToParse = today.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
      }
      const appointmentDate = new Date(`${dateToParse} ${timeStr}`);
      return new Date() > appointmentDate;
    } catch (e) {
      return true; // fallback
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <span className="px-2.5 py-1 bg-orange-100 text-orange-700 rounded-full text-xs font-medium border border-orange-200 flex items-center gap-1 w-max"><Clock size={12}/> Pending</span>;
      case 'sent_to_doctor':
        return <span className="px-2.5 py-1 bg-blue-100 text-blue-700 rounded-full text-xs font-medium border border-blue-200 flex items-center gap-1 w-max"><Send size={12}/> Confirmed</span>;
      case 'completed':
        return <span className="px-2.5 py-1 bg-green-100 text-green-700 rounded-full text-xs font-medium border border-green-200 flex items-center gap-1 w-max"><CheckCircle size={12}/> Completed</span>;
      default:
        return <span className="px-2.5 py-1 bg-gray-100 text-gray-700 rounded-full text-xs font-medium border border-gray-200 uppercase">{status}</span>;
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Professional Appointments</h1>
          <p className="text-secondaryText">Manage patient appointments and assign them to professionals.</p>
        </div>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex justify-between items-center bg-gray-50/50">

          <div className="flex gap-4">
            <div className="relative w-72">
              <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
              <input type="text" placeholder="Search appointments..." className="input-field pl-10 bg-white" />
            </div>
            <select className="input-field bg-white w-48" value={filterProfession} onChange={e => setFilterProfession(e.target.value)}>
              <option value="All">All Professions</option>
              <option value="Doctor">Doctors</option>
              <option value="CA">CAs</option>
              <option value="Developer">Developers</option>
              <option value="Teacher">Teachers</option>
              <option value="Professor">Professors</option>
              <option value="Lawyer">Lawyers</option>
              <option value="Consultant">Consultants</option>
            </select>
          </div>

        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium">Patient</th>
                <th className="p-4 font-medium">Professional</th>
                <th className="p-4 font-medium">Date & Time</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} className="text-center p-8 text-secondaryText">Loading appointments...</td></tr>
              ) : appointments.length === 0 ? (
                <tr><td colSpan={5} className="text-center p-8 text-secondaryText">No appointments found.</td></tr>
              ) : (
                appointments.filter(appt => filterProfession === "All" || appt.professional?.profession === filterProfession).map((appt) => (
                  <tr key={appt.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4">
                      <div className="font-medium text-primaryText">{appt.user?.full_name || 'Unknown User'}</div>
                      <div className="text-xs text-secondaryText">{appt.user?.mobile_number || ''}</div>
                    </td>
                    <td className="p-4">
                      <div className="font-medium text-primaryText">{appt.professional?.name || 'Unknown Professional'}</div>
                      <div className="text-xs text-secondaryText">{appt.professional?.clinic || ''}</div>
                    </td>
                    <td className="p-4 text-secondaryText">
                      {appt.appointment_date} <br/>
                      <span className="text-xs">{appt.appointment_time}</span>
                    </td>
                    <td className="p-4">
                      {getStatusBadge(appt.status)}
                    </td>
                    <td className="p-4 text-right">
                      {appt.status === 'pending' && (
                        <button 
                          onClick={() => updateStatus(appt.id, 'sent_to_doctor')}
                          className="px-3 py-1.5 bg-primaryBrand text-white rounded text-sm font-medium hover:bg-opacity-90 transition-colors"
                        >
                          Send to Professional
                        </button>
                      )}
                      {appt.status === 'sent_to_doctor' && (
                        <button 
                          onClick={() => updateStatus(appt.id, 'completed')}
                          disabled={!isAppointmentPast(appt.appointment_date, appt.appointment_time)}
                          className={`px-3 py-1.5 text-white rounded text-sm font-medium transition-colors ${!isAppointmentPast(appt.appointment_date, appt.appointment_time) ? 'bg-gray-400 cursor-not-allowed' : 'bg-green-600 hover:bg-opacity-90'}`}
                          title={!isAppointmentPast(appt.appointment_date, appt.appointment_time) ? 'Cannot complete a future appointment' : ''}
                        >
                          Mark Completed
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Appointments;
