import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeft, Shield, Lock, Eye, Server, RefreshCw, Mail } from 'lucide-react';

const PrivacyPolicy: React.FC = () => {
  return (
    <div className="min-h-screen bg-background">
      {/* Navigation Header */}
      <header className="sticky top-0 z-30 bg-white/90 backdrop-blur border-b border-border">
        <div className="max-w-4xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link to="/login" className="flex items-center gap-2 text-sm font-semibold text-secondaryText hover:text-primaryText transition-colors">
            <ArrowLeft size={16} /> Back to Login
          </Link>
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primaryBrand rounded-lg flex items-center justify-center text-white font-bold text-sm shadow-sm shadow-primaryBrand/30">C</div>
            <span className="font-bold text-primaryText">CareerSetu</span>
          </div>
          <Link to="/terms" className="text-sm font-medium text-primaryBrand hover:underline">
            Terms & Conditions →
          </Link>
        </div>
      </header>

      {/* Hero Banner */}
      <div className="bg-gradient-to-b from-primaryBrand/5 to-transparent py-12 border-b border-border/60">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-semibold mb-4">
            <Shield size={14} /> Data Protection & Privacy Commitment
          </div>
          <h1 className="text-3xl sm:text-4xl font-extrabold text-primaryText tracking-tight">Privacy Policy</h1>
          <p className="text-secondaryText text-sm sm:text-base mt-3 max-w-2xl mx-auto">
            Learn how CareerSetu collects, protects, uses, and respects your personal and professional data.
          </p>
          <p className="text-xs text-secondaryText mt-2">Effective Date: October 21, 2026 | Compliant with DPDP Act, India</p>
        </div>
      </div>

      {/* Content Body */}
      <main className="max-w-4xl mx-auto px-6 py-10 space-y-8 text-primaryText leading-relaxed">
        
        {/* Section 1 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <Eye size={20} className="text-primaryBrand flex-shrink-0" />
            1. Information We Collect
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            We collect information you provide directly to us when registering an account, completing your student profile, applying for jobs, attempting mock tests, or claiming merchant offers:
          </p>
          <ul className="text-secondaryText text-sm space-y-2 list-disc list-inside">
            <li><strong>Personal Contact Data:</strong> Full Name, Email Address, Mobile Number, WhatsApp Number, Date of Birth, Gender, City, State, Pincode.</li>
            <li><strong>Professional & Academic Data:</strong> Resume/CV, Education History, Degrees, Work Experience, Career Goals, Skills, Portfolio & GitHub/LinkedIn URLs.</li>
            <li><strong>Assessment Activity:</strong> Test attempts, question responses, scores, percentile rankings, and performance metrics.</li>
            <li><strong>Offer Redemptions:</strong> Claimed discounts, merchant vouchers, in-store pass generation records.</li>
          </ul>
        </section>

        {/* Section 2 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <Server size={20} className="text-primaryBrand flex-shrink-0" />
            2. How We Use Your Information
          </h2>
          <ul className="text-secondaryText text-sm space-y-2 list-disc list-inside">
            <li>To match candidate profiles with relevant job openings, internships, and recruiter postings.</li>
            <li>To compute objective profile completion scores, resume feedback, and assessment results.</li>
            <li>To issue exclusive merchant discount vouchers and authenticate in-store passes.</li>
            <li>To communicate transactional updates, OTP logins, interview invitations, and critical notifications.</li>
            <li>To improve platform performance, audit security, and prevent fraudulent abuse.</li>
          </ul>
        </section>

        {/* Section 3 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <Lock size={20} className="text-primaryBrand flex-shrink-0" />
            3. Information Sharing & Third Parties
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            CareerSetu does <strong>not</strong> sell your personal information to third-party data brokers. We share data solely under strict necessity:
          </p>
          <ul className="text-secondaryText text-sm space-y-2 list-disc list-inside">
            <li><strong>Prospective Employers:</strong> When you apply for a job, your resume, contact details, and relevant qualifications are forwarded to the employer.</li>
            <li><strong>Partner Merchants:</strong> For unique code voucher redemption or in-store pass verification (e.g. gym, coaching, or bookstore partner).</li>
            <li><strong>Service Providers:</strong> Cloud hosting, secure SMS OTP gateways, and Firebase authentication infrastructure.</li>
            <li><strong>Legal Compliance:</strong> When required by lawful government or regulatory summons under Indian cyber law.</li>
          </ul>
        </section>

        {/* Section 4 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <Shield size={20} className="text-primaryBrand flex-shrink-0" />
            4. Data Security & Storage
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            We employ modern security standards including 256-bit SSL/TLS encryption for all data in transit, salted password hashing, JWT-based bearer authentication, and role-based administrative access controls. All databases are hosted within secure, audited data centers.
          </p>
        </section>

        {/* Section 5 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <RefreshCw size={20} className="text-primaryBrand flex-shrink-0" />
            5. Your Rights & Data Retention
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            You maintain full ownership of your data. You may review, edit, or update your profile information at any time directly through the CareerSetu mobile app or portal. You also have the right to request deletion of your account and personal records by contacting our support team.
          </p>
        </section>

        {/* Section 6 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <Mail size={20} className="text-primaryBrand flex-shrink-0" />
            6. Grievance Officer & Inquiries
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            In accordance with the Information Technology Act and the Digital Personal Data Protection (DPDP) Act, 2023, the details of our Grievance Officer are provided below:
          </p>
          <div className="text-sm bg-gray-50 p-4 rounded-lg border border-border text-secondaryText">
            <p className="font-semibold text-primaryText">Data Protection & Grievance Officer</p>
            <p>Email: privacy@careersetu.com</p>
            <p>Address: CareerSetu Technologies, Maharashtra, India</p>
          </div>
        </section>

      </main>

      {/* Footer */}
      <footer className="border-t border-border bg-white py-8">
        <div className="max-w-4xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-secondaryText">
          <p>© {new Date().getFullYear()} CareerSetu. All rights reserved.</p>
          <div className="flex gap-6">
            <Link to="/terms" className="hover:text-primaryText font-medium">Terms & Conditions</Link>
            <Link to="/privacy" className="hover:text-primaryText font-medium">Privacy Policy</Link>
            <Link to="/login" className="hover:text-primaryText font-medium">Admin Portal</Link>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default PrivacyPolicy;
