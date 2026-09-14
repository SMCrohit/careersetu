import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { Lock, User, Eye, EyeOff } from 'lucide-react';

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    try {
      const formData = new URLSearchParams();
      formData.append('username', username);
      formData.append('password', password);
      
      const response = await api.post('/admin/login', formData);
      localStorage.setItem('adminToken', response.data.access_token);
      navigate('/');
    } catch (err) {
      setError('Invalid credentials');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="card w-full max-w-md p-8 animate-slide-up">
        <div className="flex flex-col items-center mb-8">
          <div className="w-12 h-12 bg-primaryBrand rounded-lg flex items-center justify-center text-white font-bold text-2xl mb-4 shadow-lg shadow-primaryBrand/30">C</div>
          <h1 className="text-2xl font-bold text-primaryText">Login</h1>
          <p className="text-secondaryText mt-1">Welcome back to CareerSetu</p>
        </div>

        {error && <div className="bg-error/10 text-error p-3 rounded-md mb-4 text-sm text-center">{error}</div>}

        <form onSubmit={handleLogin} className="space-y-5">
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Username</label>
            <div className="relative">
              <User className="absolute left-3 top-2.5 text-borderDark" size={18} />
              <input 
                type="text" 
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="input-field pl-10"
                placeholder="Enter admin username"
                required
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Password</label>
            <div className="relative">
              <Lock className="absolute left-3 top-2.5 text-borderDark" size={18} />
              <input 
                type={showPassword ? "text" : "password"} 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="input-field pl-10 pr-10"
                placeholder="Enter password"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-2.5 text-borderDark hover:text-primaryText transition-colors focus:outline-none"
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>
          <button type="submit" className="btn-primary w-full mt-2">
            Sign In
          </button>
        </form>
      </div>
    </div>
  );
};

export default Login;
