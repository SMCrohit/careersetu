import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Jobs from './pages/Jobs';
import Tests from './pages/Tests';
import TestQuestions from './pages/TestQuestions';
import Professionals from './pages/Professionals';
import Offers from './pages/Offers';
import Banners from './pages/Banners';
import Notifications from './pages/Notifications';
import Users from './pages/Users';
import UserProfile from './pages/UserProfile';
import ActivityLogs from './pages/ActivityLogs';
import Appointments from './pages/Appointments';
import AppliedJobs from './pages/AppliedJobs';
import AttemptedTests from './pages/AttemptedTests';
import ClaimedOffers from './pages/ClaimedOffers';
import ProfessionalReviews from './pages/ProfessionalReviews';
import { ToastProvider } from './context/ToastContext';

const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const token = localStorage.getItem('adminToken');
  if (!token) return <Navigate to="/login" replace />;
  return (
    <div className="flex h-screen bg-background">
      <Sidebar />
      <main className="flex-1 overflow-y-auto p-8 bg-background">
        {children}
      </main>
    </div>
  );
};

function App() {
  return (
    <ToastProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/jobs" element={<ProtectedRoute><Jobs /></ProtectedRoute>} />
          <Route path="/jobs/applied" element={<ProtectedRoute><AppliedJobs /></ProtectedRoute>} />
          <Route path="/tests" element={<ProtectedRoute><Tests /></ProtectedRoute>} />
          <Route path="/tests/attempted" element={<ProtectedRoute><AttemptedTests /></ProtectedRoute>} />
          <Route path="/tests/:id/questions" element={<ProtectedRoute><TestQuestions /></ProtectedRoute>} />
          <Route path="/professionals" element={<ProtectedRoute><Professionals /></ProtectedRoute>} />
          <Route path="/appointments" element={<ProtectedRoute><Appointments /></ProtectedRoute>} />
          <Route path="/professionals/reviews" element={<ProtectedRoute><ProfessionalReviews /></ProtectedRoute>} />
          <Route path="/offers" element={<ProtectedRoute><Offers /></ProtectedRoute>} />
          <Route path="/offers/claimed" element={<ProtectedRoute><ClaimedOffers /></ProtectedRoute>} />
          <Route path="/banners" element={<ProtectedRoute><Banners /></ProtectedRoute>} />
          <Route path="/notifications" element={<ProtectedRoute><Notifications /></ProtectedRoute>} />
          <Route path="/users" element={<ProtectedRoute><Users /></ProtectedRoute>} />
          <Route path="/users/:id" element={<ProtectedRoute><UserProfile /></ProtectedRoute>} />
          <Route path="/logs" element={<ProtectedRoute><ActivityLogs /></ProtectedRoute>} />
        </Routes>
      </Router>
    </ToastProvider>
  );
}

export default App;
