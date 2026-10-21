import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Tag, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, CheckCircle2, Clock, Building } from 'lucide-react';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import Modal from '../components/Modal';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface ClaimedOffer {
  id: string;
  user_id: string;
  offer_id: string;
  voucher_code?: string;
  status?: string;
  created_datetime?: string;
  redeemed_at?: string;
  inquiry_details?: {
    phone?: string;
    email?: string;
    notes?: string;
    college?: string;
    stream?: string;
    [key: string]: any;
  };
  offer?: {
    id: string;
    title: string;
    subtitle?: string;
    city?: string;
    type?: string;
    discount_code?: string;
    merchant_name?: string;
    redemption_type?: string;
  };
  user?: {
    id: string;
    full_name: string;
    mobile_number: string;
    email: string;
  };
}

const ClaimedOffers = () => {
  const { showToast } = useToast();
  const [claimedOffers, setClaimedOffers] = useState<ClaimedOffer[]>([]);
  const [loading, setLoading] = useState(true);

  const [selectedInquiry, setSelectedInquiry] = useState<ClaimedOffer | null>(null);

  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchClaimedOffers();
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

  const fetchClaimedOffers = async () => {
    try {
      const res = await api.get('/admin/claimed-offers');
      setClaimedOffers(res.data);
    } catch (error) {
      showToast("Failed to fetch claimed offers", "error");
    } finally {
      setLoading(false);
    }
  };

  // ── Export helpers ─────────────────────────────────────────────────────────
  const exportRows = claimedOffers.map((co, i) => ({
    '#': i + 1,
    'Student Name': co.user?.full_name || 'N/A',
    'Mobile': co.user?.mobile_number || 'N/A',
    'Email': co.user?.email || 'N/A',
    'Offer Title': co.offer?.title || 'Unknown Offer',
    'Partner/Merchant': co.offer?.merchant_name || '—',
    'Category': co.offer?.type || '—',
    'City': co.offer?.city || 'All',
    'Voucher / Pass ID': co.voucher_code || co.offer?.discount_code || 'N/A',
    'Status': (co.status || 'active').toUpperCase(),
    'Claimed Date': co.created_datetime ? new Date(co.created_datetime).toLocaleDateString('en-IN') : '—',
  }));

  const exportToCSV = () => {
    if (exportRows.length === 0) return;
    const headers = Object.keys(exportRows[0]);
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'claimed_student_offers.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Claims & Leads');
    XLSX.writeFile(wb, 'claimed_student_offers.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Claimed Offers & Partner Inquiries', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${claimedOffers.length} claims`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'Student Name', 'Mobile', 'Email', 'Offer Title', 'Partner', 'City', 'Voucher / Pass', 'Status']],
      body: exportRows.map((r) => [r['#'], r['Student Name'], r['Mobile'], r['Email'], r['Offer Title'], r['Partner/Merchant'], r['City'], r['Voucher / Pass ID'], r['Status']]),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [10, 102, 194], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('claimed_student_offers.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const columns: Column<ClaimedOffer>[] = [
    {
      header: 'Student',
      accessorKey: 'user.full_name',
      sortable: true,
      cell: (co) => (
        <div>
          <div className="font-semibold text-primaryText">{co.user?.full_name || 'N/A'}</div>
          <div className="text-xs text-secondaryText flex items-center gap-1.5 mt-0.5">
            <span>{co.user?.mobile_number || 'No phone'}</span>
            {co.user?.email && <span>· {co.user?.email}</span>}
          </div>
        </div>
      )
    },
    {
      header: 'Offer & Partner',
      accessorKey: 'offer.title',
      sortable: true,
      cell: (co) => (
        <div>
          <div className="text-sm font-medium text-primaryBrand">{co.offer?.title || 'Unknown Offer'}</div>
          <div className="text-xs text-secondaryText flex items-center gap-1 mt-0.5">
            {co.offer?.merchant_name && (
              <span className="font-medium text-primaryText flex items-center gap-1">
                <Building size={11} /> {co.offer?.merchant_name}
              </span>
            )}
            {co.offer?.city && <span>· {co.offer?.city}</span>}
          </div>
        </div>
      )
    },
    {
      header: 'Voucher / Digital Pass ID',
      accessorKey: 'voucher_code',
      sortable: true,
      cell: (co) => {
        const code = co.voucher_code || co.offer?.discount_code || 'CLAIMED';
        const isPass = code.startsWith('PASS-');
        const isLead = code.startsWith('LEAD-');
        return (
          <div>
            <span className={`inline-flex items-center px-2.5 py-0.5 rounded font-mono text-xs font-semibold ${
              isPass ? 'bg-amber-100 text-amber-800 border border-amber-300' :
              isLead ? 'bg-emerald-100 text-emerald-800 border border-emerald-300' :
              'bg-primaryBrand/10 text-primaryBrand border border-primaryBrand/20'
            }`}>
              {code}
            </span>
            {co.inquiry_details && (
              <button 
                onClick={() => setSelectedInquiry(co)}
                className="block text-[11px] text-primaryBrand underline mt-1 font-medium hover:text-blue-700"
              >
                View Lead Notes
              </button>
            )}
          </div>
        );
      }
    },
    {
      header: 'Status',
      accessorKey: 'status',
      sortable: true,
      cell: (co) => {
        const isRedeemed = co.status === 'redeemed';
        return (
          <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium ${
            isRedeemed ? 'bg-emerald-100 text-emerald-800' : 'bg-blue-100 text-blue-800'
          }`}>
            {isRedeemed ? <CheckCircle2 size={12} /> : <Clock size={12} />}
            {isRedeemed ? 'Redeemed' : 'Active Pass'}
          </span>
        );
      }
    },
    {
      header: 'Claimed Date',
      accessorKey: 'created_datetime',
      sortable: true,
      cell: (co) => (
        <span className="text-xs text-secondaryText">
          {co.created_datetime ? new Date(co.created_datetime).toLocaleDateString('en-IN', {
            day: 'numeric',
            month: 'short',
            year: 'numeric'
          }) : '—'}
        </span>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primaryBrand/10 rounded-xl flex items-center justify-center">
            <Tag className="text-primaryBrand" size={20} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-primaryText">Claimed Offers & Inquiries</h1>
            <p className="text-sm text-secondaryText">Real-time student claims, digital passes, and partner callback leads.</p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
            {claimedOffers.length} Claims Total
          </div>

          {/* Export */}
          <div className="relative" ref={exportRef}>
            <button
              onClick={() => setExportOpen((o) => !o)}
              className="flex items-center gap-2 px-4 py-2 bg-primaryBrand text-white rounded-md text-sm font-semibold hover:bg-primaryBrand/90 transition-colors shadow-sm"
            >
              <Download size={16} />
              Export
              <ChevronDown size={14} className={`transition-transform ${exportOpen ? 'rotate-180' : ''}`} />
            </button>
            {exportOpen && (
              <div className="absolute right-0 mt-2 w-48 bg-white border border-border rounded-md shadow-lg z-50 overflow-hidden animate-fade-in">
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
        data={claimedOffers}
        columns={columns}
        searchPlaceholder="Search by student, offer, partner, voucher..."
        searchableKeys={['user.full_name', 'user.email', 'user.mobile_number', 'offer.title', 'offer.merchant_name', 'voucher_code']}
        loading={loading}
        emptyStateMessage="No claimed offers found yet."
        emptyStateIcon={<Tag size={36} className="text-border" />}
      />

      {/* Inquiry Details Modal */}
      <Modal 
        isOpen={Boolean(selectedInquiry)} 
        onClose={() => setSelectedInquiry(null)} 
        title="Student Inquiry & Callback Details"
      >
        {selectedInquiry && (
          <div className="space-y-4 text-sm">
            <div className="p-3 bg-backgroundLight rounded-lg border border-border">
              <div className="font-semibold text-primaryText">{selectedInquiry.offer?.title}</div>
              <div className="text-xs text-secondaryText mt-0.5">Partner: {selectedInquiry.offer?.merchant_name || 'Direct Partner'}</div>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div>
                <span className="text-secondaryText block">Student Name:</span>
                <span className="font-semibold text-primaryText">{selectedInquiry.user?.full_name}</span>
              </div>
              <div>
                <span className="text-secondaryText block">Contact Number:</span>
                <span className="font-semibold text-primaryText">{selectedInquiry.user?.mobile_number}</span>
              </div>
              <div>
                <span className="text-secondaryText block">Email:</span>
                <span className="font-semibold text-primaryText">{selectedInquiry.user?.email || 'N/A'}</span>
              </div>
              <div>
                <span className="text-secondaryText block">Pass / Reference ID:</span>
                <span className="font-mono font-semibold text-primaryBrand">{selectedInquiry.voucher_code}</span>
              </div>
            </div>

            {selectedInquiry.inquiry_details && (
              <div>
                <span className="text-secondaryText block text-xs mb-1 font-medium">Inquiry Payload / Custom Student Input:</span>
                <pre className="p-3 bg-gray-50 border border-border rounded-lg text-xs overflow-x-auto text-primaryText font-mono">
                  {JSON.stringify(selectedInquiry.inquiry_details, null, 2)}
                </pre>
              </div>
            )}

            <div className="flex justify-end pt-2">
              <button 
                type="button" 
                onClick={() => setSelectedInquiry(null)} 
                className="btn-primary text-xs"
              >
                Close
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};

export default ClaimedOffers;
