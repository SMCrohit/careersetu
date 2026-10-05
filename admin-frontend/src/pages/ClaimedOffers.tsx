import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Tag, Download, ChevronDown, FileText, FileSpreadsheet, FileDown } from 'lucide-react';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface ClaimedOffer {
  id: string;
  user_id: string;
  offer_id: string;
  offer: {
    title: string;
    city: string;
    discount_code: string;
  };
  user: {
    full_name: string;
    mobile_number: string;
    email: string;
  };
}

const ClaimedOffers = () => {
  const { showToast } = useToast();
  const [claimedOffers, setClaimedOffers] = useState<ClaimedOffer[]>([]);
  const [loading, setLoading] = useState(true);

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
    'User Name': co.user?.full_name || 'N/A',
    'Mobile': co.user?.mobile_number || 'N/A',
    'Email': co.user?.email || 'N/A',
    'Offer': co.offer?.title || 'Unknown Offer',
    'City': co.offer?.city || 'All',
    'Code Used': co.offer?.discount_code || 'N/A',
  }));

  const exportToCSV = () => {
    if (exportRows.length === 0) return;
    const headers = Object.keys(exportRows[0]);
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'claimed_offers.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Claimed Offers');
    XLSX.writeFile(wb, 'claimed_offers.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Claimed Offers', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${claimedOffers.length} claimed offers`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'User Name', 'Mobile', 'Email', 'Offer', 'City', 'Code Used']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('claimed_offers.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const columns: Column<ClaimedOffer>[] = [
    {
      header: 'User',
      accessorKey: 'user.full_name',
      sortable: true,
      cell: (co) => <div className="font-medium text-primaryText">{co.user?.full_name || 'N/A'}</div>
    },
    {
      header: 'Contact',
      accessorKey: 'user.mobile_number',
      cell: (co) => (
        <div>
          <div className="text-sm text-primaryText">{co.user?.mobile_number || 'N/A'}</div>
          <div className="text-xs text-secondaryText">{co.user?.email || ''}</div>
        </div>
      )
    },
    {
      header: 'Offer',
      accessorKey: 'offer.title',
      sortable: true,
      cell: (co) => <div className="text-sm font-medium">{co.offer?.title || 'Unknown Offer'}</div>
    },
    {
      header: 'City',
      accessorKey: 'offer.city',
      sortable: true,
      cell: (co) => <div className="text-sm text-secondaryText">{co.offer?.city || 'All'}</div>
    },
    {
      header: 'Code Used',
      accessorKey: 'offer.discount_code',
      cell: (co) => (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primaryBrand/10 text-primaryBrand">
          {co.offer?.discount_code || 'N/A'}
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
            <h1 className="text-2xl font-bold text-primaryText">Claimed Offers</h1>
            <p className="text-sm text-secondaryText">Track which users claimed offers</p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
            {claimedOffers.length} Claims
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
        data={claimedOffers}
        columns={columns}
        searchPlaceholder="Search by user or offer..."
        searchableKeys={['user.full_name', 'user.mobile_number', 'offer.title']}
        loading={loading}
        emptyStateMessage="No claimed offers found."
        emptyStateIcon={<Tag size={36} className="text-border" />}
      />
    </div>
  );
};

export default ClaimedOffers;
