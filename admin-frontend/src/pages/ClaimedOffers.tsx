import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Tag, Search } from 'lucide-react';
import { useToast } from '../context/ToastContext';

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
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    fetchClaimedOffers();
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

  const filteredOffers = claimedOffers.filter(co => 
    co.user?.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    co.user?.mobile_number?.includes(searchQuery) ||
    co.offer?.title?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div>
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primaryBrand/10 rounded-xl flex items-center justify-center">
            <Tag className="text-primaryBrand" size={20} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-primaryText">Claimed Offers</h1>
            <p className="text-sm text-secondaryText">Track which users claimed offers</p>
          </div>
        </div>

        <div className="relative w-full md:w-64">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondaryText" size={18} />
          <input 
            type="text" 
            placeholder="Search by user or offer..." 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primaryBrand/20"
          />
        </div>
      </div>

      <div className="bg-white rounded-xl border border-border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-background text-secondaryText text-sm uppercase tracking-wider">
                <th className="p-4 font-semibold">User</th>
                <th className="p-4 font-semibold">Contact</th>
                <th className="p-4 font-semibold">Offer</th>
                <th className="p-4 font-semibold">City</th>
                <th className="p-4 font-semibold">Code Used</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                <tr>
                  <td colSpan={5} className="p-8 text-center text-secondaryText">Loading...</td>
                </tr>
              ) : filteredOffers.length === 0 ? (
                <tr>
                  <td colSpan={5} className="p-8 text-center text-secondaryText">No claimed offers found.</td>
                </tr>
              ) : (
                filteredOffers.map((co) => (
                  <tr key={co.id} className="hover:bg-background/50 transition-colors">
                    <td className="p-4">
                      <div className="font-medium text-primaryText">{co.user?.full_name || 'N/A'}</div>
                    </td>
                    <td className="p-4">
                      <div className="text-sm text-primaryText">{co.user?.mobile_number || 'N/A'}</div>
                      <div className="text-xs text-secondaryText">{co.user?.email || ''}</div>
                    </td>
                    <td className="p-4 text-sm font-medium">{co.offer?.title || 'Unknown Offer'}</td>
                    <td className="p-4 text-sm text-secondaryText">{co.offer?.city || 'All'}</td>
                    <td className="p-4">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primaryBrand/10 text-primaryBrand">
                        {co.offer?.discount_code || 'N/A'}
                      </span>
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

export default ClaimedOffers;
