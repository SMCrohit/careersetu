import { useEffect, useState } from 'react';
import api from '../api/axios';
import { FileText, Search, User, BookOpen, Calendar, Trophy } from 'lucide-react';

type TestAttempt = {
  id: string;
  score: number;
  total_questions: number;
  attempted_at: string;
  user: {
    id: string;
    full_name: string;
    mobile_number: string;
    city: string;
  } | null;
  test: {
    id: string;
    title: string;
    tag: string;
    difficulty: string;
  } | null;
};

const difficultyColors: Record<string, string> = {
  Easy: 'bg-green-100 text-green-700',
  Medium: 'bg-yellow-100 text-yellow-700',
  Hard: 'bg-red-100 text-red-700',
};

const AttemptedTests = () => {
  const [attempts, setAttempts] = useState<TestAttempt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  useEffect(() => {
    const fetchAttempts = async () => {
      try {
        const { data } = await api.get('/admin/test-attempts');
        setAttempts(data);
      } catch (err) {
        setError('Failed to load test attempts.');
      } finally {
        setLoading(false);
      }
    };
    fetchAttempts();
  }, []);

  const filtered = attempts.filter((att) => {
    return (
      att.user?.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      att.test?.title?.toLowerCase().includes(search.toLowerCase()) ||
      att.test?.tag?.toLowerCase().includes(search.toLowerCase()) ||
      att.user?.mobile_number?.includes(search)
    );
  });

  const formatDate = (iso: string) => {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  };

  const getScoreColor = (score: number, total: number) => {
    if (total === 0) return 'text-secondaryText';
    const pct = (score / total) * 100;
    if (pct >= 80) return 'text-green-600';
    if (pct >= 50) return 'text-yellow-600';
    return 'text-red-500';
  };

  return (
    <div>
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <div className="w-10 h-10 bg-primaryBrand/10 rounded-xl flex items-center justify-center">
          <FileText className="text-primaryBrand" size={20} />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Attempted Tests</h1>
          <p className="text-sm text-secondaryText">All test attempts made by users</p>
        </div>
        <div className="ml-auto bg-primaryBrand/10 text-primaryBrand text-sm font-semibold px-3 py-1.5 rounded-full">
          {filtered.length} Attempts
        </div>
      </div>

      {/* Search */}
      <div className="relative mb-6 max-w-md">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-secondaryText" />
        <input
          type="text"
          placeholder="Search by user, test name or tag..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-border bg-white text-sm text-primaryText focus:outline-none focus:ring-2 focus:ring-primaryBrand/30"
        />
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <div className="w-8 h-8 border-4 border-primaryBrand border-t-transparent rounded-full animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-red-50 text-red-600 p-6 rounded-xl border border-red-200 text-center">{error}</div>
      ) : filtered.length === 0 ? (
        <div className="bg-white rounded-xl border border-border p-16 flex flex-col items-center justify-center text-center">
          <FileText size={40} className="text-border mb-3" />
          <p className="text-primaryText font-medium">No test attempts found</p>
          <p className="text-secondaryText text-sm mt-1">Try changing your search.</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-border overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-backgroundLight border-b border-border">
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">#</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">User</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Test</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Tag</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Difficulty</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Score</th>
                  <th className="text-left px-5 py-3.5 text-secondaryText font-semibold">Attempted On</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((att, idx) => (
                  <tr key={att.id} className="border-b border-border last:border-0 hover:bg-backgroundLight/50 transition-colors">
                    <td className="px-5 py-4 text-secondaryText">{idx + 1}</td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-full bg-primaryBrand/10 flex items-center justify-center shrink-0">
                          <User size={14} className="text-primaryBrand" />
                        </div>
                        <div>
                          <p className="font-medium text-primaryText">{att.user?.full_name || '—'}</p>
                          <p className="text-xs text-secondaryText">{att.user?.mobile_number || '—'} &middot; {att.user?.city || '—'}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-2">
                        <BookOpen size={14} className="text-secondaryText shrink-0" />
                        <p className="font-medium text-primaryText">{att.test?.title || '—'}</p>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <span className="px-2 py-1 rounded-md bg-backgroundLight text-secondaryText text-xs font-medium">
                        {att.test?.tag || '—'}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${difficultyColors[att.test?.difficulty || ''] || 'bg-gray-100 text-gray-600'}`}>
                        {att.test?.difficulty || '—'}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-1.5">
                        <Trophy size={14} className={getScoreColor(att.score, att.total_questions)} />
                        <span className={`font-bold text-base ${getScoreColor(att.score, att.total_questions)}`}>
                          {att.score != null ? att.score : '—'}
                        </span>
                        {att.total_questions > 0 && (
                          <span className="text-secondaryText text-xs">/ {att.total_questions}</span>
                        )}
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-1.5 text-secondaryText text-xs">
                        <Calendar size={12} />
                        {formatDate(att.attempted_at)}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttemptedTests;
