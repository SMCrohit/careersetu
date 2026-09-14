import { AlertTriangle, X } from 'lucide-react';

interface ConfirmDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
}

const ConfirmDialog = ({ isOpen, onClose, onConfirm, title, message }: ConfirmDialogProps) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 animate-fade-in p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-md animate-slide-up overflow-hidden">
        <div className="p-6">
          <div className="flex items-start gap-4">
            <div className="p-3 bg-red-50 rounded-full text-error shrink-0">
              <AlertTriangle size={24} />
            </div>
            <div>
              <h2 className="text-xl font-bold text-primaryText mb-2">{title}</h2>
              <p className="text-secondaryText">{message}</p>
            </div>
          </div>
        </div>
        <div className="px-6 py-4 bg-gray-50 flex justify-end gap-3 border-t border-border">
          <button 
            onClick={onClose}
            className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium transition-colors"
          >
            Cancel
          </button>
          <button 
            onClick={() => {
              onConfirm();
              onClose();
            }}
            className="px-4 py-2 bg-error text-white rounded-md font-medium hover:bg-red-700 transition-colors"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmDialog;
