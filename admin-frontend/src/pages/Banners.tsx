import { useState, useEffect, useRef } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, Search, Info } from 'lucide-react';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import ReactCrop, { type Crop, type PixelCrop, centerCrop, makeAspectCrop } from 'react-image-crop';
import 'react-image-crop/dist/ReactCrop.css';

interface Banner {
  id: string;
  image_url: string;
  link_url: string;
}

const defaultFormData = {
  image_url: '', link_url: ''
};

const Banners = () => {
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

  useEffect(() => {
    fetchBanners();
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
      setCrop(undefined);
      const reader = new FileReader();
      reader.addEventListener('load', () => setImgSrc(reader.result?.toString() || ''));
      reader.readAsDataURL(e.target.files[0]);
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

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Marketing Banners</h1>
          <p className="text-secondaryText">Manage banners shown on the mobile app home screen.</p>
        </div>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add Banner
        </button>
      </div>

      <div className="card">
        <div className="p-4 border-b border-border flex justify-between items-center bg-gray-50/50">
          <div className="relative w-72">
            <Search className="absolute left-3 top-2.5 text-borderDark" size={18} />
            <input type="text" placeholder="Search banners..." className="input-field pl-10 bg-white" />
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border text-sm text-secondaryText">
                <th className="p-4 font-medium w-32">Preview</th>
                <th className="p-4 font-medium">Link URL</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={3} className="text-center p-8 text-secondaryText">Loading banners...</td></tr>
              ) : banners.length === 0 ? (
                <tr><td colSpan={3} className="text-center p-8 text-secondaryText">No banners found.</td></tr>
              ) : (
                banners.map((banner) => (
                  <tr key={banner.id} className="border-b border-border hover:bg-gray-50/50 transition-colors">
                    <td className="p-4">
                      <div className="w-24 h-12 bg-gray-200 rounded overflow-hidden">
                        <img src={banner.image_url} alt="Banner" className="w-full h-full object-cover" onError={(e) => (e.currentTarget.style.display = 'none')} />
                      </div>
                    </td>
                    <td className="p-4 text-primaryText truncate max-w-xs"><a href={banner.link_url} target="_blank" rel="noreferrer" className="text-primaryBrand hover:underline">{banner.link_url}</a></td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button onClick={() => openEditModal(banner)} className="text-secondaryText hover:text-primaryBrand transition-colors"><Edit2 size={16} /></button>
                        <button onClick={() => { setItemToDelete(banner.id); setDeleteDialogOpen(true); }} className="text-secondaryText hover:text-error transition-colors"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal isOpen={isModalOpen} onClose={handleCancelModal} title={editingId ? "Edit Banner" : "Add New Banner"}>
        <div className="bg-blue-50 text-blue-800 p-3 rounded-lg mb-4 flex items-start gap-2 text-sm border border-blue-100">
          <Info size={16} className="mt-0.5 flex-shrink-0" />
          <p>For the best display in the mobile app, upload images with an approximate <strong>2:1 aspect ratio</strong> (e.g. 800x400 pixels).</p>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Banner Image</label>
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
