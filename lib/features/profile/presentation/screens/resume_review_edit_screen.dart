import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/resume_analysis.dart';
import '../widgets/chip_manager_bottom_sheet.dart';
import '../widgets/complex_list_manager_bottom_sheet.dart';
import '../widgets/edit_profile_bottom_sheet.dart';
import '../widgets/notice_period_bottom_sheet.dart';
import '../widgets/resume_save_confirm_dialog.dart';
import '../widgets/salary_bottom_sheet.dart';

/// Full profile edit form opened when an uploaded resume doesn't match the profile.
/// Starts from the profile, with values read from the resume filled in where they differ.
/// Nothing is saved until the user confirms. Pops with `true` once something was saved.
class ResumeReviewEditScreen extends ConsumerStatefulWidget {
  final User user;
  final ResumeAnalysis analysis;

  /// `{filename, data}` payload for `resume_data`.
  final Map<String, dynamic> resumeData;

  const ResumeReviewEditScreen({
    super.key,
    required this.user,
    required this.analysis,
    required this.resumeData,
  });

  @override
  ConsumerState<ResumeReviewEditScreen> createState() => _ResumeReviewEditScreenState();
}

class _ResumeReviewEditScreenState extends ConsumerState<ResumeReviewEditScreen> {
  static const _fieldLabels = {
    'full_name': 'Full Name',
    'email': 'Email',
    'whatsapp_number': 'WhatsApp Number',
    'dob': 'Date of Birth',
    'gender': 'Gender',
    'marital_status': 'Marital Status',
    'city': 'City',
    'state': 'State',
    'pincode': 'Pincode',
    'address': 'Address',
    'goal': 'Career Goal',
    'summary': 'Summary',
    'years_of_experience': 'Years of Experience',
    'current_salary': 'Current Salary',
    'expected_salary': 'Expected Salary',
    'notice_period_days': 'Notice Period',
    'linkedin_url': 'LinkedIn',
    'github_url': 'GitHub',
    'portfolio_url': 'Portfolio',
    'skills': 'Skills',
    'languages': 'Languages',
    'work_experience': 'Work Experience',
    'education_history': 'Education',
    'projects': 'Projects',
    'certifications': 'Certifications',
    'achievements': 'Achievements',
    'hobbies': 'Hobbies',
    'acquisition_source': 'Acquisition Source',
  };

  static const _resumeTextFields = [
    'full_name', 'email', 'address', 'summary', 'linkedin_url', 'github_url', 'portfolio_url',
  ];
  static const _stringListFields = ['skills', 'languages', 'hobbies'];
  static const _objectListFields = [
    'work_experience', 'education_history', 'projects', 'certifications', 'achievements',
  ];

  late final Map<String, dynamic> _original;
  late Map<String, dynamic> _draft;
  final Set<String> _fromResume = {};
  bool _isSaving = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _original = _profileValues(widget.user);
    _draft = jsonDecode(jsonEncode(_original)) as Map<String, dynamic>;
    _applyResume(widget.analysis.extracted);
  }

  Map<String, dynamic> _profileValues(User u) => {
        'full_name': u.fullName,
        'email': u.email,
        'whatsapp_number': u.whatsappNumber,
        'dob': u.dob ?? '',
        'gender': u.gender,
        'marital_status': u.maritalStatus,
        'city': u.city,
        'state': u.state,
        'pincode': u.pincode,
        'address': u.address,
        'goal': u.goal,
        'summary': u.summary,
        'years_of_experience': u.yearsOfExperience,
        'current_salary': u.currentSalary,
        'expected_salary': u.expectedSalary,
        'notice_period_days': u.noticePeriodDays,
        'linkedin_url': u.linkedinUrl,
        'github_url': u.githubUrl,
        'portfolio_url': u.portfolioUrl,
        'skills': List<dynamic>.from(u.skills ?? []),
        'languages': List<dynamic>.from(u.languages ?? []),
        'work_experience': List<dynamic>.from(u.workExperience ?? []),
        'education_history': List<dynamic>.from(u.educationHistory ?? []),
        'projects': List<dynamic>.from(u.projects ?? []),
        'certifications': List<dynamic>.from(u.certifications ?? []),
        'achievements': List<dynamic>.from(u.achievements ?? []),
        'hobbies': List<dynamic>.from(u.hobbies ?? []),
        'acquisition_source': u.acquisitionSource,
      };

  String _str(dynamic v) => (v ?? '').toString().trim();

  void _setFromResume(String key, dynamic value) {
    _draft[key] = value;
    _fromResume.add(key);
  }

  /// Fills in resume values wherever they differ from the profile.
  void _applyResume(Map<String, dynamic> r) {
    for (final key in _resumeTextFields) {
      final value = _str(r[key]);
      if (value.isNotEmpty && value.toLowerCase() != _str(_draft[key]).toLowerCase()) {
        _setFromResume(key, value);
      }
    }

    final whatsapp = _str(r['whatsapp_number']).replaceAll(RegExp(r'\D'), '');
    if (whatsapp.length >= 10) {
      final last10 = whatsapp.substring(whatsapp.length - 10);
      if (last10 != _draft['whatsapp_number']) _setFromResume('whatsapp_number', last10);
    }

    final dob = DateTime.tryParse(_str(r['dob']));
    if (dob != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(dob);
      if (formatted != _draft['dob']) _setFromResume('dob', formatted);
    }

    final gender = _str(r['gender']);
    if (['Male', 'Female', 'Other'].contains(gender) && gender != _draft['gender']) {
      _setFromResume('gender', gender);
    }

    final years = r['years_of_experience'];
    if (years is num && years > 0 && years.toDouble() != _draft['years_of_experience']) {
      _setFromResume('years_of_experience', years.toDouble());
    }

    final city = _str(r['city']);
    if (city.isNotEmpty && !_str(_draft['city']).toLowerCase().contains(city.toLowerCase())) {
      _setFromResume('city', city);
      final state = _str(r['state']);
      final pincode = _str(r['pincode']).replaceAll(RegExp(r'\D'), '');
      if (state.isNotEmpty) _setFromResume('state', state);
      if (pincode.length == 6) _setFromResume('pincode', pincode);
    }

    for (final key in _stringListFields) {
      final existing = List<dynamic>.from(_draft[key]);
      final seen = existing.map((e) => e.toString().toLowerCase()).toSet();
      final added = (r[key] as List? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty && seen.add(e.toLowerCase()))
          .toList();
      if (added.isNotEmpty) _setFromResume(key, [...existing, ...added]);
    }

    for (final key in _objectListFields) {
      final existing = List<dynamic>.from(_draft[key]);
      final seen = existing.map(_itemKey).toSet();
      final added = (r[key] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e).map((k, v) => MapEntry(k, _str(v))))
          .where((e) => e.values.first.isNotEmpty && seen.add(_itemKey(e)))
          .toList();
      if (added.isNotEmpty) _setFromResume(key, [...existing, ...added]);
    }
  }

  /// Identifies a list item by its first two fields, e.g. title + company.
  String _itemKey(dynamic item) {
    if (item is! Map) return item.toString().toLowerCase();
    return item.values.take(2).map((v) => _str(v).toLowerCase()).join('|');
  }

  Map<String, dynamic> get _changedFields => Map.fromEntries(
        _draft.entries.where((e) => jsonEncode(e.value) != jsonEncode(_original[e.key])),
      );

  Future<bool> _updateDraft(Map<String, dynamic> data) async {
    setState(() {
      _draft.addAll(data);
      _fromResume.removeAll(data.keys);
    });
    return true;
  }

  Future<void> _continue() async {
    if (_str(_draft['full_name']).isEmpty) {
      CustomToast.showError(context, 'Name cannot be empty');
      return;
    }

    final changed = _changedFields;
    final choice = await ResumeSaveConfirmDialog.show(
      context,
      resumeFilename: widget.resumeData['filename'] ?? 'Resume.pdf',
      changedFields: changed.keys.map((k) => _fieldLabels[k] ?? k).toList(),
      resumeMismatched: true,
    );
    if (choice == null || !mounted) return;

    final payload = <String, dynamic>{
      if (choice != ResumeSaveChoice.resumeOnly) ...changed,
      if (choice != ResumeSaveChoice.infoOnly) 'resume_data': widget.resumeData,
    };
    // Location is saved as a set, as the profile screen does.
    if (payload.containsKey('city') || payload.containsKey('state') || payload.containsKey('pincode')) {
      payload['city'] = _draft['city'];
      payload['state'] = _draft['state'];
      payload['pincode'] = _draft['pincode'];
    }

    setState(() {
      _isSaving = true;
      _progress = 0;
    });
    final success = await ref.read(authProvider.notifier).updateProfileDetails(
      payload,
      onSendProgress: (count, total) {
        if (total > 0 && mounted) setState(() => _progress = count / total);
      },
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      CustomToast.showSuccess(context, switch (choice) {
        ResumeSaveChoice.resumeAndInfo => 'Resume and profile updated',
        ResumeSaveChoice.infoOnly => 'Profile updated',
        ResumeSaveChoice.resumeOnly => 'Resume uploaded successfully',
      });
      Navigator.pop(context, true);
    } else {
      CustomToast.showError(context, 'Failed to save. Please try again.');
    }
  }

  // ---- Sheets ----

  void _openSheet(Widget sheet, {bool rootNavigator = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: rootNavigator,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  void _editField(String key, String title) {
    _openSheet(
      EditProfileBottomSheet(
        title: title,
        fieldKey: key,
        currentValue: key == 'years_of_experience' ? _draft[key].toString() : _str(_draft[key]),
        initialLocation: key == 'city'
            ? {'city': _str(_draft['city']), 'state': _str(_draft['state']), 'pincode': _str(_draft['pincode'])}
            : null,
        onSave: _updateDraft,
      ),
      rootNavigator: true,
    );
  }

  void _editChips(String key, String title) {
    _openSheet(ChipManagerBottomSheet(
      title: title,
      fieldKey: key,
      currentList: _draft[key],
      onSave: (f, v) => _updateDraft({f: v}),
    ));
  }

  void _editList(String key, String title) {
    _openSheet(ComplexListManagerBottomSheet(
      title: title,
      fieldKey: key,
      currentList: _draft[key],
      onSave: (f, v) => _updateDraft({f: v}),
    ));
  }

  void _editSalary(String key, String title) {
    _openSheet(SalaryBottomSheet(
      field: key,
      title: title,
      initialValue: _draft[key],
      onSave: (f, v) async => _updateDraft({f: v}),
    ));
  }

  void _editNoticePeriod() {
    _openSheet(NoticePeriodBottomSheet(
      field: 'notice_period_days',
      title: 'Notice Period',
      initialValue: _draft['notice_period_days'],
      onSave: (f, v) async => _updateDraft({f: v}),
    ));
  }

  // ---- Display helpers ----

  String _orAdd(String key, String placeholder) {
    final v = _str(_draft[key]);
    return v.isNotEmpty ? v : placeholder;
  }

  String _formatDob(String dob) {
    final parsed = DateTime.tryParse(dob);
    return parsed != null ? DateFormat('dd MMMM yyyy').format(parsed) : dob;
  }

  String _salary(int? value, String placeholder) =>
      value != null ? '₹ ${NumberFormat('#,##,###').format(value)} / year' : placeholder;

  String _listSummary(String key, String unit, String placeholder) {
    final list = _draft[key] as List;
    if (list.isEmpty) return placeholder;
    final preview = list.take(3).map((e) => e is Map ? _str(e.values.first) : e.toString()).join(', ');
    return '${list.length} $unit · $preview${list.length > 3 ? '…' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final notice = _draft['notice_period_days'] as int?;
    final location = [_draft['city'], _draft['state'], _draft['pincode']].map(_str).where((e) => e.isNotEmpty).join(', ');

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F7FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          title: const Text('Review your info'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildInfoBanner(),
            _buildSectionHeader('BASIC & PERSONAL INFO'),
            _buildTile('full_name', 'Full Name', _orAdd('full_name', 'Add Name'), Icons.badge_outlined, () => _editField('full_name', 'Full Name')),
            _buildTile('mobile_number', 'Mobile Number', widget.user.mobileNumber.isNotEmpty ? widget.user.mobileNumber : '-', Icons.phone, null,
                hint: 'Change from Profile → Mobile Number (OTP required)'),
            _buildTile('whatsapp_number', 'WhatsApp Number', _orAdd('whatsapp_number', 'Add WhatsApp'), Icons.chat, () => _editField('whatsapp_number', 'WhatsApp Number')),
            _buildTile('email', 'Email', _orAdd('email', 'Add Email'), Icons.email, () => _editField('email', 'Email')),
            _buildTile('dob', 'Date of Birth', _str(_draft['dob']).isNotEmpty ? _formatDob(_draft['dob']) : 'Add Date of Birth', Icons.cake, () => _editField('dob', 'Date of Birth')),
            _buildTile('gender', 'Gender', _orAdd('gender', 'Add Gender'), Icons.person, () => _editField('gender', 'Gender')),
            _buildTile('marital_status', 'Marital Status', _orAdd('marital_status', 'Add Marital Status'), Icons.family_restroom, () => _editField('marital_status', 'Marital Status')),
            _buildTile('city', 'Location (City, State, Pincode)', location.isNotEmpty ? location : 'Add Location', Icons.location_city, () => _editField('city', 'Location')),
            _buildTile('address', 'Full Address', _orAdd('address', 'Add Full Address'), Icons.home, () => _editField('address', 'Address')),

            _buildSectionHeader('PROFESSIONAL OVERVIEW'),
            _buildTile('goal', 'Career Goal', _str(_draft['goal']).isNotEmpty ? _str(_draft['goal']).toUpperCase() : 'Add Goal', Icons.flag, () => _editField('goal', 'Career Goal')),
            _buildTile('summary', 'Professional Summary', _orAdd('summary', 'Add Summary'), Icons.text_snippet, () => _editField('summary', 'Professional Summary')),
            _buildTile('years_of_experience', 'Years of Experience', '${_draft['years_of_experience']} Years', Icons.work, () => _editField('years_of_experience', 'Years of Experience')),
            _buildTile('current_salary', 'Current Salary', _salary(_draft['current_salary'], 'Add Current Salary'), Icons.payments_outlined, () => _editSalary('current_salary', 'Current Salary')),
            _buildTile('expected_salary', 'Expected Salary', _salary(_draft['expected_salary'], 'Add Expected Salary'), Icons.account_balance_wallet_outlined, () => _editSalary('expected_salary', 'Expected Salary')),
            _buildTile('notice_period_days', 'Notice Period',
                notice != null ? (notice % 30 == 0 && notice >= 30 ? '${notice ~/ 30} Months' : '$notice Days') : 'Add Notice Period',
                Icons.event_available_outlined, _editNoticePeriod),

            _buildSectionHeader('DIGITAL PRESENCE'),
            _buildTile('linkedin_url', 'LinkedIn Profile', _orAdd('linkedin_url', 'Add LinkedIn'), Icons.link, () => _editField('linkedin_url', 'LinkedIn URL')),
            _buildTile('github_url', 'GitHub Profile', _orAdd('github_url', 'Add GitHub'), Icons.code, () => _editField('github_url', 'GitHub URL')),
            _buildTile('portfolio_url', 'Portfolio URL', _orAdd('portfolio_url', 'Add Portfolio'), Icons.web, () => _editField('portfolio_url', 'Portfolio URL')),

            _buildSectionHeader('SKILLS & LANGUAGES'),
            _buildTile('skills', 'Skills', _listSummary('skills', 'Skills', 'Add Skills'), Icons.lightbulb, () => _editChips('skills', 'Skills')),
            _buildTile('languages', 'Languages', _listSummary('languages', 'Languages', 'Add Languages'), Icons.language, () => _editChips('languages', 'Languages')),

            _buildSectionHeader('EXPERIENCE & EDUCATION'),
            _buildTile('work_experience', 'Work Experience', _listSummary('work_experience', 'Roles', 'Add Work Experience'), Icons.business, () => _editList('work_experience', 'Work Experience')),
            _buildTile('education_history', 'Education History', _listSummary('education_history', 'Degrees', 'Add Education'), Icons.school, () => _editList('education_history', 'Education')),
            _buildTile('projects', 'Projects', _listSummary('projects', 'Projects', 'Add Projects'), Icons.integration_instructions, () => _editList('projects', 'Projects')),
            _buildTile('certifications', 'Certifications', _listSummary('certifications', 'Certifications', 'Add Certifications'), Icons.workspace_premium, () => _editList('certifications', 'Certifications')),
            _buildTile('achievements', 'Achievements', _listSummary('achievements', 'Achievements', 'Add Achievements'), Icons.emoji_events, () => _editList('achievements', 'Achievements')),

            _buildSectionHeader('OTHER DETAILS'),
            _buildTile('hobbies', 'Hobbies', _listSummary('hobbies', 'Hobbies', 'Add Hobbies'), Icons.sports_esports, () => _editChips('hobbies', 'Hobbies')),
            _buildTile('acquisition_source', 'How did you hear about us?', _orAdd('acquisition_source', 'Select Source'), Icons.campaign, () => _editField('acquisition_source', 'Acquisition Source')),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving) ...[
                  LinearProgressIndicator(
                    value: _progress > 0 && _progress < 1 ? _progress : null,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBrand),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Continue',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFFD97706)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'We filled in details from your resume where they differ from your profile (marked "From resume"). Review and edit anything, then tap Continue.',
              style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTile(String key, String title, String subtitle, IconData icon, VoidCallback? onTap, {String? hint}) {
    final fromResume = _fromResume.contains(key) || (key == 'city' && _fromResume.any((k) => ['state', 'pincode'].contains(k)));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: fromResume ? Border.all(color: const Color(0xFFF59E0B)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSaving ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFE3F1FF), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: const Color(0xFF0ea5e9), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText))),
                          if (fromResume) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                              child: const Text('From resume', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                      if (hint != null) ...[
                        const SizedBox(height: 4),
                        Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right, color: AppColors.secondaryText, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
