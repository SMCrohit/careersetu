import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { 
  ArrowLeft, Plus, Trash2, Edit2, X, Upload, Image as ImageIcon,
  FileSpreadsheet, Download, CheckCircle, AlertCircle, Loader2
} from 'lucide-react';
import ConfirmDialog from '../components/ConfirmDialog';
import Modal from '../components/Modal';
import { useToast } from '../context/ToastContext';
import CreatableSelect from 'react-select/creatable';
import * as XLSX from 'xlsx';

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

  // Bulk Upload state
  const [uploadModalOpen, setUploadModalOpen] = useState(false);
  const [uploadFileName, setUploadFileName] = useState('');
  const [parsedQuestions, setParsedQuestions] = useState<any[]>([]);
  const [uploadErrors, setUploadErrors] = useState<string[]>([]);
  const [isUploading, setIsUploading] = useState(false);

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
      const payload: any = { ...formData };
      delete payload.id;
      delete payload.test_id;
      delete payload.created_datetime;
      delete payload.deleted_datetime;
      delete payload.is_active;

      if (payload.question_type === 'true_false') {
        payload.options = [
          { id: '1', text: 'True' },
          { id: '2', text: 'False' }
        ];
      }
      
      // Clean numbers and optional overrides
      payload.marks = payload.marks ? parseFloat(payload.marks) : 1.0;
      payload.negative_marks = (payload.negative_marks !== '' && payload.negative_marks !== null && payload.negative_marks !== undefined) 
        ? parseFloat(payload.negative_marks) 
        : null;
      payload.time_limit_seconds = (payload.time_limit_seconds !== '' && payload.time_limit_seconds !== null && payload.time_limit_seconds !== undefined) 
        ? parseInt(payload.time_limit_seconds) 
        : null;
      payload.order_index = payload.order_index ? parseInt(payload.order_index) : 0;

      if (editingId) {
        await api.put(`/tests/${id}/questions/${editingId}`, payload);
        showToast("Question updated successfully", "success");
      } else {
        await api.post(`/tests/${id}/questions`, payload);
        showToast("Question added successfully", "success");
      }

      await fetchTestAndQuestions();
      
      if (addAnother) {
        openAddForm();
      } else {
        setIsFormView(false);
      }
    } catch (error: any) {
      const errorMsg = error?.response?.data?.detail 
        ? (typeof error.response.data.detail === 'string' 
            ? error.response.data.detail 
            : JSON.stringify(error.response.data.detail))
        : "Failed to save question";
      showToast(errorMsg, "error");
    } finally {
      setSaving(false);
    }
  };

  // Sample template downloads
  const downloadSampleCSV = () => {
    const csvContent = [
      'question_text,question_type,option_1,option_2,option_3,option_4,correct_answer,marks,negative_marks,time_limit_seconds,section,topic,subtopic,difficulty,explanation',
      '"What is the time complexity of searching in a balanced BST?",single_select,"O(1)","O(n)","O(log n)","O(n^2)","O(log n)",1.0,0.25,60,"Computer Science","Data Structures","Trees","Medium","Balanced BST search takes O(log n) time."',
      '"Which of the following numbers are prime?",multi_select,"2","4","7","9","2||7",2.0,0.5,60,"Mathematics","Number Theory","Primes","Medium","2 and 7 are prime numbers."',
      '"Python is an interpreted programming language.",true_false,"True","False",,,"True",1.0,0.25,45,"Computer Science","Programming","Python","Easy","Python code is executed line-by-line by an interpreter."',
      '"What does CPU stand for?",single_select,"Central Processing Unit","Computer Personal Unit","Central Processor Universal","Control Processing Unit","Central Processing Unit",1.0,0.25,60,"General IT","Hardware","Architecture","Easy","CPU stands for Central Processing Unit."'
    ].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'sample_questions_template.csv';
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };

  const downloadSampleXLSX = () => {
    const sampleRows = [
      {
        question_text: "What is the time complexity of searching in a balanced BST?",
        question_type: "single_select",
        option_1: "O(1)",
        option_2: "O(n)",
        option_3: "O(log n)",
        option_4: "O(n^2)",
        correct_answer: "O(log n)",
        marks: 1.0,
        negative_marks: 0.25,
        time_limit_seconds: 60,
        section: "Computer Science",
        topic: "Data Structures",
        subtopic: "Trees",
        difficulty: "Medium",
        explanation: "Balanced BST search takes O(log n) time."
      },
      {
        question_text: "Which of the following numbers are prime?",
        question_type: "multi_select",
        option_1: "2",
        option_2: "4",
        option_3: "7",
        option_4: "9",
        correct_answer: "2||7",
        marks: 2.0,
        negative_marks: 0.5,
        time_limit_seconds: 60,
        section: "Mathematics",
        topic: "Number Theory",
        subtopic: "Primes",
        difficulty: "Medium",
        explanation: "2 and 7 are prime numbers."
      },
      {
        question_text: "Python is an interpreted programming language.",
        question_type: "true_false",
        option_1: "True",
        option_2: "False",
        option_3: "",
        option_4: "",
        correct_answer: "True",
        marks: 1.0,
        negative_marks: 0.25,
        time_limit_seconds: 45,
        section: "Computer Science",
        topic: "Programming",
        subtopic: "Python",
        difficulty: "Easy",
        explanation: "Python code is executed line-by-line by an interpreter."
      },
      {
        question_text: "What does CPU stand for?",
        question_type: "single_select",
        option_1: "Central Processing Unit",
        option_2: "Computer Personal Unit",
        option_3: "Central Processor Universal",
        option_4: "Control Processing Unit",
        correct_answer: "Central Processing Unit",
        marks: 1.0,
        negative_marks: 0.25,
        time_limit_seconds: 60,
        section: "General IT",
        topic: "Hardware",
        subtopic: "Architecture",
        difficulty: "Easy",
        explanation: "CPU stands for Central Processing Unit."
      }
    ];
    const ws = XLSX.utils.json_to_sheet(sampleRows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Questions");
    XLSX.writeFile(wb, "sample_questions_template.xlsx");
  };

  const handleBulkFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadFileName(file.name);
    setUploadErrors([]);
    setParsedQuestions([]);

    const reader = new FileReader();
    reader.onload = (evt) => {
      try {
        const bstr = evt.target?.result;
        const wb = XLSX.read(bstr, { type: 'binary' });
        const wsName = wb.SheetNames[0];
        const ws = wb.Sheets[wsName];
        const rows: any[] = XLSX.utils.sheet_to_json(ws, { defval: '' });

        if (!rows || rows.length === 0) {
          setUploadErrors(["File is empty or contains no readable rows."]);
          return;
        }

        const validQuestions: any[] = [];
        const errors: string[] = [];

        rows.forEach((row, idx) => {
          const rowNum = idx + 2;
          const getVal = (...keys: string[]) => {
            for (const k of keys) {
              for (const rowKey of Object.keys(row)) {
                if (rowKey.trim().toLowerCase() === k.toLowerCase()) {
                  return String(row[rowKey] || '').trim();
                }
              }
            }
            return '';
          };

          const qText = getVal('question_text', 'question', 'question text', 'question_title');
          if (!qText) {
            errors.push(`Row ${rowNum}: Skipped (Missing question text)`);
            return;
          }

          let qType = getVal('question_type', 'type', 'question type').toLowerCase().replace(/[\s-]/g, '_');
          if (!['single_select', 'multi_select', 'true_false'].includes(qType)) {
            qType = 'single_select';
          }

          let options: { id: string; text: string }[] = [];
          if (qType === 'true_false') {
            options = [
              { id: '1', text: 'True' },
              { id: '2', text: 'False' }
            ];
          } else {
            for (let optIdx = 1; optIdx <= 10; optIdx++) {
              const optVal = getVal(`option_${optIdx}`, `option ${optIdx}`, `option${optIdx}`, `choice_${optIdx}`, `choice ${optIdx}`);
              if (optVal) {
                options.push({ id: String(options.length + 1), text: optVal });
              }
            }
            if (options.length < 2) {
              errors.push(`Row ${rowNum}: Skipped (At least 2 options required, found ${options.length})`);
              return;
            }
          }

          let correctAns = getVal('correct_answer', 'answer', 'correct answer', 'correct');
          if (!correctAns) {
            errors.push(`Row ${rowNum}: Skipped (Missing correct answer)`);
            return;
          }

          if (qType !== 'true_false') {
            const optIndex = parseInt(correctAns);
            if (!isNaN(optIndex) && optIndex >= 1 && optIndex <= options.length) {
              correctAns = options[optIndex - 1].text;
            }
          } else {
            if (correctAns.toLowerCase() === 't' || correctAns.toLowerCase() === '1') correctAns = 'True';
            if (correctAns.toLowerCase() === 'f' || correctAns.toLowerCase() === '0') correctAns = 'False';
          }

          const marksVal = parseFloat(getVal('marks', 'mark')) || 1.0;
          const negValRaw = getVal('negative_marks', 'negative marks', 'negative mark');
          const negVal = negValRaw !== '' ? parseFloat(negValRaw) : null;
          const timeValRaw = getVal('time_limit_seconds', 'time limit', 'time_limit');
          const timeVal = timeValRaw !== '' ? parseInt(timeValRaw) : null;

          const section = getVal('section');
          const topic = getVal('topic');
          const subtopic = getVal('subtopic');
          const difficulty = getVal('difficulty') || 'Medium';
          const explanation = getVal('explanation', 'solution');

          validQuestions.push({
            question_text: qText,
            question_type: qType,
            options,
            correct_answer: correctAns,
            marks: marksVal,
            negative_marks: negVal,
            time_limit_seconds: timeVal,
            section: section || null,
            topic: topic || null,
            subtopic: subtopic || null,
            difficulty,
            explanation: explanation || null,
            order_index: validQuestions.length + 1
          });
        });

        setParsedQuestions(validQuestions);
        setUploadErrors(errors);
        if (validQuestions.length === 0) {
          showToast("No valid questions could be extracted from file", "error");
        } else {
          showToast(`Parsed ${validQuestions.length} valid questions from ${file.name}`, "success");
        }
      } catch (err) {
        showToast("Failed to parse file", "error");
      }
    };
    reader.readAsBinaryString(file);
    e.target.value = '';
  };

  const handleExecuteBulkUpload = async () => {
    if (parsedQuestions.length === 0) return;
    setIsUploading(true);
    try {
      const res = await api.post(`/tests/${id}/questions/bulk`, { questions: parsedQuestions });
      showToast(`Successfully imported ${res.data.count || parsedQuestions.length} questions!`, "success");
      setUploadModalOpen(false);
      setParsedQuestions([]);
      setUploadErrors([]);
      setUploadFileName('');
      await fetchTestAndQuestions();
    } catch (error: any) {
      const msg = error?.response?.data?.detail 
        ? (typeof error.response.data.detail === 'string' ? error.response.data.detail : JSON.stringify(error.response.data.detail))
        : "Failed to upload questions";
      showToast(msg, "error");
    } finally {
      setIsUploading(false);
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
              <button 
                type="button"
                onClick={() => {
                  setUploadModalOpen(true);
                  setParsedQuestions([]);
                  setUploadErrors([]);
                  setUploadFileName('');
                }} 
                className="px-4 py-2 border border-gray-300 text-secondaryText font-medium rounded-md hover:bg-gray-50 transition-colors flex items-center gap-2"
              >
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

      {/* Bulk Upload Modal */}
      <Modal
        isOpen={uploadModalOpen}
        onClose={() => {
          if (!isUploading) {
            setUploadModalOpen(false);
            setParsedQuestions([]);
            setUploadErrors([]);
            setUploadFileName('');
          }
        }}
        title="Bulk Upload Questions"
      >
        <div className="space-y-6">
          {/* Instructions & Sample Download */}
          <div className="bg-blue-50/60 p-4 rounded-xl border border-blue-100 space-y-3">
            <div>
              <h4 className="text-sm font-bold text-blue-900">Step 1: Download Sample Template</h4>
              <p className="text-xs text-blue-700 mt-1">
                Use our sample template to format your questions correctly before uploading. Supports Single Select, Multi Select, and True/False questions.
              </p>
            </div>
            <div className="flex flex-wrap gap-2 pt-1">
              <button
                type="button"
                onClick={downloadSampleCSV}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-white text-blue-700 rounded-lg text-xs font-semibold hover:bg-blue-100 transition-colors border border-blue-200 shadow-xs"
              >
                <Download size={14} /> Download Sample CSV
              </button>
              <button
                type="button"
                onClick={downloadSampleXLSX}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 text-white rounded-lg text-xs font-semibold hover:bg-blue-700 transition-colors shadow-xs"
              >
                <FileSpreadsheet size={14} /> Download Sample Excel (.xlsx)
              </button>
            </div>
          </div>

          {/* File Upload Zone */}
          <div>
            <h4 className="text-sm font-bold text-primaryText mb-2">Step 2: Upload Completed File</h4>
            <label className="flex flex-col items-center justify-center p-6 border-2 border-dashed border-gray-300 rounded-xl hover:border-primaryBrand bg-backgroundLight cursor-pointer transition-colors group">
              <Upload className="text-gray-400 group-hover:text-primaryBrand mb-2" size={32} />
              <p className="text-sm font-medium text-primaryText">
                {uploadFileName ? uploadFileName : "Click to browse or drag & drop"}
              </p>
              <p className="text-xs text-secondaryText mt-1">Supports .xlsx, .xls, and .csv files</p>
              <input
                type="file"
                className="hidden"
                accept=".xlsx, .xls, .csv"
                onChange={handleBulkFileChange}
              />
            </label>
          </div>

          {/* Validation Errors Warning */}
          {uploadErrors.length > 0 && (
            <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl space-y-1">
              <div className="flex items-center gap-1.5 text-amber-800 text-xs font-semibold">
                <AlertCircle size={14} /> {uploadErrors.length} Warning(s) / Skipped Row(s):
              </div>
              <ul className="text-xs text-amber-700 list-disc list-inside max-h-24 overflow-y-auto space-y-0.5">
                {uploadErrors.map((err, i) => (
                  <li key={i}>{err}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Parsed Preview */}
          {parsedQuestions.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center justify-between text-xs font-semibold text-green-700 bg-green-50 p-2.5 rounded-lg border border-green-200">
                <span className="flex items-center gap-1.5">
                  <CheckCircle size={16} /> Ready to import {parsedQuestions.length} question(s)
                </span>
                <span className="text-secondaryText font-normal">Showing first 5 previewed</span>
              </div>

              <div className="border border-border rounded-lg overflow-hidden max-h-56 overflow-y-auto">
                <table className="w-full text-xs text-left">
                  <thead className="bg-background font-semibold text-secondaryText border-b border-border sticky top-0">
                    <tr>
                      <th className="p-2 w-8">#</th>
                      <th className="p-2">Question</th>
                      <th className="p-2 w-24">Type</th>
                      <th className="p-2">Correct Answer</th>
                      <th className="p-2 w-16">Marks</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {parsedQuestions.slice(0, 5).map((q, idx) => (
                      <tr key={idx} className="hover:bg-background/40">
                        <td className="p-2 font-medium">{idx + 1}</td>
                        <td className="p-2 truncate max-w-xs" title={q.question_text}>{q.question_text}</td>
                        <td className="p-2 uppercase text-[10px] text-secondaryText">{q.question_type}</td>
                        <td className="p-2 text-green-700 font-medium truncate max-w-[120px]" title={q.correct_answer}>{q.correct_answer}</td>
                        <td className="p-2">{q.marks}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Footer Actions */}
          <div className="flex justify-end gap-3 pt-3 border-t border-border">
            <button
              type="button"
              disabled={isUploading}
              onClick={() => {
                setUploadModalOpen(false);
                setParsedQuestions([]);
                setUploadErrors([]);
                setUploadFileName('');
              }}
              className="px-4 py-2 text-sm text-secondaryText font-medium hover:text-primaryText"
            >
              Cancel
            </button>
            <button
              type="button"
              disabled={parsedQuestions.length === 0 || isUploading}
              onClick={handleExecuteBulkUpload}
              className="btn-primary inline-flex items-center gap-2 text-sm disabled:opacity-50"
            >
              {isUploading ? (
                <>
                  <Loader2 size={16} className="animate-spin" /> Importing Questions...
                </>
              ) : (
                `Import ${parsedQuestions.length} Question(s)`
              )}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};

export default TestQuestions;
