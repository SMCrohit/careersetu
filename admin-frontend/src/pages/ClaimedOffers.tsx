import { Tag, Clock } from 'lucide-react';

const ClaimedOffers = () => {
  return (
    <div>
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <div className="w-10 h-10 bg-primaryBrand/10 rounded-xl flex items-center justify-center">
          <Tag className="text-primaryBrand" size={20} />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Claimed Offers</h1>
          <p className="text-sm text-secondaryText">Track which users claimed offers</p>
        </div>
      </div>

      {/* Coming Soon */}
      <div className="bg-white rounded-xl border border-border p-16 flex flex-col items-center justify-center text-center shadow-sm">
        <div className="w-16 h-16 bg-primaryBrand/10 rounded-2xl flex items-center justify-center mb-5">
          <Clock size={30} className="text-primaryBrand" />
        </div>
        <h2 className="text-lg font-semibold text-primaryText mb-2">Coming Soon</h2>
        <p className="text-secondaryText text-sm max-w-sm">
          The claimed offers tracking feature is under development. Once enabled, you'll be able to see all users who have claimed discount offers from this panel.
        </p>
      </div>
    </div>
  );
};

export default ClaimedOffers;
