import React, { useState } from 'react';
import { 
  FileText, Briefcase, GraduationCap, Award, MapPin, 
  Phone, Mail, Globe, Download, Eye, Sparkles, 
  CheckCircle2, FolderGit2, ExternalLink,
  ChevronDown, ChevronUp, Copy, Check
} from 'lucide-react';
import Modal from './Modal';

// Helper to compute human readable file size from base64 string
export const getBase64FileSize = (b64?: string): string => {
  if (!b64) return 'Unknown size';
  try {
    // Each base64 char is roughly 6 bits (0.75 byte)
    const padding = (b64.endsWith('==') ? 2 : b64.endsWith('=') ? 1 : 0);
    const bytes = (b64.length * 0.75) - padding;
    if (bytes < 1024) return `${Math.max(1, Math.round(bytes))} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
  } catch {
    return 'Unknown size';
  }
};

interface AiExtractionPreviewProps {
  data: any;
  onOpenFullResume?: () => void;
}

export const AiExtractionPreview: React.FC<AiExtractionPreviewProps> = ({ data, onOpenFullResume }) => {
  const [expanded, setExpanded] = useState(false);

  if (!data || (typeof data === 'object' && Object.keys(data).length === 0)) {
    return null;
  }

  // Parse if string
  let parsed = data;
  if (typeof data === 'string') {
    try {
      parsed = JSON.parse(data);
    } catch {
      return (
        <div className="bg-purple-50/50 p-4 rounded-xl border border-purple-100 text-sm text-gray-700">
          <p className="text-gray-800 leading-relaxed whitespace-pre-wrap">{data}</p>
        </div>
      );
    }
  }

  const {
    full_name,
    headline,
    email,
    phone,
    city,
    summary,
    skills,
    experience,
    education,
    projects,
    certifications,
    languages,
    links
  } = parsed || {};

  const skillsList: string[] = Array.isArray(skills) 
    ? skills 
    : typeof skills === 'string' 
      ? skills.split(',').map((s: string) => s.trim()).filter(Boolean)
      : [];

  const expList = Array.isArray(experience) ? experience : [];
  const eduList = Array.isArray(education) ? education : [];
  const projList = Array.isArray(projects) ? projects : [];
  const certList = Array.isArray(certifications) ? certifications : [];
  const langList = Array.isArray(languages) ? languages : [];

  const hasExtraSections = expList.length > 0 || eduList.length > 0 || projList.length > 0 || certList.length > 0;

  return (
    <div className="bg-white rounded-xl border border-purple-100 shadow-sm overflow-hidden text-sm">
      {/* Header bar */}
      <div className="bg-gradient-to-r from-purple-50 via-white to-purple-50/30 px-5 py-3.5 border-b border-purple-100 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Sparkles size={16} className="text-purple-600" />
          <span className="font-bold text-gray-900 text-sm">AI Extracted Candidate Details</span>
        </div>
        {onOpenFullResume && (
          <button 
            type="button"
            onClick={onOpenFullResume}
            className="text-xs font-semibold text-purple-700 hover:text-purple-800 flex items-center gap-1 hover:underline"
          >
            Open Document View <ExternalLink size={12} />
          </button>
        )}
      </div>

      <div className="p-5 space-y-4">
        {/* Name and headline */}
        {(full_name || headline) && (
          <div className="flex flex-wrap items-baseline gap-2">
            {full_name && <h4 className="text-base font-bold text-gray-900">{full_name}</h4>}
            {headline && (
              <span className="px-2.5 py-0.5 bg-purple-100 text-purple-800 text-xs font-semibold rounded-full">
                {headline}
              </span>
            )}
          </div>
        )}

        {/* Contact Info Chips */}
        {(email || phone || city) && (
          <div className="flex flex-wrap gap-2 text-xs">
            {email && (
              <span className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-gray-50 border border-gray-200 text-gray-700 rounded-lg">
                <Mail size={13} className="text-purple-600" />
                <span>{email}</span>
              </span>
            )}
            {phone && (
              <span className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-gray-50 border border-gray-200 text-gray-700 rounded-lg">
                <Phone size={13} className="text-purple-600" />
                <span>{phone}</span>
              </span>
            )}
            {city && (
              <span className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-gray-50 border border-gray-200 text-gray-700 rounded-lg">
                <MapPin size={13} className="text-purple-600" />
                <span>{city}</span>
              </span>
            )}
          </div>
        )}

        {/* Professional Summary */}
        {summary && (
          <div className="bg-purple-50/40 border-l-4 border-purple-500 rounded-r-lg p-3 text-gray-700">
            <p className="text-xs font-semibold text-purple-900 mb-1 uppercase tracking-wide">Professional Summary</p>
            <p className="text-xs text-gray-600 leading-relaxed">{summary}</p>
          </div>
        )}

        {/* Skills */}
        {skillsList.length > 0 && (
          <div>
            <p className="text-xs font-semibold text-gray-700 mb-2 uppercase tracking-wide">Key Skills</p>
            <div className="flex flex-wrap gap-1.5">
              {skillsList.map((skill, idx) => (
                <span 
                  key={idx}
                  className="px-2.5 py-1 bg-purple-50 text-purple-700 border border-purple-200 text-xs font-medium rounded-md"
                >
                  {skill}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Languages & Links */}
        {(langList.length > 0 || links?.linkedin || links?.github || links?.portfolio) && (
          <div className="flex flex-wrap items-center gap-2 pt-1 text-xs">
            {langList.map((lang: string, idx: number) => (
              <span key={idx} className="px-2 py-0.5 bg-gray-100 text-gray-700 rounded text-[11px]">
                {lang}
              </span>
            ))}
            {links?.linkedin && (
              <a href={links.linkedin} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-purple-600 hover:underline">
                <Globe size={12} /> LinkedIn
              </a>
            )}
            {links?.github && (
              <a href={links.github} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-purple-600 hover:underline">
                <FolderGit2 size={12} /> GitHub
              </a>
            )}
            {links?.portfolio && (
              <a href={links.portfolio} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-purple-600 hover:underline">
                <Globe size={12} /> Portfolio
              </a>
            )}
          </div>
        )}

        {/* Collapsible extra sections if experience/education exist */}
        {hasExtraSections && (
          <div>
            <button
              type="button"
              onClick={() => setExpanded(!expanded)}
              className="w-full mt-2 py-2 px-3 bg-gray-50 hover:bg-gray-100 border border-gray-200 rounded-lg text-xs font-semibold text-gray-700 flex items-center justify-between transition"
            >
              <span>{expanded ? 'Hide Additional Sections' : 'Show Work Experience & Education'}</span>
              {expanded ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            </button>

            {expanded && (
              <div className="mt-3 pt-3 border-t border-gray-100 space-y-4">
                {/* Experience */}
                {expList.length > 0 && (
                  <div>
                    <p className="text-xs font-bold text-gray-800 mb-2 flex items-center gap-1.5">
                      <Briefcase size={14} className="text-purple-600" /> Experience ({expList.length})
                    </p>
                    <div className="space-y-2">
                      {expList.map((exp: any, i: number) => (
                        <div key={i} className="bg-gray-50/80 p-3 rounded-lg border border-gray-200/70 text-xs">
                          <div className="flex justify-between items-start">
                            <div>
                              <p className="font-bold text-gray-900">{exp.title || 'Role not specified'}</p>
                              <p className="text-gray-600">{exp.company}{exp.location ? ` • ${exp.location}` : ''}</p>
                            </div>
                            <span className="text-gray-500 text-[11px] font-medium">
                              {exp.start || ''} {exp.end ? `- ${exp.end}` : ''}
                            </span>
                          </div>
                          {Array.isArray(exp.bullets) && exp.bullets.length > 0 && (
                            <ul className="list-disc list-inside mt-2 space-y-1 text-gray-600 text-[11px]">
                              {exp.bullets.map((b: string, bi: number) => (
                                <li key={bi}>{b}</li>
                              ))}
                            </ul>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Education */}
                {eduList.length > 0 && (
                  <div>
                    <p className="text-xs font-bold text-gray-800 mb-2 flex items-center gap-1.5">
                      <GraduationCap size={14} className="text-purple-600" /> Education ({eduList.length})
                    </p>
                    <div className="space-y-2">
                      {eduList.map((edu: any, i: number) => (
                        <div key={i} className="bg-gray-50/80 p-3 rounded-lg border border-gray-200/70 text-xs">
                          <div className="flex justify-between items-start">
                            <div>
                              <p className="font-bold text-gray-900">{edu.degree || 'Degree'}</p>
                              <p className="text-gray-600">{edu.school}</p>
                            </div>
                            <div className="text-right">
                              <span className="text-gray-500 text-[11px]">
                                {edu.start || ''} {edu.end ? `- ${edu.end}` : ''}
                              </span>
                              {edu.score && <p className="text-purple-700 font-semibold text-[11px]">Score: {edu.score}</p>}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Projects */}
                {projList.length > 0 && (
                  <div>
                    <p className="text-xs font-bold text-gray-800 mb-2 flex items-center gap-1.5">
                      <FolderGit2 size={14} className="text-purple-600" /> Projects ({projList.length})
                    </p>
                    <div className="space-y-2">
                      {projList.map((proj: any, i: number) => (
                        <div key={i} className="bg-gray-50/80 p-3 rounded-lg border border-gray-200/70 text-xs">
                          <p className="font-bold text-gray-900">{proj.title}</p>
                          {proj.description && <p className="text-gray-600 mt-1">{proj.description}</p>}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Certifications */}
                {certList.length > 0 && (
                  <div>
                    <p className="text-xs font-bold text-gray-800 mb-2 flex items-center gap-1.5">
                      <Award size={14} className="text-purple-600" /> Certifications ({certList.length})
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {certList.map((cert: any, i: number) => (
                        <span key={i} className="px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs text-gray-700">
                          <strong>{cert.title}</strong> {cert.organization ? `by ${cert.organization}` : ''} {cert.year ? `(${cert.year})` : ''}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

interface UploadedDocumentDetailsProps {
  resumeData: any;
  onPreview: () => void;
  onDownload: () => void;
}

export const UploadedDocumentDetails: React.FC<UploadedDocumentDetailsProps> = ({
  resumeData,
  onPreview,
  onDownload
}) => {
  if (!resumeData || typeof resumeData !== 'object') {
    return null;
  }

  const filename = resumeData.filename || 'Uploaded_Resume.pdf';
  const fileSize = getBase64FileSize(resumeData.data);
  const isPdf = filename.toLowerCase().endsWith('.pdf');

  return (
    <div className="border border-blue-100 bg-blue-50/30 rounded-xl p-6">
      {/* Top Header Card */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-blue-100 text-blue-600 rounded-xl flex items-center justify-center shrink-0 shadow-sm">
            <FileText size={28} />
          </div>
          <div>
            <h3 className="text-lg font-bold text-gray-900 break-all">{filename}</h3>
            <div className="flex items-center gap-2 mt-1">
              <span className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded text-xs font-semibold">
                {isPdf ? 'PDF Document' : 'Document'}
              </span>
              <span className="text-xs text-gray-500">• {fileSize}</span>
              <span className="text-xs text-green-600 font-medium flex items-center gap-1">
                <CheckCircle2 size={13} /> Verified
              </span>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-3">
          <button 
            type="button"
            onClick={onPreview} 
            className="flex items-center gap-2 px-4 py-2.5 bg-white border border-gray-200 rounded-lg text-gray-700 hover:bg-gray-50 hover:text-blue-600 transition shadow-sm text-sm font-semibold"
            title="Preview in new tab"
          >
            <Eye size={16} /> Preview
          </button>
          <button 
            type="button"
            onClick={onDownload} 
            className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition shadow-sm"
          >
            <Download size={16} /> Download
          </button>
        </div>
      </div>

      {/* Structured Document Specs Grid */}
      <div className="bg-white rounded-xl border border-blue-100 p-5 shadow-sm">
        <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-4">Document Specifications</h4>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs">
          <div className="p-3 bg-gray-50 rounded-lg border border-gray-100">
            <span className="text-gray-500 block mb-1">File Name</span>
            <span className="font-semibold text-gray-900 truncate block" title={filename}>{filename}</span>
          </div>
          <div className="p-3 bg-gray-50 rounded-lg border border-gray-100">
            <span className="text-gray-500 block mb-1">File Type</span>
            <span className="font-semibold text-gray-900 block">{isPdf ? 'application/pdf' : 'Document file'}</span>
          </div>
          <div className="p-3 bg-gray-50 rounded-lg border border-gray-100">
            <span className="text-gray-500 block mb-1">Payload Size</span>
            <span className="font-semibold text-gray-900 block">{fileSize}</span>
          </div>
          <div className="p-3 bg-gray-50 rounded-lg border border-gray-100">
            <span className="text-gray-500 block mb-1">Status</span>
            <span className="font-semibold text-emerald-700 flex items-center gap-1">
              <CheckCircle2 size={13} className="text-emerald-600" /> Ready to View
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

interface AiResumeModalProps {
  session: any;
  isOpen: boolean;
  onClose: () => void;
}

export const AiResumeModal: React.FC<AiResumeModalProps> = ({ session, isOpen, onClose }) => {
  const [copied, setCopied] = useState(false);

  if (!isOpen || !session) return null;

  const data = typeof session.extracted_data === 'string'
    ? (() => { try { return JSON.parse(session.extracted_data); } catch { return {}; } })()
    : (session.extracted_data || {});

  const {
    full_name,
    headline,
    email,
    phone,
    city,
    summary,
    skills,
    experience,
    education,
    projects,
    certifications,
    languages,
    links
  } = data;

  const skillsList: string[] = Array.isArray(skills) 
    ? skills 
    : typeof skills === 'string' 
      ? skills.split(',').map((s: string) => s.trim()).filter(Boolean)
      : [];

  const expList = Array.isArray(experience) ? experience : [];
  const eduList = Array.isArray(education) ? education : [];
  const projList = Array.isArray(projects) ? projects : [];
  const certList = Array.isArray(certifications) ? certifications : [];
  const langList = Array.isArray(languages) ? languages : [];

  const handleCopyText = () => {
    const lines: string[] = [];
    if (full_name) lines.push(full_name);
    if (headline) lines.push(headline);
    const contact = [email, phone, city].filter(Boolean).join(' | ');
    if (contact) lines.push(contact);
    if (summary) lines.push(`\nSUMMARY:\n${summary}`);
    if (skillsList.length > 0) lines.push(`\nSKILLS:\n${skillsList.join(', ')}`);
    if (expList.length > 0) {
      lines.push('\nEXPERIENCE:');
      expList.forEach((e: any) => {
        lines.push(`${e.title || ''} at ${e.company || ''} (${e.start || ''} - ${e.end || ''})`);
        if (Array.isArray(e.bullets)) e.bullets.forEach((b: string) => lines.push(`  • ${b}`));
      });
    }
    if (eduList.length > 0) {
      lines.push('\nEDUCATION:');
      eduList.forEach((ed: any) => {
        lines.push(`${ed.degree || ''} - ${ed.school || ''} (${ed.start || ''} - ${ed.end || ''})`);
      });
    }

    navigator.clipboard.writeText(lines.join('\n'));
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="AI Generated Resume">
      <div className="space-y-6">
        {/* Top actions */}
        <div className="flex justify-between items-center bg-gray-50 p-3 rounded-lg border border-gray-200">
          <div className="flex items-center gap-2">
            <span className={`px-2.5 py-1 text-xs font-bold rounded uppercase ${session.status === 'completed' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}>
              {session.status}
            </span>
            <span className="text-xs text-gray-500">
              Generated on {new Date(session.created_datetime).toLocaleDateString()}
            </span>
          </div>
          <button
            type="button"
            onClick={handleCopyText}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-white border border-gray-200 hover:bg-gray-100 text-gray-700 rounded-lg text-xs font-semibold transition"
          >
            {copied ? <Check size={14} className="text-green-600" /> : <Copy size={14} />}
            {copied ? 'Copied Resume' : 'Copy Text'}
          </button>
        </div>

        {/* Formatted Resume Document */}
        <div className="bg-white border border-gray-200 rounded-xl p-8 shadow-sm space-y-6 text-gray-800">
          {/* Header */}
          <div className="border-b border-gray-200 pb-5 text-center sm:text-left">
            <h1 className="text-2xl font-bold text-gray-900 tracking-tight">{full_name || 'Candidate Name'}</h1>
            {headline && <p className="text-purple-700 font-semibold text-base mt-1">{headline}</p>}
            
            <div className="flex flex-wrap justify-center sm:justify-start gap-4 mt-3 text-xs text-gray-600">
              {email && <span className="flex items-center gap-1"><Mail size={13} className="text-purple-600"/> {email}</span>}
              {phone && <span className="flex items-center gap-1"><Phone size={13} className="text-purple-600"/> {phone}</span>}
              {city && <span className="flex items-center gap-1"><MapPin size={13} className="text-purple-600"/> {city}</span>}
              {links?.linkedin && <span className="flex items-center gap-1"><Globe size={13} className="text-purple-600"/> LinkedIn</span>}
              {links?.github && <span className="flex items-center gap-1"><FolderGit2 size={13} className="text-purple-600"/> GitHub</span>}
            </div>
          </div>

          {/* Summary */}
          {summary && (
            <div>
              <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider border-b border-gray-200 pb-1 mb-2">
                Professional Summary
              </h3>
              <p className="text-sm text-gray-700 leading-relaxed">{summary}</p>
            </div>
          )}

          {/* Skills */}
          {skillsList.length > 0 && (
            <div>
              <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider border-b border-gray-200 pb-1 mb-2">
                Core Skills
              </h3>
              <div className="flex flex-wrap gap-1.5">
                {skillsList.map((skill, i) => (
                  <span key={i} className="px-2.5 py-1 bg-purple-50 text-purple-700 border border-purple-200 rounded text-xs font-medium">
                    {skill}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Work Experience */}
          {expList.length > 0 && (
            <div>
              <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider border-b border-gray-200 pb-1 mb-3">
                Professional Experience
              </h3>
              <div className="space-y-4">
                {expList.map((exp: any, i: number) => (
                  <div key={i}>
                    <div className="flex justify-between items-baseline">
                      <h4 className="font-bold text-gray-900 text-sm">{exp.title}</h4>
                      <span className="text-xs text-gray-500 font-medium">
                        {exp.start} {exp.end ? `- ${exp.end}` : ''}
                      </span>
                    </div>
                    <p className="text-xs font-medium text-gray-700">{exp.company} {exp.location ? `• ${exp.location}` : ''}</p>
                    {Array.isArray(exp.bullets) && exp.bullets.length > 0 && (
                      <ul className="list-disc list-inside mt-2 space-y-1 text-xs text-gray-600">
                        {exp.bullets.map((b: string, bi: number) => (
                          <li key={bi}>{b}</li>
                        ))}
                      </ul>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Education */}
          {eduList.length > 0 && (
            <div>
              <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider border-b border-gray-200 pb-1 mb-3">
                Education
              </h3>
              <div className="space-y-3">
                {eduList.map((edu: any, i: number) => (
                  <div key={i} className="flex justify-between items-start">
                    <div>
                      <h4 className="font-bold text-gray-900 text-sm">{edu.degree}</h4>
                      <p className="text-xs text-gray-600">{edu.school}</p>
                    </div>
                    <div className="text-right">
                      <span className="text-xs text-gray-500 font-medium">
                        {edu.start} {edu.end ? `- ${edu.end}` : ''}
                      </span>
                      {edu.score && <p className="text-xs text-purple-700 font-semibold">Score: {edu.score}</p>}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Projects */}
          {projList.length > 0 && (
            <div>
              <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider border-b border-gray-200 pb-1 mb-3">
                Key Projects
              </h3>
              <div className="space-y-3">
                {projList.map((proj: any, i: number) => (
                  <div key={i}>
                    <h4 className="font-bold text-gray-900 text-sm">{proj.title}</h4>
                    {proj.description && <p className="text-xs text-gray-600 mt-1">{proj.description}</p>}
                    {Array.isArray(proj.bullets) && proj.bullets.length > 0 && (
                      <ul className="list-disc list-inside mt-1.5 space-y-0.5 text-xs text-gray-600">
                        {proj.bullets.map((b: string, bi: number) => (
                          <li key={bi}>{b}</li>
                        ))}
                      </ul>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Certifications & Languages */}
          {(certList.length > 0 || langList.length > 0) && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
              {certList.length > 0 && (
                <div>
                  <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider border-b border-gray-200 pb-1 mb-2">
                    Certifications
                  </h3>
                  <div className="space-y-1.5 text-xs text-gray-700">
                    {certList.map((cert: any, i: number) => (
                      <p key={i}>
                        <span className="font-semibold text-gray-900">{cert.title}</span>
                        {cert.organization ? ` — ${cert.organization}` : ''}
                        {cert.year ? ` (${cert.year})` : ''}
                      </p>
                    ))}
                  </div>
                </div>
              )}

              {langList.length > 0 && (
                <div>
                  <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider border-b border-gray-200 pb-1 mb-2">
                    Languages
                  </h3>
                  <div className="flex flex-wrap gap-1.5">
                    {langList.map((l: string, i: number) => (
                      <span key={i} className="px-2.5 py-1 bg-gray-100 text-gray-700 rounded text-xs">
                        {l}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </Modal>
  );
};

export const AiReportViewer: React.FC<{ report: any }> = ({ report }) => {
  if (!report) return null;
  if (typeof report === 'string') {
    return <p className="text-sm text-gray-700 leading-relaxed whitespace-pre-wrap">{report}</p>;
  }

  const { overall_insight, strong_areas, weak_areas, time_management, next_steps } = report;

  return (
    <div className="space-y-3 text-xs">
      {overall_insight && (
        <p className="text-gray-800 leading-relaxed font-medium">{overall_insight}</p>
      )}
      {time_management && (
        <div className="bg-white/80 p-2.5 rounded-lg border border-purple-100 text-gray-600">
          <strong className="text-purple-800">Pacing & Timing: </strong>
          {time_management}
        </div>
      )}
      {Array.isArray(strong_areas) && strong_areas.length > 0 && (
        <div>
          <span className="font-semibold text-emerald-800 block mb-1">Strengths:</span>
          <div className="flex flex-wrap gap-1.5">
            {strong_areas.map((s: any, idx: number) => (
              <span key={idx} className="px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded font-medium">
                {typeof s === 'string' ? s : `${s.topic || s.subtopic || 'Topic'} (${s.accuracy ?? 0}%)`}
              </span>
            ))}
          </div>
        </div>
      )}
      {Array.isArray(weak_areas) && weak_areas.length > 0 && (
        <div>
          <span className="font-semibold text-amber-800 block mb-1">Areas to Improve:</span>
          <div className="flex flex-wrap gap-1.5">
            {weak_areas.map((w: any, idx: number) => (
              <span key={idx} className="px-2 py-0.5 bg-amber-100 text-amber-800 rounded font-medium">
                {typeof w === 'string' ? w : `${w.topic || w.subtopic || 'Topic'} (${w.accuracy ?? 0}%)`}
              </span>
            ))}
          </div>
        </div>
      )}
      {Array.isArray(next_steps) && next_steps.length > 0 && (
        <div className="mt-2">
          <span className="font-semibold text-purple-900 block mb-1">Recommended Next Steps:</span>
          <ul className="list-disc list-inside space-y-1 text-gray-700">
            {next_steps.map((step: string, idx: number) => (
              <li key={idx}>{step}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

