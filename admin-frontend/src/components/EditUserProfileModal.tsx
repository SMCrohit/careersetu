import React, { useState, useEffect, useRef } from 'react';
import { 
  X, User, Phone, Mail, MapPin, Target, Briefcase, 
  Link, Globe, Calendar, Lock, Camera, Upload, Trash2, Check
} from 'lucide-react';
import ReactCrop, { type Crop, type PixelCrop, centerCrop, makeAspectCrop } from 'react-image-crop';
import 'react-image-crop/dist/ReactCrop.css';
import api from '../api/axios';
import { useToast } from '../context/ToastContext';

interface EditUserProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: any;
  onSuccess: () => void;
}

const EditUserProfileModal: React.FC<EditUserProfileModalProps> = ({
  isOpen,
  onClose,
  user,
  onSuccess
}) => {
  const { showToast } = useToast();
  const [activeTab, setActiveTab] = useState<'personal' | 'location' | 'career' | 'skills_links'>('personal');
  const [saving, setSaving] = useState(false);

  // Crop states
  const [imgSrc, setImgSrc] = useState('');
  const imgRef = useRef<HTMLImageElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [crop, setCrop] = useState<Crop>();
  const [completedCrop, setCompletedCrop] = useState<PixelCrop>();

  // Form state
  const [formData, setFormData] = useState({
    full_name: '',
    mobile_number: '',
    email: '',
    whatsapp_number: '',
    dob: '',
    gender: '',
    marital_status: '',
    profile_image_url: '',
    // Location
    address: '',
    city: '',
    state: '',
    pincode: '',
    country: 'India',
    // Career
    goal: '',
    summary: '',
    years_of_experience: '',
    current_salary: '',
    expected_salary: '',
    notice_period_days: '',
    willing_to_relocate: false,
    // Skills & Links
    skillsInput: '',
    languagesInput: '',
    hobbiesInput: '',
    linkedin_url: '',
    github_url: '',
    portfolio_url: '',
  });

  useEffect(() => {
    if (user && isOpen) {
      setFormData({
        full_name: user.full_name || '',
        mobile_number: user.mobile_number || '',
        email: user.email || '',
        whatsapp_number: user.whatsapp_number || '',
        dob: user.dob ? user.dob.split('T')[0] : '',
        gender: user.gender || '',
        marital_status: user.marital_status || '',
        profile_image_url: user.profile_image_url || '',
        address: user.address || '',
        city: user.city || '',
        state: user.state || '',
        pincode: user.pincode || '',
        country: user.country || 'India',
        goal: user.goal?.name || (typeof user.goal === 'string' ? user.goal : ''),
        summary: user.summary || '',
        years_of_experience: user.years_of_experience !== null && user.years_of_experience !== undefined ? String(user.years_of_experience) : '',
        current_salary: user.current_salary !== null && user.current_salary !== undefined ? String(user.current_salary) : '',
        expected_salary: user.expected_salary !== null && user.expected_salary !== undefined ? String(user.expected_salary) : '',
        notice_period_days: user.notice_period_days !== null && user.notice_period_days !== undefined ? String(user.notice_period_days) : '',
        willing_to_relocate: Boolean(user.willing_to_relocate),
        skillsInput: Array.isArray(user.skills) ? user.skills.join(', ') : (user.skills || ''),
        languagesInput: Array.isArray(user.languages) ? user.languages.join(', ') : (user.languages || ''),
        hobbiesInput: Array.isArray(user.hobbies) ? user.hobbies.join(', ') : (user.hobbies || ''),
        linkedin_url: user.linkedin_url || '',
        github_url: user.github_url || '',
        portfolio_url: user.portfolio_url || '',
      });
      setActiveTab('personal');
      setImgSrc('');
    }
  }, [user, isOpen]);

  if (!isOpen) return null;

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    if (type === 'checkbox') {
      const checked = (e.target as HTMLInputElement).checked;
      setFormData(prev => ({ ...prev, [name]: checked }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
  };

  const parseList = (str: string): string[] => {
    return str
      .split(',')
      .map(s => s.trim())
      .filter(Boolean);
  };

  // Image Selection & Crop handling
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
      makeAspectCrop({ unit: '%', width: 80 }, 1, width, height),
      width,
      height
    );
    setCrop(initialCrop);
  };

  const handleApplyCrop = () => {
    const image = imgRef.current;
    if (!image || !completedCrop) {
      showToast("Please adjust your crop area first", "error");
      return;
    }

    const canvas = document.createElement('canvas');
    const scaleX = image.naturalWidth / image.width;
    const scaleY = image.naturalHeight / image.height;

    // Standard profile avatar dimension (max 400x400 for crisp rendering without bloating payload)
    const targetDim = Math.min(400, Math.max(150, Math.round(completedCrop.width * scaleX)));
    canvas.width = targetDim;
    canvas.height = targetDim;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(
      image,
      completedCrop.x * scaleX,
      completedCrop.y * scaleY,
      completedCrop.width * scaleX,
      completedCrop.height * scaleY,
      0,
      0,
      targetDim,
      targetDim
    );

    const croppedBase64 = canvas.toDataURL('image/jpeg', 0.88);
    setFormData(prev => ({ ...prev, profile_image_url: croppedBase64 }));
    setImgSrc('');
    if (fileInputRef.current) fileInputRef.current.value = '';
    showToast("Profile image cropped successfully", "success");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);

    try {
      // NOTE: mobile_number is purposely omitted/read-only to prevent editing
      const payload: any = {
        full_name: formData.full_name.trim(),
        email: formData.email.trim() || null,
        whatsapp_number: formData.whatsapp_number.trim() || null,
        dob: formData.dob || null,
        gender: formData.gender || null,
        marital_status: formData.marital_status || null,
        profile_image_url: formData.profile_image_url || null,
        address: formData.address.trim() || null,
        city: formData.city.trim() || null,
        state: formData.state.trim() || null,
        pincode: formData.pincode.trim() || null,
        country: formData.country.trim() || 'India',
        goal: formData.goal.trim() || null,
        summary: formData.summary.trim() || null,
        years_of_experience: formData.years_of_experience === '' ? null : Number(formData.years_of_experience),
        current_salary: formData.current_salary === '' ? null : Number(formData.current_salary),
        expected_salary: formData.expected_salary === '' ? null : Number(formData.expected_salary),
        notice_period_days: formData.notice_period_days === '' ? null : Number(formData.notice_period_days),
        willing_to_relocate: formData.willing_to_relocate,
        skills: parseList(formData.skillsInput),
        languages: parseList(formData.languagesInput),
        hobbies: parseList(formData.hobbiesInput),
        linkedin_url: formData.linkedin_url.trim() || null,
        github_url: formData.github_url.trim() || null,
        portfolio_url: formData.portfolio_url.trim() || null,
      };

      await api.put(`/users/${user.id}/profile`, payload);
      showToast("Profile updated successfully", "success");
      onSuccess();
      onClose();
    } catch (err: any) {
      const errMsg = err?.response?.data?.detail || "Failed to update user profile";
      showToast(errMsg, "error");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 animate-fade-in">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-3xl max-h-[92vh] flex flex-col overflow-hidden animate-slide-up">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex justify-between items-center bg-gradient-to-r from-gray-50 to-white">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Edit Student Profile</h2>
            <p className="text-xs text-gray-500 mt-0.5">Update personal, professional, and career details for {user.full_name || 'User'}</p>
          </div>
          <button 
            type="button"
            onClick={onClose}
            className="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-full transition"
          >
            <X size={20} />
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="flex border-b border-gray-200 bg-gray-50/50 px-6 gap-2 overflow-x-auto text-sm font-semibold">
          <button
            type="button"
            onClick={() => setActiveTab('personal')}
            className={`py-3 px-3 border-b-2 flex items-center gap-1.5 transition whitespace-nowrap ${
              activeTab === 'personal'
                ? 'border-primaryBrand text-primaryBrand font-bold'
                : 'border-transparent text-gray-500 hover:text-gray-800'
            }`}
          >
            <User size={15} /> Personal
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('location')}
            className={`py-3 px-3 border-b-2 flex items-center gap-1.5 transition whitespace-nowrap ${
              activeTab === 'location'
                ? 'border-primaryBrand text-primaryBrand font-bold'
                : 'border-transparent text-gray-500 hover:text-gray-800'
            }`}
          >
            <MapPin size={15} /> Location
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('career')}
            className={`py-3 px-3 border-b-2 flex items-center gap-1.5 transition whitespace-nowrap ${
              activeTab === 'career'
                ? 'border-primaryBrand text-primaryBrand font-bold'
                : 'border-transparent text-gray-500 hover:text-gray-800'
            }`}
          >
            <Briefcase size={15} /> Career & CTC
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('skills_links')}
            className={`py-3 px-3 border-b-2 flex items-center gap-1.5 transition whitespace-nowrap ${
              activeTab === 'skills_links'
                ? 'border-primaryBrand text-primaryBrand font-bold'
                : 'border-transparent text-gray-500 hover:text-gray-800'
            }`}
          >
            <Target size={15} /> Skills & Links
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* TAB 1: PERSONAL */}
          {activeTab === 'personal' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              
              {/* Profile Image Avatar with Edit/Crop Action */}
              <div className="md:col-span-2 flex flex-col sm:flex-row items-center gap-5 p-4 bg-gray-50/80 border border-gray-200/80 rounded-xl mb-2">
                <div 
                  className="relative group cursor-pointer"
                  onClick={() => fileInputRef.current?.click()}
                  title="Click to change profile picture"
                >
                  {formData.profile_image_url ? (
                    <img
                      src={formData.profile_image_url}
                      alt="Candidate Profile"
                      className="w-24 h-24 rounded-full object-cover border-4 border-white shadow-md group-hover:opacity-90 transition"
                    />
                  ) : (
                    <div className="w-24 h-24 rounded-full bg-primaryBrand/10 text-primaryBrand flex items-center justify-center border-4 border-white shadow-md">
                      <User size={40} />
                    </div>
                  )}

                  {/* Edit Floating Camera Icon Button */}
                  <button
                    type="button"
                    className="absolute bottom-0 right-0 p-2 bg-primaryBrand text-white rounded-full shadow-lg hover:bg-blue-700 transition transform hover:scale-105"
                    title="Upload & Crop Profile Picture"
                    onClick={(e) => {
                      e.stopPropagation();
                      fileInputRef.current?.click();
                    }}
                  >
                    <Camera size={14} />
                  </button>
                </div>

                <div className="flex-1 text-center sm:text-left space-y-1">
                  <h4 className="text-sm font-bold text-gray-900">Profile Picture</h4>
                  <p className="text-xs text-gray-500">
                    Click the photo or button below to upload a photo, adjust crop area (1:1), and set avatar.
                  </p>
                  <div className="flex items-center justify-center sm:justify-start gap-2 pt-1.5">
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-white border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-50 transition shadow-xs"
                    >
                      <Upload size={13} className="text-primaryBrand" />
                      Select & Crop Photo
                    </button>
                    {formData.profile_image_url && (
                      <button
                        type="button"
                        onClick={() => setFormData(prev => ({ ...prev, profile_image_url: '' }))}
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs text-red-600 hover:bg-red-50 rounded-lg transition"
                      >
                        <Trash2 size={13} />
                        Remove
                      </button>
                    )}
                  </div>
                </div>

                {/* Hidden File Input */}
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={onSelectFile}
                />
              </div>

              {/* Full Name */}
              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Full Name <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <User size={16} className="absolute left-3 top-3 text-gray-400" />
                  <input
                    type="text"
                    name="full_name"
                    required
                    value={formData.full_name}
                    onChange={handleChange}
                    placeholder="e.g. Vaishali Sharma"
                    className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>
              </div>

              {/* Mobile Number (Read-Only - Not Editable) */}
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider">
                    Mobile Number
                  </label>
                  <span className="text-[11px] text-gray-400 flex items-center gap-1 font-medium">
                    <Lock size={11} /> Read-only
                  </span>
                </div>
                <div className="relative">
                  <Phone size={16} className="absolute left-3 top-2.5 text-gray-400" />
                  <input
                    type="text"
                    name="mobile_number"
                    readOnly
                    disabled
                    value={formData.mobile_number}
                    className="w-full pl-9 pr-9 py-2 border border-gray-200 bg-gray-100/80 text-gray-500 rounded-lg text-sm cursor-not-allowed select-none font-medium"
                    title="Mobile number is the primary account identifier and cannot be modified"
                  />
                  <Lock size={14} className="absolute right-3 top-3 text-gray-400" />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Email Address
                </label>
                <div className="relative">
                  <Mail size={16} className="absolute left-3 top-3 text-gray-400" />
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    placeholder="user@example.com"
                    className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  WhatsApp Number
                </label>
                <div className="relative">
                  <Phone size={16} className="absolute left-3 top-3 text-gray-400" />
                  <input
                    type="text"
                    name="whatsapp_number"
                    value={formData.whatsapp_number}
                    onChange={handleChange}
                    placeholder="e.g. 9876543210"
                    className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Date of Birth
                </label>
                <div className="relative">
                  <Calendar size={16} className="absolute left-3 top-3 text-gray-400" />
                  <input
                    type="date"
                    name="dob"
                    value={formData.dob}
                    onChange={handleChange}
                    className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Gender
                </label>
                <select
                  name="gender"
                  value={formData.gender}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none bg-white"
                >
                  <option value="">Select Gender</option>
                  <option value="Male">Male</option>
                  <option value="Female">Female</option>
                  <option value="Other">Other</option>
                  <option value="Prefer not to say">Prefer not to say</option>
                </select>
              </div>

              <div className="md:col-span-2">
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Marital Status
                </label>
                <select
                  name="marital_status"
                  value={formData.marital_status}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none bg-white"
                >
                  <option value="">Select Status</option>
                  <option value="Single">Single</option>
                  <option value="Married">Married</option>
                  <option value="Other">Other</option>
                </select>
              </div>
            </div>
          )}

          {/* TAB 2: LOCATION */}
          {activeTab === 'location' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="md:col-span-2">
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Street Address
                </label>
                <input
                  type="text"
                  name="address"
                  value={formData.address}
                  onChange={handleChange}
                  placeholder="e.g. Flat 402, Green Avenue"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  City
                </label>
                <div className="relative">
                  <MapPin size={16} className="absolute left-3 top-3 text-gray-400" />
                  <input
                    type="text"
                    name="city"
                    value={formData.city}
                    onChange={handleChange}
                    placeholder="e.g. Raipur"
                    className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  State
                </label>
                <input
                  type="text"
                  name="state"
                  value={formData.state}
                  onChange={handleChange}
                  placeholder="e.g. Chhattisgarh"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Pincode
                </label>
                <input
                  type="text"
                  name="pincode"
                  value={formData.pincode}
                  onChange={handleChange}
                  placeholder="e.g. 492001"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Country
                </label>
                <input
                  type="text"
                  name="country"
                  value={formData.country}
                  onChange={handleChange}
                  placeholder="India"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                />
              </div>
            </div>
          )}

          {/* TAB 3: CAREER & COMPENSATION */}
          {activeTab === 'career' && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                    Career Goal / Designation
                  </label>
                  <div className="relative">
                    <Target size={16} className="absolute left-3 top-3 text-gray-400" />
                    <input
                      type="text"
                      name="goal"
                      value={formData.goal}
                      onChange={handleChange}
                      placeholder="e.g. Software Engineer, Data Scientist"
                      className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                    Total Experience (Years)
                  </label>
                  <input
                    type="number"
                    step="0.5"
                    min="0"
                    name="years_of_experience"
                    value={formData.years_of_experience}
                    onChange={handleChange}
                    placeholder="e.g. 3.5"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                    Current Salary (₹ LPA)
                  </label>
                  <input
                    type="number"
                    min="0"
                    name="current_salary"
                    value={formData.current_salary}
                    onChange={handleChange}
                    placeholder="e.g. 450000"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                    Expected Salary (₹ LPA)
                  </label>
                  <input
                    type="number"
                    min="0"
                    name="expected_salary"
                    value={formData.expected_salary}
                    onChange={handleChange}
                    placeholder="e.g. 600000"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                    Notice Period (Days)
                  </label>
                  <input
                    type="number"
                    min="0"
                    name="notice_period_days"
                    value={formData.notice_period_days}
                    onChange={handleChange}
                    placeholder="e.g. 30"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                  />
                </div>

                <div className="flex items-center pt-6">
                  <label className="flex items-center gap-2 cursor-pointer select-none text-sm text-gray-700 font-medium">
                    <input
                      type="checkbox"
                      name="willing_to_relocate"
                      checked={formData.willing_to_relocate}
                      onChange={handleChange}
                      className="w-4 h-4 text-primaryBrand rounded border-gray-300 focus:ring-primaryBrand"
                    />
                    <span>Willing to Relocate for Job</span>
                  </label>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  About Me / Professional Summary
                </label>
                <textarea
                  rows={4}
                  name="summary"
                  value={formData.summary}
                  onChange={handleChange}
                  placeholder="Brief summary about the student's career objective and key strengths..."
                  className="w-full p-3 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                />
              </div>
            </div>
          )}

          {/* TAB 4: SKILLS & LINKS */}
          {activeTab === 'skills_links' && (
            <div className="space-y-5">
              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Skills (Comma separated)
                </label>
                <input
                  type="text"
                  name="skillsInput"
                  value={formData.skillsInput}
                  onChange={handleChange}
                  placeholder="e.g. Python, React, Flutter, SQL, Communication"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                />
                {parseList(formData.skillsInput).length > 0 && (
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {parseList(formData.skillsInput).map((skill, i) => (
                      <span key={i} className="px-2 py-0.5 bg-blue-50 text-blue-700 rounded text-xs border border-blue-100">
                        {skill}
                      </span>
                    ))}
                  </div>
                )}
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Languages Known (Comma separated)
                </label>
                <input
                  type="text"
                  name="languagesInput"
                  value={formData.languagesInput}
                  onChange={handleChange}
                  placeholder="e.g. English, Hindi, Marathi"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                />
                {parseList(formData.languagesInput).length > 0 && (
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {parseList(formData.languagesInput).map((lang, i) => (
                      <span key={i} className="px-2 py-0.5 bg-orange-50 text-orange-700 rounded text-xs border border-orange-100">
                        {lang}
                      </span>
                    ))}
                  </div>
                )}
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                  Hobbies / Interests (Comma separated)
                </label>
                <input
                  type="text"
                  name="hobbiesInput"
                  value={formData.hobbiesInput}
                  onChange={handleChange}
                  placeholder="e.g. Reading, Football, Chess"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                    LinkedIn URL
                  </label>
                  <div className="relative">
                    <Link size={16} className="absolute left-3 top-3 text-blue-500" />
                    <input
                      type="url"
                      name="linkedin_url"
                      value={formData.linkedin_url}
                      onChange={handleChange}
                      placeholder="https://linkedin.com/in/..."
                      className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                    GitHub URL
                  </label>
                  <div className="relative">
                    <Link size={16} className="absolute left-3 top-3 text-gray-600" />
                    <input
                      type="url"
                      name="github_url"
                      value={formData.github_url}
                      onChange={handleChange}
                      placeholder="https://github.com/..."
                      className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1.5">
                    Portfolio Website
                  </label>
                  <div className="relative">
                    <Globe size={16} className="absolute left-3 top-3 text-green-600" />
                    <input
                      type="url"
                      name="portfolio_url"
                      value={formData.portfolio_url}
                      onChange={handleChange}
                      placeholder="https://myportfolio.com"
                      className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primaryBrand/20 focus:border-primaryBrand outline-none"
                    />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Footer Actions */}
          <div className="pt-5 border-t border-gray-200 flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              className="px-5 py-2.5 rounded-lg border border-gray-300 text-gray-700 text-sm font-semibold hover:bg-gray-50 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="px-6 py-2.5 bg-primaryBrand text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition shadow-sm flex items-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {saving ? 'Saving...' : 'Save Profile Changes'}
            </button>
          </div>
        </form>
      </div>

      {/* Image Crop Modal Overlay */}
      {Boolean(imgSrc) && (
        <div className="fixed inset-0 z-60 flex items-center justify-center bg-black/75 p-4 animate-fade-in">
          <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full p-6 animate-slide-up flex flex-col max-h-[90vh]">
            <div className="flex justify-between items-center mb-4 pb-2 border-b border-gray-100">
              <div>
                <h3 className="text-base font-bold text-gray-900">Crop Profile Picture</h3>
                <p className="text-xs text-gray-500">Drag and scale the circle to crop the candidate's avatar</p>
              </div>
              <button
                type="button"
                onClick={() => {
                  setImgSrc('');
                  if (fileInputRef.current) fileInputRef.current.value = '';
                }}
                className="p-1 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-full transition"
              >
                <X size={18} />
              </button>
            </div>

            <div className="flex-1 overflow-auto flex items-center justify-center bg-gray-950/5 rounded-xl p-3 min-h-[260px]">
              <ReactCrop
                crop={crop}
                onChange={c => setCrop(c)}
                onComplete={c => setCompletedCrop(c)}
                aspect={1}
                circularCrop
              >
                <img
                  ref={imgRef}
                  src={imgSrc}
                  alt="Crop preview"
                  onLoad={onImageLoad}
                  className="max-h-[50vh] max-w-full object-contain"
                />
              </ReactCrop>
            </div>

            <div className="flex justify-end gap-3 mt-5 pt-3 border-t border-gray-100">
              <button
                type="button"
                onClick={() => {
                  setImgSrc('');
                  if (fileInputRef.current) fileInputRef.current.value = '';
                }}
                className="px-4 py-2 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleApplyCrop}
                className="px-5 py-2 bg-primaryBrand text-white rounded-lg text-xs font-semibold hover:bg-blue-700 transition shadow-sm flex items-center gap-1.5"
              >
                <Check size={14} />
                Apply & Save Crop
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default EditUserProfileModal;
