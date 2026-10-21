import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { 
  Plus, Edit2, Trash2, Download, ChevronDown, FileText, 
  FileSpreadsheet, FileDown, Tag, Ticket, Building, MapPin, X, Filter 
} from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface Offer {
  id: string;
  title: string;
  subtitle: string;
  type: string;
  action: string;
  description: string;
  city?: string;
  state?: string;
  pincode?: string;
  target_professions?: string;
  discount_code?: string;
  valid_until?: string;
  merchant_name?: string;
  merchant_address?: string;
  partner_phone?: string;
  external_url?: string;
  redemption_type: string;
  terms_and_conditions?: string;
  target_stream?: string;
  min_resume_score?: number;
  total_quota?: number;
  claimed_count?: number;
  available_vouchers_count?: number;
  voucher_codes?: string[];
}

const defaultFormData = {
  title: '',
  subtitle: '',
  type: 'Gyms & Fitness',
  action: 'Claim Deal',
  description: '',
  city: '',
  state: '',
  pincode: '',
  target_professions: '',
  discount_code: '',
  valid_until: '',
  merchant_name: '',
  merchant_address: '',
  partner_phone: '',
  external_url: '',
  redemption_type: 'generic_code',
  terms_and_conditions: '',
  target_stream: 'All',
  min_resume_score: 0,
  total_quota: '' as any,
};

const CATEGORIES = [
  'Gyms & Fitness',
  'Banks & Finance',
  'Coaching & Classes',
  'Books & Stationery',
  'Food & Cafes',
  'Tech & Subscriptions'
];

const REDEMPTION_TYPES = [
  { value: 'generic_code', label: 'Universal Promo Code (e.g. CAREER20)' },
  { value: 'unique_code_pool', label: 'Unique Voucher Pool (1 per student, CSV upload)' },
  { value: 'in_store_pass', label: 'In-Store Digital Pass (QR/Barcode for counter)' },
  { value: 'bank_lead', label: 'Bank / Coaching Lead (Request Callback/Apply)' },
  { value: 'affiliate_link', label: 'Direct Partner Link (External Portal)' },
];

const Offers = () => {
  const { showToast } = useToast();
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  // Target professions state from /goals
  const [goals, setGoals] = useState<any[]>([]);
  const [tagDropdownOpen, setTagDropdownOpen] = useState(false);
  const tagDropdownRef = useRef<HTMLDivElement>(null);

  // Pincode auto-lookup state
  const [pincodeLoading, setPincodeLoading] = useState(false);
  const [pincodeData, setPincodeData] = useState<any[]>([]);
  const [selectedArea, setSelectedArea] = useState('');

  // Unique Voucher Pool file upload inside Create / Edit modal
  const [uploadedVouchers, setUploadedVouchers] = useState<string[]>([]);
  const [voucherFileName, setVoucherFileName] = useState('');

  // Voucher pool management modal state (for already created offers)
  const [isVoucherModalOpen, setIsVoucherModalOpen] = useState(false);
  const [activeOfferForVouchers, setActiveOfferForVouchers] = useState<Offer | null>(null);
  const [voucherInput, setVoucherInput] = useState('');
  const [voucherStats, setVoucherStats] = useState<{ total: number; claimed: number; available: number } | null>(null);
  const [voucherLoading, setVoucherLoading] = useState(false);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  // Filter Drawer State
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [filterCity, setFilterCity] = useState('All');
  const [cities, setCities] = useState<string[]>([]);
  const [filterCategory, setFilterCategory] = useState('All');
  const [filterRedemptionType, setFilterRedemptionType] = useState('All');
  const [filterProfessions, setFilterProfessions] = useState<string[]>([]);
  const [filterValidityUpto, setFilterValidityUpto] = useState('');

  const activeFiltersCount = 
    (filterCity !== 'All' ? 1 : 0) +
    (filterCategory !== 'All' ? 1 : 0) +
    (filterRedemptionType !== 'All' ? 1 : 0) +
    (filterProfessions.length > 0 ? 1 : 0) +
    (filterValidityUpto ? 1 : 0);

  useEffect(() => {
    fetchOffersWithParams();
    api.get('/goals').then(res => setGoals(res.data)).catch(() => {});
    api.get('/offers/cities').then(res => setCities(res.data)).catch(() => {});
  }, []);

  // Close dropdowns when clicking outside
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (exportRef.current && !exportRef.current.contains(e.target as Node)) {
        setExportOpen(false);
      }
      if (tagDropdownRef.current && !tagDropdownRef.current.contains(e.target as Node)) {
        setTagDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const fetchOffersWithParams = async (
    city = filterCity,
    category = filterCategory,
    redemptionType = filterRedemptionType,
    professions = filterProfessions,
    validityUpto = filterValidityUpto
  ) => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (city && city !== 'All') params.append('city', city);
      if (category && category !== 'All') params.append('category', category);
      if (redemptionType && redemptionType !== 'All') params.append('redemption_type', redemptionType);
      if (professions && professions.length > 0) params.append('professions', professions.join(','));
      if (validityUpto) params.append('validity_upto', validityUpto);

      const res = await api.get(`/offers?${params.toString()}`);
      setOffers(res.data);
    } catch (error) {
      showToast("Failed to fetch offers", "error");
    } finally {
      setLoading(false);
    }
  };

  const fetchOffers = () => fetchOffersWithParams();

  const handleApplyFilters = () => {
    fetchOffersWithParams(filterCity, filterCategory, filterRedemptionType, filterProfessions, filterValidityUpto);
    setIsFilterOpen(false);
  };

  const handleClearFilters = () => {
    setFilterCity('All');
    setFilterCategory('All');
    setFilterRedemptionType('All');
    setFilterProfessions([]);
    setFilterValidityUpto('');
    fetchOffersWithParams('All', 'All', 'All', [], '');
    setIsFilterOpen(false);
  };

  const confirmDelete = async () => {
    if (!itemToDelete) return;
    try {
      await api.delete(`/offers/${itemToDelete}`);
      setOffers(offers.filter(o => o.id !== itemToDelete));
      showToast("Offer deleted successfully", "success");
    } catch (error) {
      showToast("Failed to delete offer", "error");
    }
    setItemToDelete(null);
  };

  const handlePincodeChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const code = e.target.value.replace(/\D/g, '').slice(0, 6);
    setSelectedArea('');
    setFormData(prev => ({ ...prev, pincode: code, city: '', state: '' }));
    
    if (code.length === 6) {
      setPincodeLoading(true);
      try {
        const res = await api.get(`/pincodes/${code}`);
        setPincodeData(res.data);
        if (res.data && res.data.length > 0) {
          setSelectedArea(res.data[0].area);
          setFormData(prev => ({
            ...prev,
            pincode: code,
            city: res.data[0].city,
            state: res.data[0].state
          }));
        } else {
          showToast("No areas found for this Pincode", "error");
        }
      } catch (err) {
        showToast("Invalid Pincode", "error");
      } finally {
        setPincodeLoading(false);
      }
    } else {
      setPincodeData([]);
    }
  };

  const handleProfessionToggle = (option: string) => {
    const currentTags = formData.target_professions 
      ? formData.target_professions.split(',').map(t => t.trim()).filter(Boolean) 
      : [];
    if (currentTags.includes(option)) {
      setFormData({ ...formData, target_professions: currentTags.filter(t => t !== option).join(', ') });
    } else {
      setFormData({ ...formData, target_professions: [...currentTags, option].join(', ') });
    }
  };

  const downloadSampleTemplate = () => {
    const sampleData = [
      { 'Voucher Code': 'OFFER-DEAL-1001' },
      { 'Voucher Code': 'OFFER-DEAL-1002' },
      { 'Voucher Code': 'OFFER-DEAL-1003' },
      { 'Voucher Code': 'OFFER-DEAL-1004' },
      { 'Voucher Code': 'OFFER-DEAL-1005' },
    ];
    const ws = XLSX.utils.json_to_sheet(sampleData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Sample_Vouchers');
    XLSX.writeFile(wb, 'voucher_sample_template.xlsx');
  };

  const handleExcelUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (evt) => {
      try {
        const bstr = evt.target?.result;
        const wb = XLSX.read(bstr, { type: 'binary' });
        const wsName = wb.SheetNames[0];
        const ws = wb.Sheets[wsName];
        const rawData: any[][] = XLSX.utils.sheet_to_json(ws, { header: 1 });
        const codes: string[] = [];
        rawData.forEach((row) => {
          if (Array.isArray(row)) {
            row.forEach((cell) => {
              const val = String(cell || '').trim();
              if (val && !['voucher code', 'vouchercode', 'code', 'codes', 'voucher_code'].includes(val.toLowerCase())) {
                codes.push(val);
              }
            });
          }
        });
        const uniqueCodes = Array.from(new Set(codes));
        if (uniqueCodes.length === 0) {
          showToast("No valid voucher codes found in file", "error");
          return;
        }
        setUploadedVouchers(uniqueCodes);
        setVoucherFileName(file.name);
        showToast(`Loaded ${uniqueCodes.length} voucher codes from ${file.name}`, "success");
      } catch (err) {
        showToast("Failed to parse file", "error");
      }
    };
    reader.readAsBinaryString(file);
  };

  const openEditModal = (offer: Offer) => {
    setFormData({
      title: offer.title || '',
      subtitle: offer.subtitle || '',
      type: offer.type || 'Gyms & Fitness',
      action: offer.action || 'Claim Deal',
      description: offer.description || '',
      city: offer.city || '',
      state: offer.state || '',
      pincode: offer.pincode || '',
      target_professions: offer.target_professions || '',
      discount_code: offer.discount_code || '',
      valid_until: offer.valid_until ? new Date(offer.valid_until).toISOString().split('T')[0] : '',
      merchant_name: offer.merchant_name || '',
      merchant_address: offer.merchant_address || '',
      partner_phone: offer.partner_phone || '',
      external_url: offer.external_url || '',
      redemption_type: offer.redemption_type || 'generic_code',
      terms_and_conditions: offer.terms_and_conditions || '',
      target_stream: offer.target_stream || 'All',
      min_resume_score: offer.min_resume_score || 0,
      total_quota: offer.total_quota !== undefined && offer.total_quota !== null ? offer.total_quota : '',
    });
    setUploadedVouchers([]);
    setVoucherFileName('');
    if (offer.pincode && offer.pincode.length === 6) {
      api.get(`/pincodes/${offer.pincode}`).then(res => {
        setPincodeData(res.data);
        if (res.data && res.data.length > 0) {
          const match = res.data.find((p: any) => p.city === offer.city);
          setSelectedArea(match ? match.area : res.data[0].area);
        }
      }).catch(() => {});
    } else {
      setPincodeData([]);
      setSelectedArea('');
    }
    setEditingId(offer.id);
    setIsModalOpen(true);
  };

  const openAddModal = () => {
    setFormData(defaultFormData);
    setPincodeData([]);
    setSelectedArea('');
    setUploadedVouchers([]);
    setVoucherFileName('');
    setEditingId(null);
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.pincode || formData.pincode.length !== 6) {
      showToast("Please enter a valid 6-digit Pincode", "error");
      return;
    }
    if (!selectedArea && pincodeData.length > 0) {
      showToast("Please select an Area", "error");
      return;
    }
    if (!formData.city || !formData.state) {
      showToast("City and State are compulsory. Please enter a valid Pincode and select Area.", "error");
      return;
    }
    try {
      const payload: any = {
        ...formData,
        total_quota: formData.total_quota ? Number(formData.total_quota) : null,
        min_resume_score: Number(formData.min_resume_score) || 0,
        valid_until: formData.valid_until ? new Date(formData.valid_until).toISOString() : null,
      };

      if (formData.redemption_type === 'unique_code_pool' && uploadedVouchers.length > 0) {
        payload.voucher_codes = uploadedVouchers;
      }

      if (editingId) {
        const res = await api.put(`/offers/${editingId}`, payload);
        setOffers(offers.map(o => o.id === editingId ? res.data : o));
        showToast("Offer updated successfully", "success");
      } else {
        const res = await api.post('/offers', payload);
        setOffers([res.data, ...offers]);
        showToast("Offer created successfully", "success");
      }
      setIsModalOpen(false);
      setFormData(defaultFormData);
      setEditingId(null);
      setUploadedVouchers([]);
      setVoucherFileName('');
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} offer`, "error");
    }
  };

  const openVoucherModal = async (offer: Offer) => {
    setActiveOfferForVouchers(offer);
    setIsVoucherModalOpen(true);
    setVoucherLoading(true);
    try {
      const res = await api.get(`/offers/${offer.id}/vouchers`);
      setVoucherStats(res.data);
    } catch (err) {
      showToast("Failed to load voucher pool details", "error");
    } finally {
      setVoucherLoading(false);
    }
  };

  const handleUploadVouchers = async () => {
    if (!activeOfferForVouchers || !voucherInput.trim()) return;
    const codes = voucherInput
      .split(/[\n,]+/)
      .map(c => c.trim())
      .filter(c => c.length > 0);

    if (codes.length === 0) {
      showToast("Please enter at least one code", "error");
      return;
    }

    try {
      setVoucherLoading(true);
      const res = await api.post(`/offers/${activeOfferForVouchers.id}/vouchers/upload`, { codes });
      showToast(res.data.message || "Vouchers uploaded successfully", "success");
      setVoucherInput('');
      const updatedStats = await api.get(`/offers/${activeOfferForVouchers.id}/vouchers`);
      setVoucherStats(updatedStats.data);
      fetchOffers();
    } catch (err) {
      showToast("Failed to upload vouchers", "error");
    } finally {
      setVoucherLoading(false);
    }
  };

  // ── Export helpers ─────────────────────────────────────────────────────────
  const exportRows = offers.map((offer, i) => ({
    '#': i + 1,
    'Merchant': offer.merchant_name || '—',
    'Title': offer.title || '—',
    'Category': offer.type || '—',
    'Redemption': offer.redemption_type || 'generic_code',
    'City': offer.city ? `${offer.city}${offer.pincode ? ` (${offer.pincode})` : ''}` : 'All India',
    'Target': offer.target_professions || offer.target_stream || 'All',
    'Code/Pass': offer.discount_code || 'Dynamic/Lead',
    'Claims': `${offer.claimed_count || 0}${offer.total_quota ? ` / ${offer.total_quota}` : ''}`,
    'Valid Until': offer.valid_until ? new Date(offer.valid_until).toLocaleDateString('en-IN') : 'Ongoing',
  }));

  const exportToCSV = () => {
    if (exportRows.length === 0) return;
    const headers = Object.keys(exportRows[0]);
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'offers.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Offers');
    XLSX.writeFile(wb, 'offers.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF({ orientation: 'landscape' });
    doc.setFontSize(16);
    doc.text('Offers & Merchant Perks', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${offers.length} offers`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'Merchant', 'Title', 'Category', 'Redemption', 'Location', 'Target', 'Code/Pass', 'Claims', 'Valid Until']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [10, 102, 194], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('offers.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const getRedemptionBadge = (type: string) => {
    switch (type) {
      case 'in_store_pass':
        return <span className="px-2 py-0.5 bg-amber-500/10 text-amber-700 border border-amber-500/20 rounded-full text-xs font-medium">In-Store Pass</span>;
      case 'unique_code_pool':
        return <span className="px-2 py-0.5 bg-purple-500/10 text-purple-700 border border-purple-500/20 rounded-full text-xs font-medium">Unique Code Pool</span>;
      case 'bank_lead':
        return <span className="px-2 py-0.5 bg-emerald-500/10 text-emerald-700 border border-emerald-500/20 rounded-full text-xs font-medium">Lead Gen Form</span>;
      case 'affiliate_link':
        return <span className="px-2 py-0.5 bg-sky-500/10 text-sky-700 border border-sky-500/20 rounded-full text-xs font-medium">External Link</span>;
      default:
        return <span className="px-2 py-0.5 bg-blue-500/10 text-blue-700 border border-blue-500/20 rounded-full text-xs font-medium">Universal Code</span>;
    }
  };

  const columns: Column<Offer>[] = [
    {
      header: 'Partner & Offer',
      accessorKey: 'title',
      sortable: true,
      cell: (offer) => (
        <div className="py-1">
          <div className="flex items-center gap-2">
            <span className="font-semibold text-primaryBrand hover:underline cursor-pointer" onClick={() => openEditModal(offer)}>
              {offer.title}
            </span>
          </div>
          <div className="text-xs text-secondaryText flex items-center gap-1.5 mt-0.5">
            {offer.merchant_name && (
              <span className="font-medium text-primaryText flex items-center gap-1">
                <Building size={12} className="text-secondaryText" /> {offer.merchant_name}
              </span>
            )}
            {offer.city && (
              <span className="flex items-center gap-0.5 text-secondaryText">
                · <MapPin size={11} /> {offer.city}{offer.pincode ? ` (${offer.pincode})` : ''}
              </span>
            )}
          </div>
          <div className="text-xs text-secondaryText truncate max-w-xs mt-0.5">{offer.subtitle}</div>
        </div>
      )
    },
    {
      header: 'Category',
      accessorKey: 'type',
      sortable: true,
      cell: (offer) => (
        <span className="px-2.5 py-1 bg-primaryBrand/10 text-primaryBrand rounded-full text-xs font-medium">
          {offer.type}
        </span>
      )
    },
    {
      header: 'Redemption Type',
      accessorKey: 'redemption_type',
      sortable: true,
      cell: (offer) => getRedemptionBadge(offer.redemption_type)
    },
    {
      header: 'Inventory / Claims',
      accessorKey: 'claimed_count',
      sortable: true,
      cell: (offer) => (
        <div className="text-xs">
          <div className="font-medium text-primaryText">
            {offer.claimed_count || 0} claimed
            {offer.total_quota ? <span className="text-secondaryText font-normal"> / {offer.total_quota} max</span> : ''}
          </div>
          {offer.redemption_type === 'unique_code_pool' && (
            <div className="text-purple-600 font-medium mt-0.5 flex items-center gap-1">
              <Ticket size={11} />
              {offer.available_vouchers_count !== undefined ? `${offer.available_vouchers_count} codes left` : 'Manage pool'}
            </div>
          )}
        </div>
      )
    },
    {
      header: 'Target Professions',
      cell: (offer) => (
        <div className="text-xs text-secondaryText max-w-[180px] truncate" title={offer.target_professions || offer.target_stream || 'All'}>
          <span className="text-primaryText font-medium">{offer.target_professions || offer.target_stream || 'All'}</span>
          {offer.min_resume_score ? <div className="text-[11px] text-secondaryText">Min Resume: {offer.min_resume_score}%</div> : null}
        </div>
      )
    },
    {
      header: 'Valid Until',
      accessorKey: 'valid_until',
      sortable: true,
      cell: (offer) => (
        <span className="text-xs text-secondaryText">
          {offer.valid_until ? new Date(offer.valid_until).toLocaleDateString('en-IN') : 'Ongoing'}
        </span>
      )
    },
    {
      header: 'Actions',
      cell: (offer) => (
        <div className="flex items-center justify-end gap-2">
          {offer.redemption_type === 'unique_code_pool' && (
            <button 
              onClick={() => openVoucherModal(offer)} 
              title="Manage Voucher Codes"
              className="p-1.5 rounded-lg text-purple-600 hover:bg-purple-50 transition-colors"
            >
              <Ticket size={16} />
            </button>
          )}
          <button 
            onClick={() => openEditModal(offer)} 
            title="Edit Offer"
            className="p-1.5 rounded-lg text-secondaryText hover:text-primaryBrand hover:bg-primaryBrand/10 transition-colors"
          >
            <Edit2 size={16} />
          </button>
          <button 
            onClick={() => { setItemToDelete(offer.id); setDeleteDialogOpen(true); }} 
            title="Delete Offer"
            className="p-1.5 rounded-lg text-secondaryText hover:text-error hover:bg-red-50 transition-colors"
          >
            <Trash2 size={16} />
          </button>
        </div>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
      <div className="flex flex-wrap justify-between items-center gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Offers & Merchant Perks</h1>
          <p className="text-secondaryText text-sm mt-1">Manage discounts from local Gyms, Student Shops, Banks, Coaching, and Subscriptions.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
            {offers.length} Active Offers
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

          <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
            <Plus size={18} /> Add New Offer
          </button>
        </div>
      </div>

      <DataTable
        data={offers}
        columns={columns}
        searchPlaceholder="Search by offer, merchant, category, city..."
        searchableKeys={['title', 'subtitle', 'type', 'city', 'state', 'pincode', 'merchant_name', 'discount_code', 'target_professions']}
        loading={loading}
        emptyStateMessage="No offers found. Create your first offer."
        emptyStateIcon={<Tag size={36} className="text-border" />}
        toolbarExtras={
          <button
            onClick={() => setIsFilterOpen(true)}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-border rounded-md text-sm font-medium text-secondaryText hover:text-primaryText hover:bg-gray-50 transition-colors shadow-sm h-[42px]"
          >
            <Filter size={18} />
            <span>Filters</span>
            {activeFiltersCount > 0 && (
              <span className="w-5 h-5 bg-primaryBrand text-white text-[10px] flex items-center justify-center rounded-full font-bold">
                {activeFiltersCount}
              </span>
            )}
          </button>
        }
      />

      {/* Offer Form Modal */}
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingId ? "Edit Offer" : "Create Offer"}>
        <form onSubmit={handleSubmit} className="space-y-4 max-h-[75vh] overflow-y-auto px-1">
          
          {/* Row 1: Partner / Merchant Name | Offer Headline / Title * */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Partner / Merchant Name</label>
              <input 
                type="text" 
                className="input-field" 
                value={formData.merchant_name} 
                onChange={e => setFormData({...formData, merchant_name: e.target.value})} 
                placeholder="e.g. Gold's Gym, HDFC Bank, Allen Institute" 
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Offer Headline / Title *</label>
              <input 
                required 
                type="text" 
                className="input-field" 
                value={formData.title} 
                onChange={e => setFormData({...formData, title: e.target.value})} 
                placeholder="e.g. Flat 40% Off Annual Student Gym Pass" 
              />
            </div>
          </div>

          {/* Row 2: Subtitle / Highlight Tagline * | Offer Category * */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Subtitle / Highlight Tagline *</label>
              <input 
                required 
                type="text" 
                className="input-field" 
                value={formData.subtitle} 
                onChange={e => setFormData({...formData, subtitle: e.target.value})} 
                placeholder="e.g. Valid at FC Road branch on college ID" 
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Offer Category *</label>
              <select 
                className="input-field bg-white" 
                value={formData.type} 
                onChange={e => setFormData({...formData, type: e.target.value})}
              >
                {CATEGORIES.map(cat => <option key={cat} value={cat}>{cat}</option>)}
              </select>
            </div>
          </div>

          {/* Row 3: Redemption Mechanism * | Dynamic right side field */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Redemption Mechanism *</label>
              <select 
                className="input-field bg-white font-medium text-primaryBrand" 
                value={formData.redemption_type} 
                onChange={e => setFormData({...formData, redemption_type: e.target.value})}
              >
                {REDEMPTION_TYPES.map(rt => <option key={rt.value} value={rt.value}>{rt.label}</option>)}
              </select>
            </div>

            <div>
              {formData.redemption_type === 'unique_code_pool' ? (
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="block text-sm font-medium text-secondaryText">
                      Upload Voucher Codes
                    </label>
                    <button
                      type="button"
                      onClick={downloadSampleTemplate}
                      className="text-xs text-primaryBrand hover:underline flex items-center gap-1 font-medium"
                    >
                      <Download size={12} /> Sample Template
                    </button>
                  </div>
                  <div className="flex items-center gap-2">
                    <label className="flex-1 flex items-center justify-center gap-2 px-3 py-2 border border-dashed border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50 transition-colors bg-white text-sm">
                      <FileSpreadsheet size={16} className="text-green-600 shrink-0" />
                      <span className="text-secondaryText truncate text-xs">
                        {voucherFileName ? voucherFileName : "Upload .xlsx, .xls, .csv"}
                      </span>
                      <input
                        type="file"
                        accept=".xlsx, .xls, .csv"
                        className="hidden"
                        onChange={handleExcelUpload}
                      />
                    </label>
                    {uploadedVouchers.length > 0 && (
                      <button
                        type="button"
                        onClick={() => { setUploadedVouchers([]); setVoucherFileName(''); }}
                        className="p-1.5 text-xs text-red-500 hover:bg-red-50 rounded"
                        title="Remove file"
                      >
                        <X size={14} />
                      </button>
                    )}
                  </div>
                  {uploadedVouchers.length > 0 ? (
                    <p className="text-xs text-emerald-600 font-medium mt-1">
                      ✓ {uploadedVouchers.length} unique codes detected
                    </p>
                  ) : (
                    editingId && (
                      <p className="text-[11px] text-secondaryText mt-1">
                        Active pool has codes. Upload file to add more.
                      </p>
                    )
                  )}
                </div>
              ) : formData.redemption_type === 'affiliate_link' ? (
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">External Partner URL *</label>
                  <input 
                    required
                    type="url" 
                    className="input-field" 
                    value={formData.external_url} 
                    onChange={e => setFormData({...formData, external_url: e.target.value})} 
                    placeholder="https://partner.com/deal" 
                  />
                </div>
              ) : formData.redemption_type === 'in_store_pass' ? (
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Address (For in-person redemption) *</label>
                  <input 
                    required
                    type="text" 
                    className="input-field" 
                    value={formData.merchant_address} 
                    onChange={e => setFormData({...formData, merchant_address: e.target.value})} 
                    placeholder="e.g. 2nd Floor, Deccan Mall, FC Road, Pune" 
                  />
                </div>
              ) : formData.redemption_type === 'bank_lead' ? (
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Partner Helpline / WhatsApp *</label>
                  <input 
                    required
                    type="text" 
                    className="input-field" 
                    value={formData.partner_phone} 
                    onChange={e => setFormData({...formData, partner_phone: e.target.value})} 
                    placeholder="e.g. +91 98765 43210" 
                  />
                </div>
              ) : (
                /* default: generic_code */
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Promo Code *</label>
                  <input 
                    required
                    type="text" 
                    className="input-field font-mono uppercase" 
                    value={formData.discount_code} 
                    onChange={e => setFormData({...formData, discount_code: e.target.value.toUpperCase()})} 
                    placeholder="e.g. CAREER20, GYM50" 
                  />
                </div>
              )}
            </div>
          </div>

          {/* Row 4: Call to Action (Button Text) * | Valid Until (Expiry) */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Call to Action (Button Text) *</label>
              <input 
                required 
                type="text" 
                className="input-field" 
                value={formData.action} 
                onChange={e => setFormData({...formData, action: e.target.value})} 
                placeholder="e.g. Claim Deal, Apply for Loan, Get Pass" 
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-secondaryText mb-1">Valid Until (Expiry)</label>
              <input 
                type="date" 
                className="input-field" 
                value={formData.valid_until} 
                onChange={e => setFormData({...formData, valid_until: e.target.value})} 
              />
            </div>
          </div>

          {/* Row 5: Standardized Location (Pincode) - Compulsory */}
          <div className="border p-4 rounded-xl bg-gray-50 space-y-3">
            <div>
              <p className="text-sm font-semibold text-primaryText mb-0.5">Standardized Location (Pincode) *</p>
              <p className="text-xs text-secondaryText">Enter a 6-digit pin code to auto-fetch the city and state.</p>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Pincode *</label>
                <div className="relative">
                  <input 
                    required 
                    type="text" 
                    maxLength={6} 
                    pattern="[0-9]{6}"
                    className="input-field pr-10" 
                    value={formData.pincode || ''} 
                    onChange={handlePincodeChange} 
                    placeholder="e.g. 411004" 
                  />
                  {pincodeLoading && (
                    <div className="absolute right-3 top-2.5 w-5 h-5 border-2 border-primaryBrand border-t-transparent rounded-full animate-spin"></div>
                  )}
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Select Area *</label>
                <select 
                  required 
                  className="input-field bg-white disabled:bg-gray-100" 
                  disabled={pincodeData.length === 0}
                  value={selectedArea}
                  onChange={e => {
                    const areaName = e.target.value;
                    setSelectedArea(areaName);
                    const selected = pincodeData.find(p => p.area === areaName);
                    if (selected) {
                      setFormData(prev => ({
                        ...prev,
                        city: selected.city,
                        state: selected.state
                      }));
                    }
                  }}
                >
                  <option value="">{pincodeData.length > 0 ? "Select Area..." : (formData.pincode?.length === 6 ? "Select Area..." : "Enter 6-digit pincode first")}</option>
                  {pincodeData.map(p => (
                    <option key={p.id || p.area} value={p.area}>{p.area}</option>
                  ))}
                </select>
              </div>
            </div>
            
            <div className="grid grid-cols-2 gap-4 pt-2 border-t border-gray-200">
              <div>
                <label className="block text-xs font-medium text-secondaryText mb-1">City *</label>
                <input 
                  required
                  type="text" 
                  readOnly
                  className="input-field bg-gray-100 text-gray-700 font-medium cursor-not-allowed" 
                  value={formData.city || ''} 
                  placeholder="Auto-fetched from Pincode"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-secondaryText mb-1">State *</label>
                <input 
                  required
                  type="text" 
                  readOnly
                  className="input-field bg-gray-100 text-gray-700 font-medium cursor-not-allowed" 
                  value={formData.state || ''} 
                  placeholder="Auto-fetched from Pincode"
                />
              </div>
            </div>
          </div>

          {/* Row 6: Target Professions */}
          <div className="relative" ref={tagDropdownRef}>
            <label className="block text-sm font-medium text-secondaryText mb-1">Target Professions</label>
            <div 
              className="input-field min-h-[42px] cursor-pointer flex flex-wrap gap-2 items-center bg-white"
              onClick={() => setTagDropdownOpen(!tagDropdownOpen)}
            >
              {formData.target_professions ? (
                formData.target_professions.split(',').map(t => t.trim()).filter(Boolean).map(t => (
                  <span key={t} className="px-2 py-1 bg-highlight/10 text-highlight rounded text-xs font-medium border border-highlight/20 flex items-center gap-1">
                    {t}
                    <button 
                      type="button" 
                      onClick={(e) => { e.stopPropagation(); handleProfessionToggle(t); }}
                      className="hover:text-primaryBrand transition-colors font-bold"
                    >
                      ×
                    </button>
                  </span>
                ))
              ) : (
                <span className="text-secondaryText text-sm">All Professions (Click to select target professions...)</span>
              )}
            </div>
            {tagDropdownOpen && (
              <div className="absolute z-20 w-full mt-1 bg-white border border-border rounded-lg shadow-lg max-h-56 overflow-y-auto">
                {goals.map(goal => {
                  const option = goal.name;
                  const isSelected = formData.target_professions?.split(',').map((t: string) => t.trim()).includes(option);
                  return (
                    <div 
                      key={option}
                      className="flex items-center px-4 py-2 hover:bg-gray-50 cursor-pointer"
                      onClick={() => handleProfessionToggle(option)}
                    >
                      <input 
                        type="checkbox" 
                        checked={isSelected}
                        readOnly
                        className="mr-3 rounded text-primaryBrand focus:ring-primaryBrand"
                      />
                      <span className="text-sm text-primaryText">{option}</span>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Row 7: Full Offer Description * */}
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Full Offer Description *</label>
            <textarea 
              required 
              rows={3} 
              className="input-field" 
              value={formData.description} 
              onChange={e => setFormData({...formData, description: e.target.value})}
              placeholder="Explain the perks, discount structure, and how students benefit..."
            ></textarea>
          </div>

          {/* Row 8: Terms & Conditions / How to Redeem */}
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Terms & Conditions / How to Redeem</label>
            <textarea 
              rows={2} 
              className="input-field" 
              value={formData.terms_and_conditions} 
              onChange={e => setFormData({...formData, terms_and_conditions: e.target.value})}
              placeholder="e.g. Valid only upon showing a current College ID card. Cannot be combined with other offers."
            ></textarea>
          </div>

          {/* Form Actions */}
          <div className="flex justify-end gap-3 pt-3 border-t border-border">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium">Cancel</button>
            <button type="submit" className="btn-primary">{editingId ? 'Update Offer' : 'Save & Publish Offer'}</button>
          </div>
        </form>
      </Modal>

      {/* Unique Voucher Pool Modal */}
      <Modal 
        isOpen={isVoucherModalOpen} 
        onClose={() => setIsVoucherModalOpen(false)} 
        title={`Voucher Pool: ${activeOfferForVouchers?.title || ''}`}
      >
        <div className="space-y-4">
          <p className="text-sm text-secondaryText">
            Upload unique single-use voucher codes for this offer. When a user claims the offer, they will be given one exclusive code from this pool.
          </p>

          {voucherStats && (
            <div className="grid grid-cols-3 gap-3 p-3 bg-backgroundLight rounded-lg border border-border text-center">
              <div>
                <div className="text-xs text-secondaryText">Total Uploaded</div>
                <div className="text-lg font-bold text-primaryText">{voucherStats.total}</div>
              </div>
              <div>
                <div className="text-xs text-secondaryText">Claimed</div>
                <div className="text-lg font-bold text-primaryBrand">{voucherStats.claimed}</div>
              </div>
              <div>
                <div className="text-xs text-secondaryText">Available Left</div>
                <div className="text-lg font-bold text-emerald-600">{voucherStats.available}</div>
              </div>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-primaryText mb-1">
              Add New Voucher Codes (Paste list separated by newlines or commas)
            </label>
            <textarea 
              rows={6} 
              className="input-field font-mono text-xs" 
              value={voucherInput} 
              onChange={e => setVoucherInput(e.target.value)}
              placeholder="CULT-STUDENT-A819&#10;CULT-STUDENT-B920&#10;CULT-STUDENT-C103"
            ></textarea>
          </div>

          <div className="flex justify-between items-center pt-2">
            <span className="text-xs text-secondaryText">
              {voucherInput ? `${voucherInput.split(/[\n,]+/).filter(c => c.trim()).length} codes detected` : ''}
            </span>
            <div className="flex gap-2">
              <button 
                type="button" 
                onClick={() => setIsVoucherModalOpen(false)} 
                className="px-3 py-1.5 text-sm text-secondaryText hover:text-primaryText font-medium"
              >
                Close
              </button>
              <button 
                type="button" 
                disabled={voucherLoading || !voucherInput.trim()} 
                onClick={handleUploadVouchers} 
                className="btn-primary flex items-center gap-2 text-sm"
              >
                <Plus size={16} /> Upload Codes to Pool
              </button>
            </div>
          </div>
        </div>
      </Modal>

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Offer" 
        message="Are you sure you want to delete this offer? This action cannot be undone." 
      />

      {/* Filters Side Drawer */}
      {isFilterOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="absolute inset-0 bg-black/40 animate-fade-in" onClick={() => setIsFilterOpen(false)}></div>
          <div className="relative w-84 max-w-full bg-white h-full shadow-2xl flex flex-col z-10 animate-slide-in-right">
            <div className="flex justify-between items-center p-4 border-b border-border">
              <div className="flex items-center gap-2">
                <Filter size={18} className="text-primaryBrand" />
                <h2 className="text-lg font-bold text-primaryText">Filter Offers</h2>
              </div>
              <button 
                onClick={() => setIsFilterOpen(false)} 
                className="text-secondaryText hover:text-primaryText p-1 rounded-md hover:bg-gray-100 transition-colors"
              >
                <X size={20} />
              </button>
            </div>

            <div className="p-4 flex-1 overflow-y-auto space-y-5">
              {/* 1. City (Location) */}
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">City (Location)</label>
                <div className="relative">
                  <select
                    value={filterCity}
                    onChange={(e) => setFilterCity(e.target.value)}
                    className="input-field bg-white appearance-none w-full pr-8"
                  >
                    <option value="All">All Cities</option>
                    {cities.map((city) => (
                      <option key={city} value={city}>{city}</option>
                    ))}
                  </select>
                  <ChevronDown className="absolute right-3 top-3 text-gray-400 pointer-events-none" size={16} />
                </div>
              </div>

              {/* 2. Select Category */}
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Select Category</label>
                <div className="relative">
                  <select
                    value={filterCategory}
                    onChange={(e) => setFilterCategory(e.target.value)}
                    className="input-field bg-white appearance-none w-full pr-8"
                  >
                    <option value="All">All Categories</option>
                    {CATEGORIES.map(cat => (
                      <option key={cat} value={cat}>{cat}</option>
                    ))}
                  </select>
                  <ChevronDown className="absolute right-3 top-3 text-gray-400 pointer-events-none" size={16} />
                </div>
              </div>

              {/* 3. Select Redemption Type */}
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Select Redemption Type</label>
                <div className="relative">
                  <select
                    value={filterRedemptionType}
                    onChange={(e) => setFilterRedemptionType(e.target.value)}
                    className="input-field bg-white appearance-none w-full pr-8"
                  >
                    <option value="All">All Redemption Types</option>
                    {REDEMPTION_TYPES.map(rt => (
                      <option key={rt.value} value={rt.value}>{rt.label}</option>
                    ))}
                  </select>
                  <ChevronDown className="absolute right-3 top-3 text-gray-400 pointer-events-none" size={16} />
                </div>
              </div>

              {/* 4. Select Profession (Multi-select) */}
              <div>
                <div className="flex items-center justify-between mb-1">
                  <label className="block text-sm font-medium text-secondaryText">
                    Select Profession {filterProfessions.length > 0 && `(${filterProfessions.length})`}
                  </label>
                  {filterProfessions.length > 0 && (
                    <button
                      type="button"
                      onClick={() => setFilterProfessions([])}
                      className="text-xs text-primaryBrand hover:underline font-medium"
                    >
                      Clear
                    </button>
                  )}
                </div>
                <div className="border border-border rounded-lg max-h-48 overflow-y-auto p-2 bg-gray-50/50 space-y-1">
                  {goals.length === 0 ? (
                    <p className="text-xs text-secondaryText p-2">Loading professions from backend...</p>
                  ) : (
                    goals.map((g) => {
                      const isSelected = filterProfessions.includes(g.name);
                      return (
                        <label
                          key={g.id || g.name}
                          className="flex items-center gap-2.5 px-2.5 py-1.5 rounded-md hover:bg-white cursor-pointer transition-colors text-sm"
                        >
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => {
                              if (isSelected) {
                                setFilterProfessions(filterProfessions.filter(p => p !== g.name));
                              } else {
                                setFilterProfessions([...filterProfessions, g.name]);
                              }
                            }}
                            className="rounded text-primaryBrand focus:ring-primaryBrand"
                          />
                          <span className={`text-xs ${isSelected ? 'font-semibold text-primaryBrand' : 'text-primaryText'}`}>
                            {g.name}
                          </span>
                        </label>
                      );
                    })
                  )}
                </div>
              </div>

              {/* 4. Validity Upto Date */}
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Validity Upto Date</label>
                <input
                  type="date"
                  className="input-field bg-white"
                  value={filterValidityUpto}
                  onChange={(e) => setFilterValidityUpto(e.target.value)}
                />
                <p className="text-[11px] text-secondaryText mt-1">Shows active offers valid through this date.</p>
              </div>
            </div>

            {/* Side Drawer Footer */}
            <div className="p-4 border-t border-border flex justify-end gap-3 bg-white">
              <button
                type="button"
                onClick={handleClearFilters}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 font-medium text-sm transition-colors"
              >
                Clear Filters
              </button>
              <button
                type="button"
                onClick={handleApplyFilters}
                className="btn-primary text-sm px-5"
              >
                Apply
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Offers;
