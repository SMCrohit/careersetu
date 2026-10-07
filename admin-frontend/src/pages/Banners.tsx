import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Info, Download, ChevronDown, FileText, FileSpreadsheet, FileDown, Image } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import ReactCrop, { type Crop, type PixelCrop, centerCrop, makeAspectCrop } from 'react-image-crop';
import 'react-image-crop/dist/ReactCrop.css';
import { DataTable, type Column } from '../components/DataTable';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

interface Banner {
  id: string;
  image_url: string;
  link_url: string;
}

const defaultFormData = {
  image_url: '', link_url: ''
};

const Banners = ({ isSettingsTab = false }: { isSettingsTab?: boolean }) => {
  const { showToast } = useToast();
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState(defaultFormData);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<string | null>(null);

  // Crop states
  const [imgSrc, setImgSrc] = useState('');
  const imgRef = useRef<HTMLImageElement>(null);
  const [crop, setCrop] = useState<Crop>();
  const [completedCrop, setCompletedCrop] = useState<PixelCrop>();

  const [exportOpen, setExportOpen] = useState(false);
  const exportRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchBanners();
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

  const fetchBanners = async () => {
    try {
      const res = await api.get('/banners');
      setBanners(res.data);
    } catch (error) {
      showToast("Failed to fetch banners", "error");
    } finally {
      setLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!itemToDelete) return;
    try {
      await api.delete(`/banners/${itemToDelete}`);
      setBanners(banners.filter(b => b.id !== itemToDelete));
      showToast("Banner deleted successfully", "success");
    } catch (error) {
      showToast("Failed to delete banner", "error");
    }
    setItemToDelete(null);
  };

  const openEditModal = (banner: Banner) => {
    setFormData({
      image_url: banner.image_url,
      link_url: banner.link_url,
    });
    setEditingId(banner.id);
    setIsModalOpen(true);
  };

  const openAddModal = () => {
    setFormData(defaultFormData);
    setEditingId(null);
    setIsModalOpen(true);
  };

  const handleCancelModal = () => {
    setIsModalOpen(false);
    setImgSrc('');
  };

  const onSelectFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];
      if (file.size > 5 * 1024 * 1024) {
        showToast("Image must be less than 5MB", "error");
        e.target.value = '';
        return;
      }
      setCrop(undefined);
      const reader = new FileReader();
      reader.addEventListener('load', () => setImgSrc(reader.result?.toString() || ''));
      reader.readAsDataURL(file);
    }
  };

  const onImageLoad = (e: React.SyntheticEvent<HTMLImageElement>) => {
    const { width, height } = e.currentTarget;
    const initialCrop = centerCrop(
      makeAspectCrop({ unit: '%', width: 90 }, 2 / 1, width, height),
      width,
      height
    );
    setCrop(initialCrop);
  };

  const getCroppedImg = async () => {
    const image = imgRef.current;
    if (!image || !completedCrop) return;

    const canvas = document.createElement('canvas');
    const scaleX = image.naturalWidth / image.width;
    const scaleY = image.naturalHeight / image.height;
    canvas.width = completedCrop.width;
    canvas.height = completedCrop.height;
    const ctx = canvas.getContext('2d');
    
    if (!ctx) {
      throw new Error('No 2d context');
    }

    const pixelRatio = window.devicePixelRatio;
    canvas.width = completedCrop.width * pixelRatio;
    canvas.height = completedCrop.height * pixelRatio;
    ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
    ctx.imageSmoothingQuality = 'high';

    ctx.drawImage(
      image,
      completedCrop.x * scaleX,
      completedCrop.y * scaleY,
      completedCrop.width * scaleX,
      completedCrop.height * scaleY,
      0,
      0,
      completedCrop.width,
      completedCrop.height
    );

    return new Promise<void>((resolve) => {
      canvas.toBlob((blob) => {
        if (!blob) return;
        const reader = new FileReader();
        reader.readAsDataURL(blob);
        reader.onloadend = () => {
          setFormData({ ...formData, image_url: reader.result as string });
          setImgSrc(''); // Reset crop UI
          resolve();
        };
      }, 'image/jpeg', 0.9);
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.image_url) {
      showToast("Please upload an image for the banner", "error");
      return;
    }
    try {
      if (editingId) {
        const res = await api.put(`/banners/${editingId}`, formData);
        setBanners(banners.map(b => b.id === editingId ? res.data : b));
        showToast("Banner updated successfully", "success");
      } else {
        const res = await api.post('/banners', formData);
        setBanners([res.data, ...banners]);
        showToast("Banner created successfully", "success");
      }
      setIsModalOpen(false);
      setFormData(defaultFormData);
      setEditingId(null);
    } catch (error) {
      showToast(`Failed to ${editingId ? 'update' : 'create'} banner`, "error");
    }
  };

  // ── Export helpers ─────────────────────────────────────────────────────────
  const exportRows = banners.map((banner, i) => ({
    '#': i + 1,
    'Banner Image URL': banner.image_url || '—',
    'Link URL': banner.link_url || '—',
  }));

  const exportToCSV = () => {
    if (exportRows.length === 0) return;
    const headers = Object.keys(exportRows[0]);
    const rows = exportRows.map((r) => headers.map((h) => `"${(r as any)[h]}"`).join(','));
    const csv = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'banners.csv'; a.click();
    URL.revokeObjectURL(url);
    setExportOpen(false);
    showToast('CSV exported successfully', 'success');
  };

  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(exportRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Banners');
    XLSX.writeFile(wb, 'banners.xlsx');
    setExportOpen(false);
    showToast('Excel exported successfully', 'success');
  };

  const exportToPDF = () => {
    const doc = new jsPDF();
    doc.setFontSize(16);
    doc.text('Marketing Banners', 14, 15);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Exported on ${new Date().toLocaleDateString('en-IN')} · Total: ${banners.length} banners`, 14, 22);
    autoTable(doc, {
      startY: 28,
      head: [['#', 'Banner Image URL', 'Link URL']],
      body: exportRows.map((r) => Object.values(r)),
      styles: { fontSize: 8, cellPadding: 3 },
      headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [248, 248, 255] },
    });
    doc.save('banners.pdf');
    setExportOpen(false);
    showToast('PDF exported successfully', 'success');
  };

  const columns: Column<Banner>[] = [
    {
      header: 'Preview',
      cell: (banner) => (
        <div className="w-24 h-12 bg-gray-200 rounded overflow-hidden shrink-0">
          <img src={banner.image_url} alt="Banner" className="w-full h-full object-cover" onError={(e) => (e.currentTarget.style.display = 'none')} />
        </div>
      )
    },
    {
      header: 'Link URL',
      accessorKey: 'link_url', // enable search
      sortable: true,
      cell: (banner) => (
        <a href={banner.link_url} target="_blank" rel="noreferrer" className="text-primaryBrand hover:underline truncate max-w-xs block">
          {banner.link_url}
        </a>
      )
    },
    {
      header: 'Actions',
      cell: (banner) => (
        <div className="flex items-center justify-end gap-3" onClick={e => e.stopPropagation()}>
          <button onClick={() => openEditModal(banner)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
          <button onClick={() => { setItemToDelete(banner.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
        </div>
      )
    }
  ];

  return (
    <div className="animate-fade-in">
      <div className={`flex flex-wrap items-center justify-between gap-4 ${isSettingsTab ? 'mb-4' : 'mb-8'}`}>
        {isSettingsTab ? (
          <h2 className="text-xl font-semibold text-primaryText">Home Banners</h2>
        ) : (
          <div>
            <h1 className="text-2xl font-bold text-primaryText">Marketing Banners</h1>
            <p className="text-secondaryText">Manage banners shown on the mobile app home screen.</p>
          </div>
        )}
        
        <div className="flex items-center gap-3">
          {!isSettingsTab && (
            <>
              <div className="bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
                {banners.length} Banners
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
            </>
          )}

          <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
            <Plus size={18} /> Add Banner
          </button>
        </div>
      </div>

      {isSettingsTab ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {banners.map((banner) => (
            <div key={banner.id} className="card p-4 flex flex-col gap-3 group relative overflow-hidden">
              <div className="w-full aspect-[2/1] bg-gray-100 rounded overflow-hidden">
                <img src={banner.image_url} alt="Banner" className="w-full h-full object-cover" onError={(e) => (e.currentTarget.style.display = 'none')} />
              </div>
              <a href={banner.link_url} target="_blank" rel="noreferrer" className="text-xs text-primaryBrand hover:underline truncate block">
                {banner.link_url}
              </a>
              <button 
                onClick={() => { setItemToDelete(banner.id); setDeleteDialogOpen(true); }}
                className="absolute top-2 right-2 bg-white text-error opacity-0 group-hover:opacity-100 transition-opacity p-2 hover:bg-error/10 rounded-full shadow-sm border border-gray-100"
              >
                <Trash2 size={16} />
              </button>
            </div>
          ))}
          {banners.length === 0 && !loading && (
            <div className="col-span-full py-12 text-center text-secondaryText flex flex-col items-center">
              <Image size={36} className="text-border mb-3" />
              <p>No banners found.</p>
            </div>
          )}
        </div>
      ) : (
        <DataTable
          data={banners}
          columns={columns}
          searchPlaceholder="Search banners by URL..."
          searchableKeys={['link_url']}
          loading={loading}
          emptyStateMessage="No banners found."
          emptyStateIcon={<Image size={36} className="text-border" />}
          onRowClick={openEditModal}
        />
      )}

      <Modal isOpen={isModalOpen} onClose={handleCancelModal} title={editingId ? "Edit Banner" : "Add New Banner"}>
        <div className="bg-blue-50 text-blue-800 p-3 rounded-lg mb-4 flex items-start gap-2 text-sm border border-blue-100">
          <Info size={16} className="mt-0.5 flex-shrink-0" />
          <p>For the best display in the mobile app, upload images with an approximate <strong>2:1 aspect ratio</strong> (e.g. 800x400 pixels).</p>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Banner Image (Max 5MB)</label>
            {!imgSrc && (
              <input 
                type="file" 
                accept="image/*" 
                onChange={onSelectFile} 
                className="text-sm text-secondaryText file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:bg-primaryBrand/10 file:text-primaryBrand hover:file:bg-primaryBrand/20 cursor-pointer w-full" 
              />
            )}
            
            {imgSrc && (
              <div className="mt-2 border rounded p-2 bg-gray-50 flex flex-col items-center">
                <ReactCrop
                  crop={crop}
                  onChange={(_, percentCrop) => setCrop(percentCrop)}
                  onComplete={(c) => setCompletedCrop(c)}
                  aspect={2 / 1}
                >
                  <img
                    ref={imgRef}
                    alt="Crop me"
                    src={imgSrc}
                    onLoad={onImageLoad}
                    className="max-h-64 object-contain"
                  />
                </ReactCrop>
                <div className="flex gap-2 mt-4">
                  <button type="button" onClick={() => setImgSrc('')} className="px-3 py-1 text-sm bg-gray-200 rounded">Cancel Crop</button>
                  <button type="button" onClick={getCroppedImg} className="px-3 py-1 text-sm bg-primaryBrand text-white rounded">Apply Crop</button>
                </div>
              </div>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Link / Destination URL</label>
            <input required type="url" className="input-field" value={formData.link_url} onChange={e => setFormData({...formData, link_url: e.target.value})} placeholder="https://example.com" />
          </div>
          {formData.image_url && !imgSrc && (
             <div className="mt-4">
               <div className="flex justify-between items-center mb-2">
                 <label className="block text-sm font-medium text-secondaryText">Preview</label>
                 <button type="button" onClick={() => setFormData({...formData, image_url: ''})} className="text-xs text-error hover:underline">Remove Image</button>
               </div>
               <div className="w-full aspect-[2/1] bg-gray-100 rounded-lg overflow-hidden border border-border flex items-center justify-center">
                 <img src={formData.image_url} alt="Preview" className="w-full h-full object-cover" onError={(e) => { e.currentTarget.style.display = 'none'; }} />
               </div>
             </div>
          )}
          <div className="flex justify-end gap-3 mt-6">
            <button type="button" onClick={handleCancelModal} className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium">Cancel</button>
            <button type="submit" disabled={!!imgSrc} className="btn-primary disabled:opacity-50">{editingId ? 'Update Banner' : 'Save Banner'}</button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDelete} 
        title="Delete Banner" 
        message="Are you sure you want to permanently delete this banner? This action cannot be undone." 
      />
    </div>
  );
};

export default Banners;
