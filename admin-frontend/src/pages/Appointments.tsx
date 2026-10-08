import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { CheckCircle, Clock, Send, Calendar, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, Filter, MessageCircle } from 'lucide-react';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

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
  consultation_mode?: string;
  notes_by_student?: string;
  user: User;
  professional: Professional;
}

const Appointments = () => {
  const { showToast } = useToast();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterProfession, setFilterProfession] = useState("All");

  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchAppointments();
  }, []);

  // Close export dropdown on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (exportRef.current && !exportRef.current.contains(e.target as Node)) {
        setExportOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
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

  const filteredAppointments = appointments.filter(appt => 
    filterProfession === "All" || appt.professional?.profession === filterProfession
  );

  // ── Export helpers ─────────────────────────────────────────────────────────
  const exportRows = filteredAppointments.map((appt, i) => ({
    '#': i + 1,
    'Patient Name': appt.user?.full_name || '—',
    'Mobile': appt.user?.mobile_number || '—',
    'Professional': appt.professional?.name || '—',
    'Profession': appt.professional?.profession || '—',
    'Clinic': appt.professional?.clinic || '—',
    'Date': appt.appointment_date,
    'Time': appt.appointment_time,
    'Status': appt.status,
  }));

  const exportToCSV = () => {
    if (exportRows.length === 0) return;
    const headers = Object.keys(exportRows[0]);
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'appointments.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Appointments');
    XLSX.writeFile(wb, 'appointments.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Appointments', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${filteredAppointments.length} appointments`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'Patient', 'Mobile', 'Professional', 'Profession', 'Date', 'Time', 'Status']],
      body: exportRows.map((r) => Object.values(r).filter((_, i) => i !== 5)), // Removing Clinic to fit width
      styles: { fontSize: 7.5, cellPadding: 2.5 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('appointments.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const columns: Column<Appointment>[] = [
    {
      header: 'Patient',
      accessorKey: 'user.full_name', // enables search
      cell: (appt) => (
        <div>
          <div className="font-medium text-primaryText">{appt.user?.full_name || 'Unknown User'}</div>
          <div className="text-xs text-secondaryText">{appt.user?.mobile_number || ''}</div>
          {appt.notes_by_student && (
            <div className="mt-1 text-xs italic text-gray-500 bg-gray-50 p-1 rounded border border-gray-100 max-w-[200px] truncate" title={appt.notes_by_student}>
              "{appt.notes_by_student}"
            </div>
          )}
        </div>
      )
    },
    {
      header: 'Professional',
      accessorKey: 'professional.name', // enables search
      cell: (appt) => (
        <div>
          <div className="font-medium text-primaryText">{appt.professional?.name || 'Unknown Professional'}</div>
          <div className="text-xs text-secondaryText">{appt.professional?.clinic || ''}</div>
        </div>
      )
    },
    {
      header: 'Date & Time',
      accessorKey: 'appointment_date',
      cell: (appt) => (
        <div className="text-secondaryText">
          {appt.appointment_date} <br/>
          <span className="text-xs font-semibold">{appt.appointment_time}</span>
          <br/>
          <span className="text-[10px] uppercase tracking-wider text-primaryBrand/70 font-semibold bg-primaryBrand/10 px-1 py-0.5 rounded">{appt.consultation_mode || 'In-Person'}</span>
        </div>
      )
    },
    {
      header: 'Status',
      accessorKey: 'status',
      cell: (appt) => getStatusBadge(appt.status)
    },
    {
      header: 'Actions',
      cell: (appt) => (
        <div className="text-right flex items-center justify-end gap-2">
          {appt.status === 'pending' && (
            <>
              <a 
                href={`https://wa.me/?text=${encodeURIComponent(`Hello ${appt.professional.name},\n\nYou have a new ${appt.consultation_mode || 'In-Person'} booking request from ${appt.user.full_name} on ${appt.appointment_date} at ${appt.appointment_time}.\n\nPlease reply to confirm if you are available.`)}`}
                target="_blank"
                rel="noopener noreferrer"
                className="p-1.5 bg-green-50 text-green-600 rounded hover:bg-green-100 transition-colors border border-green-200"
                title="Notify via WhatsApp"
              >
                <MessageCircle size={18} />
              </a>
              <button 
                onClick={() => updateStatus(appt.id, 'sent_to_doctor')}
                className="px-3 py-1.5 bg-primaryBrand text-white rounded text-sm font-medium hover:bg-opacity-90 transition-colors whitespace-nowrap"
              >
                Confirm Booking
              </button>
            </>
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
        </div>
      )
    }
  ];

  const toolbarExtras = (
    <div className="relative w-48">
      <Filter className="absolute left-3 top-2.5 text-borderDark" size={18} />
      <select 
        className="input-field pl-10 pr-8 bg-white appearance-none cursor-pointer w-full" 
        value={filterProfession} 
        onChange={e => setFilterProfession(e.target.value)}
      >
        <option value="All">All Professions</option>
        <option value="Doctor">Doctors</option>
        <option value="CA">CAs</option>
        <option value="Developer">Developers</option>
        <option value="Teacher">Teachers</option>
        <option value="Professor">Professors</option>
        <option value="Lawyer">Lawyers</option>
        <option value="Consultant">Consultants</option>
      </select>
      <ChevronDown className="absolute right-3 top-3 text-borderDark pointer-events-none" size={16} />
    </div>
  );

  return (
    <div className="animate-fade-in">
      <div className="flex flex-wrap justify-between items-center gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Professional Appointments</h1>
          <p className="text-secondaryText">Manage patient appointments and assign them to professionals.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
            {filteredAppointments.length} Appointments
          </div>

          {/* Export */}
          <div className="relative" ref={exportRef}>
            <button
              onClick={() => setExportOpen((o) => !o)}
              className="flex items-center gap-2 px-4 py-2.5 bg-primaryBrand text-white rounded-xl text-sm font-semibold hover:bg-primaryBrand/90 transition-colors shadow-sm"
            >
              <Download size={16} />
              Export
              <ChevronDown size={14} className={`transition-transform ${exportOpen ? 'rotate-180' : ''}`} />
            </button>
            {exportOpen && (
              <div className="absolute right-0 mt-2 w-48 bg-white border border-border rounded-xl shadow-lg z-50 overflow-hidden animate-fade-in">
                <button onClick={exportToPDF} className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors">
                  <FileText size={16} className="text-red-500" /> Export as PDF
                </button>
                <button onClick={exportToExcel} className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors border-t border-border">
                  <FileSpreadsheet size={16} className="text-green-600" /> Export as Excel
                </button>
                <button onClick={exportToCSV} className="w-full flex items-center gap-3 px-4 py-3 text-sm text-primaryText hover:bg-backgroundLight transition-colors border-t border-border">
                  <FileDown size={16} className="text-blue-500" /> Export as CSV
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      <DataTable
        data={filteredAppointments}
        columns={columns}
        searchPlaceholder="Search appointments..."
        searchableKeys={['user.full_name', 'professional.name', 'user.mobile_number']}
        loading={loading}
        emptyStateMessage="No appointments found."
        emptyStateIcon={<Calendar size={36} className="text-border" />}
        toolbarExtras={toolbarExtras}
      />
    </div>
  );
};

export default Appointments;
