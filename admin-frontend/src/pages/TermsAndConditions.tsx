import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeft, FileText, Shield, CheckCircle2, AlertCircle, HelpCircle } from 'lucide-react';

const TermsAndConditions: React.FC = () => {
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
          <Link to="/privacy" className="text-sm font-medium text-primaryBrand hover:underline">
            Privacy Policy →
          </Link>
        </div>
      </header>

      {/* Hero Banner */}
      <div className="bg-gradient-to-b from-primaryBrand/5 to-transparent py-12 border-b border-border/60">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primaryBrand/10 text-primaryBrand text-xs font-semibold mb-4">
            <FileText size={14} /> Official Legal Document
          </div>
          <h1 className="text-3xl sm:text-4xl font-extrabold text-primaryText tracking-tight">Terms & Conditions</h1>
          <p className="text-secondaryText text-sm sm:text-base mt-3 max-w-2xl mx-auto">
            Please read these terms and conditions carefully before using CareerSetu services, portal, or mobile application.
          </p>
          <p className="text-xs text-secondaryText mt-2">Effective Date: October 21, 2026 | Last Updated: October 2026</p>
        </div>
      </div>

      {/* Content Body */}
      <main className="max-w-4xl mx-auto px-6 py-10 space-y-8 text-primaryText leading-relaxed">
        
        {/* Section 1 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <CheckCircle2 size={20} className="text-primaryBrand flex-shrink-0" />
            1. Acceptance of Terms
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            By creating an account, accessing, or using CareerSetu (including website, mobile application, and administrative portals), you agree to be bound by these Terms & Conditions and our Privacy Policy. If you do not agree to all of these terms, do not access or use our services.
          </p>
        </section>

        {/* Section 2 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <CheckCircle2 size={20} className="text-primaryBrand flex-shrink-0" />
            2. User Eligibility & Accounts
          </h2>
          <ul className="text-secondaryText text-sm space-y-2 list-disc list-inside">
            <li>Users must be at least 16 years of age or have parental/guardian consent to use the platform.</li>
            <li>You agree to provide accurate, current, and complete information during registration and keep your profile updated.</li>
            <li>You are solely responsible for maintaining the confidentiality of your login credentials and for all activities under your account.</li>
            <li>CareerSetu reserves the right to suspend or terminate accounts that contain fraudulent, deceptive, or misleading information.</li>
          </ul>
        </section>

        {/* Section 3 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <CheckCircle2 size={20} className="text-primaryBrand flex-shrink-0" />
            3. Educational Assessments & Mock Tests
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            CareerSetu provides skill assessments, practice questions, and mock tests to assist in career readiness. Test results, score percentiles, and completion certifications represent performance indicators on our platform and do not constitute formal academic degree accreditations unless specifically stated by an authorized university partner.
          </p>
        </section>

        {/* Section 4 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <CheckCircle2 size={20} className="text-primaryBrand flex-shrink-0" />
            4. Job Listings & Applications
          </h2>
          <ul className="text-secondaryText text-sm space-y-2 list-disc list-inside">
            <li>CareerSetu acts as a job discovery and routing bridge connecting candidates with verified employers and recruiters.</li>
            <li>We do not guarantee job placement, interview calls, or employment offers from listed companies.</li>
            <li>CareerSetu does not charge candidates any application fees or placement charges. Report any recruiter demanding payment immediately.</li>
          </ul>
        </section>

        {/* Section 5 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <CheckCircle2 size={20} className="text-primaryBrand flex-shrink-0" />
            5. Student Offers, Vouchers & Merchant Perks
          </h2>
          <ul className="text-secondaryText text-sm space-y-2 list-disc list-inside">
            <li>Student merchant perks (gym passes, coaching discounts, book deals, software licenses) are offered in collaboration with verified partners.</li>
            <li>Redemption of discount vouchers, coupon codes, and store passes is subject to partner merchant terms and validity dates.</li>
            <li>Vouchers obtained via unique code pools or in-store passes are non-transferable and may not be sold or traded for cash.</li>
          </ul>
        </section>

        {/* Section 6 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <Shield size={20} className="text-primaryBrand flex-shrink-0" />
            6. Intellectual Property & Code of Conduct
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            All text, graphics, test question banks, user interfaces, trademarks, and logos on CareerSetu are owned, controlled, or licensed by CareerSetu. Users agree not to scrape, extract, redistribute, reverse engineer, or misuse test material, candidate profiles, or platform data.
          </p>
        </section>

        {/* Section 7 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <AlertCircle size={20} className="text-primaryBrand flex-shrink-0" />
            7. Limitation of Liability
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            To the maximum extent permitted by applicable law, CareerSetu and its affiliates shall not be liable for any indirect, incidental, punitive, or consequential damages resulting from platform downtime, merchant service deficiencies, or employer hiring decisions.
          </p>
        </section>

        {/* Section 8 */}
        <section className="bg-white rounded-xl p-6 sm:p-8 border border-border shadow-sm space-y-3">
          <h2 className="text-xl font-bold text-primaryText flex items-center gap-2.5">
            <HelpCircle size={20} className="text-primaryBrand flex-shrink-0" />
            8. Contact & Grievance Redressal
          </h2>
          <p className="text-secondaryText text-sm leading-relaxed">
            For questions, legal notices, or clarifications regarding these Terms & Conditions, please contact:
          </p>
          <div className="text-sm bg-gray-50 p-4 rounded-lg border border-border text-secondaryText">
            <p className="font-semibold text-primaryText">CareerSetu Legal Team</p>
            <p>Email: legal@careersetu.com / support@careersetu.com</p>
            <p>Location: Maharashtra, India</p>
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

export default TermsAndConditions;
