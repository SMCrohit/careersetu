import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { ArrowLeft, Plus, Trash2, Edit2, X, Upload, Image as ImageIcon } from 'lucide-react';
import ConfirmDialog from '../components/ConfirmDialog';
import { useToast } from '../context/ToastContext';
import CreatableSelect from 'react-select/creatable';

interface TestQuestion {
  id: string;
  test_id: string;
  question_type: string;
  question_text: string;
  question_image_url?: string;
  question_note?: string;
  options: { id: string, text: string, image_url?: string }[];
  correct_answer: string;
  marks: number;
  negative_marks?: number;
  time_limit_seconds?: number;
  section?: string;
  topic?: string;
  subtopic?: string;
  difficulty: string;
  explanation?: string;
  explanation_image_url?: string;
  order_index: number;
}

const defaultQuestion = {
  question_type: 'single_select',
  question_text: '',
  question_image_url: '',
  question_note: '',
  options: [
    { id: '1', text: '' },
    { id: '2', text: '' },
    { id: '3', text: '' },
    { id: '4', text: '' }
  ],
  correct_answer: '',
  marks: 1.0,
  negative_marks: 0,
  time_limit_seconds: 0,
  section: '',
  topic: '',
  subtopic: '',
  difficulty: 'Medium',
  explanation: '',
  explanation_image_url: '',
  order_index: 0
};

const TestQuestions = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { showToast } = useToast();
  
  const [test, setTest] = useState<any>(null);
  const [questions, setQuestions] = useState<TestQuestion[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Taxonomies
  const [sections, setSections] = useState<{label: string, value: string}[]>([]);
  const [topics, setTopics] = useState<{label: string, value: string}[]>([]);
  const [subtopics, setSubtopics] = useState<{label: string, value: string}[]>([]);

  // Views
  const [isFormView, setIsFormView] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState<any>(defaultQuestion);
  const [saving, setSaving] = useState(false);

  // Deletion
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [questionToDelete, setQuestionToDelete] = useState<string | null>(null);

  // Upload modal logic (simplified for this rewrite)
  const [_uploadModalOpen] = useState(false);

  useEffect(() => {
    fetchTestAndQuestions();
    fetchTaxonomies();
  }, [id]);

  const fetchTaxonomies = async () => {
    try {
      const res = await api.get('/test-taxonomy');
      const data = res.data;
      setSections(data.filter((d: any) => d.type === 'section').map((d: any) => ({ label: d.name, value: d.name })));
      setTopics(data.filter((d: any) => d.type === 'topic').map((d: any) => ({ label: d.name, value: d.name })));
      setSubtopics(data.filter((d: any) => d.type === 'subtopic').map((d: any) => ({ label: d.name, value: d.name })));
    } catch (e) {
      console.error(e);
    }
  };

  const fetchTestAndQuestions = async () => {
    try {
      const testRes = await api.get(`/tests/${id}`);
      const qRes = await api.get(`/tests/${id}/questions`);
      setTest(testRes.data);
      setQuestions(qRes.data);
    } catch (error) {
      showToast("Failed to load test details or questions", "error");
    } finally {
      setLoading(false);
    }
  };

  const handleCreateTaxonomy = async (inputValue: string, type: 'section'|'topic'|'subtopic') => {
    try {
      const res = await api.post('/test-taxonomy', { type, name: inputValue });
      const newOption = { label: res.data.name, value: res.data.name };
      if (type === 'section') {
        setSections([...sections, newOption]);
        setFormData({ ...formData, section: res.data.name });
      } else if (type === 'topic') {
        setTopics([...topics, newOption]);
        setFormData({ ...formData, topic: res.data.name });
      } else if (type === 'subtopic') {
        setSubtopics([...subtopics, newOption]);
        setFormData({ ...formData, subtopic: res.data.name });
      }
      showToast(`Created new ${type}: ${inputValue}`, "success");
    } catch (error) {
      showToast(`Failed to create ${type}`, "error");
    }
  };

  const openAddForm = () => {
    setFormData({ ...defaultQuestion, options: [
      { id: '1', text: '' },
      { id: '2', text: '' },
      { id: '3', text: '' },
      { id: '4', text: '' }
    ]});
    setEditingId(null);
    setIsFormView(true);
  };

  const openEditForm = (q: TestQuestion) => {
    setFormData({ ...q });
    setEditingId(q.id);
    setIsFormView(true);
  };

  const handleSaveQuestion = async (addAnother: boolean = false) => {
    // Validation
    if (!formData.question_text.trim()) {
      showToast("Question text is required", "error");
      return;
    }
    if (!formData.correct_answer) {
      showToast("Please select a correct answer", "error");
      return;
    }

    setSaving(true);
    try {
      // Clean up dynamic options depending on type
      let payload = { ...formData };
      if (payload.question_type === 'true_false') {
        payload.options = [
          { id: '1', text: 'True' },
          { id: '2', text: 'False' }
        ];
      }
      
      // Enforce nulls for optional overrides
      if (payload.negative_marks === 0) payload.negative_marks = null;
      if (payload.time_limit_seconds === 0) payload.time_limit_seconds = null;

      if (editingId) {
        await api.put(`/tests/${id}/questions/${editingId}`, payload);
        showToast("Question updated", "success");
      } else {
        await api.post(`/tests/${id}/questions`, payload);
        showToast("Question added", "success");
      }

      await fetchTestAndQuestions();
      
      if (addAnother) {
        openAddForm();
      } else {
        setIsFormView(false);
      }
    } catch (error) {
      showToast("Failed to save question", "error");
    } finally {
      setSaving(false);
    }
  };

  const confirmDeleteQuestion = async () => {
    if (!questionToDelete) return;
    try {
      await api.delete(`/tests/${id}/questions/${questionToDelete}`);
      showToast("Question deleted", "success");
      setQuestions(questions.filter(q => q.id !== questionToDelete));
    } catch (error) {
      showToast("Failed to delete question", "error");
    } finally {
      setDeleteDialogOpen(false);
      setQuestionToDelete(null);
    }
  };

  // Dynamic Options Handlers
  const addOption = () => {
    const newOptions = [...formData.options, { id: Date.now().toString(), text: '' }];
    setFormData({ ...formData, options: newOptions });
  };

  const removeOption = (optId: string) => {
    const newOptions = formData.options.filter((o: any) => o.id !== optId);
    setFormData({ ...formData, options: newOptions });
  };

  const updateOptionText = (optId: string, text: string) => {
    const newOptions = formData.options.map((o: any) => o.id === optId ? { ...o, text } : o);
    setFormData({ ...formData, options: newOptions });
  };
  
  // Toggle for multi select correct answers
  const toggleCorrectAnswerMulti = (optText: string) => {
    let currentAns = formData.correct_answer ? formData.correct_answer.split('||') : [];
    if (currentAns.includes(optText)) {
      currentAns = currentAns.filter((a: string) => a !== optText);
    } else {
      currentAns.push(optText);
    }
    setFormData({ ...formData, correct_answer: currentAns.join('||') });
  };

  if (loading) return <div className="p-8 text-secondaryText">Loading...</div>;
  if (!test) return <div className="p-8 text-error">Test not found.</div>;

  return (
    <div className="animate-fade-in max-w-6xl mx-auto pb-20 p-6">
      {!isFormView ? (
        // --- LIST VIEW ---
        <>
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
            <div className="flex items-center gap-4">
              <button onClick={() => navigate('/tests')} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                <ArrowLeft size={24} className="text-secondaryText" />
              </button>
              <div>
                <h1 className="text-2xl font-bold text-primaryText">Manage Questions</h1>
                <p className="text-secondaryText">Test: <span className="font-medium text-primaryBrand">{test.title}</span></p>
              </div>
            </div>
            <div className="flex gap-3">
              <button onClick={() => showToast('Feature is coming soon.', 'info')} className="px-4 py-2 border border-gray-300 text-secondaryText font-medium rounded-md hover:bg-gray-50 transition-colors flex items-center gap-2">
                <Upload size={18} /> Bulk Upload
              </button>
              <button onClick={openAddForm} className="btn-primary flex items-center gap-2">
                <Plus size={18} /> Add New Question
              </button>
            </div>
          </div>

          <div className="card overflow-hidden">
            <table className="w-full text-left">
              <thead className="bg-background">
                <tr>
                  <th className="px-6 py-4 font-medium text-secondaryText w-1/2">Question</th>
                  <th className="px-6 py-4 font-medium text-secondaryText">Type</th>
                  <th className="px-6 py-4 font-medium text-secondaryText">Categories</th>
                  <th className="px-6 py-4 font-medium text-secondaryText">Marks</th>
                  <th className="px-6 py-4 font-medium text-secondaryText text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-borderDark">
                {questions.length === 0 ? (
                  <tr><td colSpan={5} className="px-6 py-8 text-center text-secondaryText">No questions added yet. Click "Add New Question" to begin.</td></tr>
                ) : (
                  questions.map((q, idx) => (
                    <tr key={q.id} className="hover:bg-background/50 transition-colors">
                      <td className="px-6 py-4 text-primaryText">
                        <p className="font-medium line-clamp-2">{idx + 1}. {q.question_text}</p>
                      </td>
                      <td className="px-6 py-4">
                        <span className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs font-medium uppercase">{q.question_type.replace('_', ' ')}</span>
                      </td>
                      <td className="px-6 py-4 text-sm text-secondaryText">
                        {q.section && <div><span className="font-medium">Sec:</span> {q.section}</div>}
                        {q.topic && <div><span className="font-medium">Topic:</span> {q.topic}</div>}
                        {q.subtopic && <div><span className="font-medium">Sub:</span> {q.subtopic}</div>}
                      </td>
                      <td className="px-6 py-4 text-sm font-medium text-green-600">
                        {q.marks.toFixed(1)}
                        {q.negative_marks && <span className="text-red-500 block text-xs">-{q.negative_marks}</span>}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button onClick={() => openEditForm(q)} className="p-2 text-primaryBrand hover:bg-primaryBrand/10 rounded transition-colors"><Edit2 size={18} /></button>
                          <button onClick={() => { setQuestionToDelete(q.id); setDeleteDialogOpen(true); }} className="p-2 text-error hover:bg-error/10 rounded transition-colors"><Trash2 size={18} /></button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </>
      ) : (
        // --- FORM VIEW ---
        <div className="animate-slide-up">
          <div className="flex items-center gap-4 mb-6">
            <button onClick={() => setIsFormView(false)} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
              <ArrowLeft size={24} className="text-secondaryText" />
            </button>
            <h1 className="text-2xl font-bold text-primaryText">{editingId ? 'Edit Question' : 'Add New Question'}</h1>
          </div>

          <div className="space-y-6">
            
            {/* Section 1: Setup */}
            <div className="card p-6 space-y-4">
              <h3 className="text-lg font-bold text-primaryText border-b border-border pb-2">1. Question Setup</h3>
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Question Type *</label>
                  <select className="input-field bg-white" value={formData.question_type} onChange={e => setFormData({...formData, question_type: e.target.value})}>
                    <option value="single_select">Single Select</option>
                    <option value="multi_select">Multi-Select</option>
                    <option value="true_false">True / False</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Section</label>
                  <CreatableSelect 
                    isClearable 
                    options={sections}
                    value={formData.section ? {label: formData.section, value: formData.section} : null}
                    onChange={(val) => setFormData({...formData, section: val ? val.value : ''})}
                    onCreateOption={(val) => handleCreateTaxonomy(val, 'section')}
                    placeholder="e.g. Quantitative"
                    menuPortalTarget={document.body}
                    styles={{ menuPortal: base => ({ ...base, zIndex: 9999 }) }}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Topic</label>
                  <CreatableSelect 
                    isClearable 
                    options={topics}
                    value={formData.topic ? {label: formData.topic, value: formData.topic} : null}
                    onChange={(val) => setFormData({...formData, topic: val ? val.value : ''})}
                    onCreateOption={(val) => handleCreateTaxonomy(val, 'topic')}
                    placeholder="e.g. Mathematics"
                    menuPortalTarget={document.body}
                    styles={{ menuPortal: base => ({ ...base, zIndex: 9999 }) }}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Sub-Topic</label>
                  <CreatableSelect 
                    isClearable 
                    options={subtopics}
                    value={formData.subtopic ? {label: formData.subtopic, value: formData.subtopic} : null}
                    onChange={(val) => setFormData({...formData, subtopic: val ? val.value : ''})}
                    onCreateOption={(val) => handleCreateTaxonomy(val, 'subtopic')}
                    placeholder="e.g. Algebra"
                    menuPortalTarget={document.body}
                    styles={{ menuPortal: base => ({ ...base, zIndex: 9999 }) }}
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Content */}
            <div className="card p-6 space-y-4">
              <h3 className="text-lg font-bold text-primaryText border-b border-border pb-2">2. Question Content</h3>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Question Text *</label>
                <textarea required rows={4} className="input-field" placeholder="Enter your question here..." value={formData.question_text} onChange={e => setFormData({...formData, question_text: e.target.value})} />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Question Note (Optional)</label>
                  <input type="text" placeholder="e.g. Read the following passage carefully" className="input-field" value={formData.question_note} onChange={e => setFormData({...formData, question_note: e.target.value})} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Question Image URL (Optional)</label>
                  <div className="flex gap-2">
                    <div className="relative flex-1">
                      <ImageIcon className="absolute left-3 top-2.5 text-gray-400" size={18} />
                      <input type="text" placeholder="https://..." className="input-field pl-10" value={formData.question_image_url} onChange={e => setFormData({...formData, question_image_url: e.target.value})} />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Section 3: Options */}
            <div className="card p-6 space-y-4">
              <div className="flex justify-between items-center border-b border-border pb-2">
                <h3 className="text-lg font-bold text-primaryText">3. Options & Answers</h3>
                {formData.question_type !== 'true_false' && (
                  <button type="button" onClick={addOption} className="text-sm font-medium text-primaryBrand flex items-center gap-1 hover:underline">
                    <Plus size={16} /> Add Option
                  </button>
                )}
              </div>
              
              <div className="space-y-3">
                {formData.question_type === 'true_false' ? (
                  <div className="flex gap-6 mt-4">
                    <label className="flex items-center gap-2 cursor-pointer p-3 border rounded-lg hover:bg-gray-50 flex-1">
                      <input type="radio" name="tf_answer" className="w-4 h-4 text-primaryBrand" checked={formData.correct_answer === 'True'} onChange={() => setFormData({...formData, correct_answer: 'True'})} />
                      <span className="font-medium">True</span>
                    </label>
                    <label className="flex items-center gap-2 cursor-pointer p-3 border rounded-lg hover:bg-gray-50 flex-1">
                      <input type="radio" name="tf_answer" className="w-4 h-4 text-primaryBrand" checked={formData.correct_answer === 'False'} onChange={() => setFormData({...formData, correct_answer: 'False'})} />
                      <span className="font-medium">False</span>
                    </label>
                  </div>
                ) : (
                  formData.options.map((opt: any, idx: number) => (
                    <div key={opt.id} className={`flex items-start gap-3 p-3 border rounded-xl transition-colors ${formData.correct_answer.includes(opt.text) && opt.text ? 'border-primaryBrand bg-primaryBrand/5' : 'border-gray-200 bg-white'}`}>
                      <div className="pt-2.5">
                        {formData.question_type === 'single_select' ? (
                           <input type="radio" name="correct_ans" className="w-5 h-5 text-primaryBrand" checked={formData.correct_answer === opt.text && opt.text !== ''} onChange={() => setFormData({...formData, correct_answer: opt.text})} />
                        ) : (
                           <input type="checkbox" className="w-5 h-5 text-primaryBrand rounded" checked={formData.correct_answer.split('||').includes(opt.text) && opt.text !== ''} onChange={() => toggleCorrectAnswerMulti(opt.text)} />
                        )}
                      </div>
                      <div className="flex-1">
                        <input type="text" placeholder={`Option ${idx + 1}`} className="w-full border-none bg-transparent focus:ring-0 p-2 text-primaryText font-medium" value={opt.text} onChange={e => updateOptionText(opt.id, e.target.value)} />
                      </div>
                      {formData.options.length > 2 && (
                        <button type="button" onClick={() => removeOption(opt.id)} className="p-2 text-gray-400 hover:text-error transition-colors mt-1">
                          <X size={18} />
                        </button>
                      )}
                    </div>
                  ))
                )}
                <p className="text-sm text-secondaryText mt-2">
                  ℹ️ {formData.question_type === 'multi_select' ? 'Check the boxes next to all correct answers.' : 'Select the radio button next to the single correct answer.'}
                </p>
              </div>
            </div>

            {/* Section 4: Scoring & Explanations */}
            <div className="card p-6 space-y-4">
              <h3 className="text-lg font-bold text-primaryText border-b border-border pb-2">4. Scoring & Explanations</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Marks Awarded *</label>
                  <input required type="number" step="0.1" min="0" className="input-field" value={formData.marks} onChange={e => setFormData({...formData, marks: parseFloat(e.target.value) || 0})} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Negative Marks Override</label>
                  <input type="number" step="0.1" min="0" placeholder="e.g. 0.25" className="input-field bg-amber-50 border-amber-200" value={formData.negative_marks || ''} onChange={e => setFormData({...formData, negative_marks: parseFloat(e.target.value)})} />
                  <p className="text-xs text-amber-600 mt-1">Overrides test default. Leave blank to use default.</p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-secondaryText mb-1">Time Limit Override (Secs)</label>
                  <input type="number" min="0" placeholder="e.g. 120" className="input-field bg-amber-50 border-amber-200" value={formData.time_limit_seconds || ''} onChange={e => setFormData({...formData, time_limit_seconds: parseInt(e.target.value)})} />
                  <p className="text-xs text-amber-600 mt-1">Overrides test default. Leave blank to use default.</p>
                </div>
              </div>
              
              <div className="mt-4 border-t pt-4">
                <label className="block text-sm font-medium text-secondaryText mb-1">Explanation Text (Solution)</label>
                <textarea rows={3} className="input-field" placeholder="Explain the reasoning behind the correct answer..." value={formData.explanation} onChange={e => setFormData({...formData, explanation: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-secondaryText mb-1">Explanation Image URL (Optional)</label>
                <div className="relative">
                  <ImageIcon className="absolute left-3 top-2.5 text-gray-400" size={18} />
                  <input type="text" placeholder="https://..." className="input-field pl-10" value={formData.explanation_image_url} onChange={e => setFormData({...formData, explanation_image_url: e.target.value})} />
                </div>
              </div>
            </div>

            {/* Actions Toolbar */}
            <div className="flex items-center justify-end gap-4 pt-4 border-t border-border">
              <button type="button" onClick={() => setIsFormView(false)} className="px-6 py-2 text-secondaryText font-medium hover:text-primaryText transition-colors">
                Cancel
              </button>
              <button type="button" onClick={() => handleSaveQuestion(true)} disabled={saving} className="px-6 py-2 bg-primaryBrand/10 text-primaryBrand font-medium rounded-xl hover:bg-primaryBrand/20 transition-colors">
                {saving ? 'Saving...' : 'Save & Add Another'}
              </button>
              <button type="button" onClick={() => handleSaveQuestion(false)} disabled={saving} className="btn-primary">
                {saving ? 'Saving...' : 'Save Question'}
              </button>
            </div>

          </div>
        </div>
      )}

      <ConfirmDialog
        isOpen={deleteDialogOpen}
        title="Delete Question"
        message="Are you sure you want to delete this question? This action cannot be undone."
        onConfirm={confirmDeleteQuestion}
        onClose={() => setDeleteDialogOpen(false)}
      />
    </div>
  );
};

export default TestQuestions;
