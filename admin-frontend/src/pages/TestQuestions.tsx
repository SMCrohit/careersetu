import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { ArrowLeft, Plus, Trash2, Save, X, Upload } from 'lucide-react';
import ConfirmDialog from '../components/ConfirmDialog';
import Modal from '../components/Modal';
import { useToast } from '../context/ToastContext';

interface Question {
  id: string;
  text: string;
  options: string[];
  correct_answer: string;
}

const TestQuestions = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [test, setTest] = useState<any>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [questionToDelete, setQuestionToDelete] = useState<number | null>(null);

  const [uploadModalOpen, setUploadModalOpen] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadFile, setUploadFile] = useState<File | null>(null);
  const [invalidQuestionsModalOpen, setInvalidQuestionsModalOpen] = useState(false);
  const [invalidQuestions, setInvalidQuestions] = useState<string[]>([]);

  useEffect(() => {
    fetchTest();
  }, [id]);

  const fetchTest = async () => {
    try {
      const res = await api.get(`/tests/${id}`);
      setTest(res.data);
      if (res.data.questions && Array.isArray(res.data.questions)) {
        setQuestions(res.data.questions);
      }
    } catch (error) {
      showToast("Failed to load test", "error");
    } finally {
      setLoading(false);
    }
  };

  const saveQuestions = async () => {
    setSaving(true);
    try {
      const updatedTest = { ...test, questions };
      await api.put(`/tests/${id}`, updatedTest);
      showToast("Questions saved successfully!", "success");
      navigate('/tests');
    } catch (error) {
      showToast("Failed to save questions", "error");
    } finally {
      setSaving(false);
    }
  };

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!uploadFile) return;
    
    setUploading(true);
    const formData = new FormData();
    formData.append('file', uploadFile);
    
    try {
      const res = await api.post(`/tests/${id}/upload-questions`, formData);
      
      const { valid, invalid } = res.data;
      
      if (valid && valid.length > 0) {
        setQuestions(prev => [...prev, ...valid]);
        showToast(`Successfully added ${valid.length} questions`, "success");
      }
      
      if (invalid && invalid.length > 0) {
        setInvalidQuestions(invalid);
        setInvalidQuestionsModalOpen(true);
      }
      
      setUploadModalOpen(false);
      setUploadFile(null);
    } catch (error) {
      showToast("Failed to upload questions", "error");
    } finally {
      setUploading(false);
    }
  };

  const addQuestion = () => {
    const newQuestion: Question = {
      id: `q_${Date.now()}`,
      text: '',
      options: ['', '', '', ''],
      correct_answer: ''
    };
    setQuestions([...questions, newQuestion]);
  };

  const updateQuestionText = (qIndex: number, text: string) => {
    const newQ = [...questions];
    newQ[qIndex].text = text;
    setQuestions(newQ);
  };

  const addOption = (qIndex: number) => {
    const newQ = [...questions];
    newQ[qIndex].options.push('');
    setQuestions(newQ);
  };

  const removeOption = (qIndex: number, optIndex: number) => {
    const newQ = [...questions];
    const removedOption = newQ[qIndex].options[optIndex];
    newQ[qIndex].options.splice(optIndex, 1);
    
    // If the removed option was the correct answer, reset correct answer
    if (newQ[qIndex].correct_answer === removedOption) {
      newQ[qIndex].correct_answer = '';
    }
    
    setQuestions(newQ);
  };

  const updateOption = (qIndex: number, optIndex: number, value: string) => {
    const newQ = [...questions];
    const oldVal = newQ[qIndex].options[optIndex];
    newQ[qIndex].options[optIndex] = value;
    
    // Update correct answer if it matched the old value
    if (newQ[qIndex].correct_answer === oldVal) {
      newQ[qIndex].correct_answer = value;
    }
    
    setQuestions(newQ);
  };

  const setCorrectAnswer = (qIndex: number, value: string) => {
    const newQ = [...questions];
    newQ[qIndex].correct_answer = value;
    setQuestions(newQ);
  };

  const removeQuestion = (qIndex: number) => {
    setQuestionToDelete(qIndex);
    setDeleteDialogOpen(true);
  };

  const confirmDeleteQuestion = () => {
    if (questionToDelete === null) return;
    const newQ = [...questions];
    newQ.splice(questionToDelete, 1);
    setQuestions(newQ);
    setQuestionToDelete(null);
    setDeleteDialogOpen(false);
    showToast("Question removed", "info");
  };

  if (loading) return <div className="p-8 text-secondaryText">Loading questions...</div>;
  if (!test) return <div className="p-8 text-error">Test not found.</div>;

  return (
    <div className="animate-fade-in max-w-5xl mx-auto pb-20">
      <div className="flex items-center gap-4 mb-8">
        <button onClick={() => navigate('/tests')} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <ArrowLeft size={24} className="text-secondaryText" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-primaryText">Manage Questions</h1>
          <p className="text-secondaryText">Editing questions for test: <span className="font-medium text-primaryBrand">{test.title}</span></p>
        </div>
        <div className="ml-auto flex gap-3">
          <button onClick={() => setUploadModalOpen(true)} className="px-4 py-2 border border-gray-300 text-secondaryText font-medium rounded-md hover:bg-gray-50 transition-colors flex items-center gap-2">
            <Upload size={18} /> Bulk Upload
          </button>
          <button onClick={addQuestion} className="px-4 py-2 border border-primaryBrand text-primaryBrand font-medium rounded-md hover:bg-blue-50 transition-colors flex items-center gap-2">
            <Plus size={18} /> Add Question
          </button>
          <button onClick={saveQuestions} disabled={saving} className="btn-primary flex items-center gap-2">
            <Save size={18} /> {saving ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>

      <div className="space-y-6">
        {questions.length === 0 ? (
          <div className="card p-12 text-center text-secondaryText flex flex-col items-center">
            <p className="mb-4">This test has no questions yet.</p>
            <button onClick={addQuestion} className="btn-primary">Create First Question</button>
          </div>
        ) : (
          questions.map((q, qIndex) => (
            <div key={q.id} className="card p-6 animate-slide-up bg-white">
              <div className="flex justify-between items-start mb-4">
                <h3 className="font-bold text-primaryText text-lg">Question {qIndex + 1}</h3>
                <button onClick={() => removeQuestion(qIndex)} className="text-secondaryText hover:text-error transition-colors p-1 rounded-md hover:bg-red-50">
                  <Trash2 size={18} />
                </button>
              </div>
              
              <div className="mb-6">
                <input 
                  type="text" 
                  value={q.text} 
                  onChange={(e) => updateQuestionText(qIndex, e.target.value)} 
                  placeholder="Enter the question text here..." 
                  className="input-field text-lg py-3 font-medium bg-gray-50/50" 
                />
              </div>

              <div className="space-y-3 pl-4 border-l-2 border-primaryBrand/20">
                <div className="flex justify-between items-center mb-2">
                  <h4 className="text-sm font-semibold text-secondaryText uppercase tracking-wider">Options</h4>
                  <button onClick={() => addOption(qIndex)} className="text-xs font-medium text-primaryBrand hover:underline flex items-center gap-1">
                    <Plus size={14} /> Add Option
                  </button>
                </div>
                
                {q.options.map((opt, optIndex) => (
                  <div key={optIndex} className="flex items-center gap-3">
                    <input 
                      type="radio" 
                      name={`correct_${q.id}`} 
                      checked={q.correct_answer === opt && opt.trim() !== ''} 
                      onChange={() => setCorrectAnswer(qIndex, opt)}
                      className="w-4 h-4 text-primaryBrand border-border focus:ring-primaryBrand"
                      title="Mark as correct answer"
                    />
                    <div className="flex-1 relative">
                      <input 
                        type="text" 
                        value={opt} 
                        onChange={(e) => updateOption(qIndex, optIndex, e.target.value)} 
                        placeholder={`Option ${optIndex + 1}`} 
                        className={`input-field pr-10 ${q.correct_answer === opt && opt.trim() !== '' ? 'border-primaryBrand bg-blue-50/30' : ''}`} 
                      />
                      {q.options.length > 2 && (
                        <button 
                          onClick={() => removeOption(qIndex, optIndex)} 
                          className="absolute right-2 top-2.5 text-borderDark hover:text-error transition-colors"
                          title="Remove option"
                        >
                          <X size={16} />
                        </button>
                      )}
                    </div>
                    {q.correct_answer === opt && opt.trim() !== '' && (
                      <span className="text-xs font-medium text-primaryBrand whitespace-nowrap bg-blue-50 px-2 py-1 rounded-md">
                        Correct Answer
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ))
        )}
      </div>

      <ConfirmDialog 
        isOpen={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)} 
        onConfirm={confirmDeleteQuestion} 
        title="Remove Question" 
        message="Are you sure you want to remove this question? You will still need to save changes for it to take effect." 
      />

      <Modal isOpen={uploadModalOpen} onClose={() => setUploadModalOpen(false)} title="Bulk Upload Questions">
        <form onSubmit={handleUpload} className="space-y-4">
          <div className="p-4 bg-blue-50 rounded-lg text-sm text-blue-800 mb-4">
            <p className="mb-2 font-medium">Download Sample Formats:</p>
            <div className="flex gap-4">
              <a href="/sample_questions.xlsx" download className="text-primaryBrand hover:underline">Excel Sample (.xlsx)</a>
              <a href="/sample_questions.pdf" download className="text-primaryBrand hover:underline">PDF Sample (.pdf)</a>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-secondaryText mb-1">Select File (PDF or Excel)</label>
            <input 
              type="file" 
              accept=".pdf,.xlsx,.xls"
              onChange={(e) => setUploadFile(e.target.files ? e.target.files[0] : null)}
              className="w-full text-sm text-secondaryText file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-primaryBrand hover:file:bg-blue-100" 
              required
            />
          </div>
          <div className="flex justify-end gap-3 mt-6">
            <button type="button" onClick={() => setUploadModalOpen(false)} className="px-4 py-2 text-secondaryText hover:text-primaryText font-medium">Cancel</button>
            <button type="submit" disabled={uploading || !uploadFile} className="btn-primary flex items-center gap-2">
              {uploading ? 'Uploading...' : 'Upload'}
            </button>
          </div>
        </form>
      </Modal>

      <Modal isOpen={invalidQuestionsModalOpen} onClose={() => setInvalidQuestionsModalOpen(false)} title="Some Questions Failed">
        <div className="space-y-4">
          <p className="text-sm text-secondaryText">The following questions did not match the required multiple-choice format and were skipped:</p>
          <div className="max-h-60 overflow-y-auto bg-gray-50 rounded-md p-3 border border-border">
            <ul className="list-disc pl-5 text-sm text-error space-y-1">
              {invalidQuestions.map((iq, idx) => (
                <li key={idx}>{iq}</li>
              ))}
            </ul>
          </div>
          <div className="flex justify-end mt-4">
            <button onClick={() => setInvalidQuestionsModalOpen(false)} className="btn-primary">Acknowledge</button>
          </div>
        </div>
      </Modal>
    </div>
  );
};

export default TestQuestions;
