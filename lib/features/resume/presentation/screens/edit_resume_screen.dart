import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../jobs/data/jobs_repository.dart';
import '../../data/ai_service.dart';
import '../../domain/resume_draft.dart';
import '../providers/resume_provider.dart';
import '../widgets/resume_ui.dart';

/// Edits the whole resume on one page, laid out like the document itself.
/// Works on a copy of the draft; nothing is saved until the user taps Save.
class EditResumeScreen extends ConsumerStatefulWidget {
  const EditResumeScreen({super.key});

  @override
  ConsumerState<EditResumeScreen> createState() => _EditResumeScreenState();
}

class _EditResumeScreenState extends ConsumerState<EditResumeScreen> {
  late ResumeDraft _draft;
  bool _dirty = false;
  bool _saving = false;

  /// Bumped after structural changes (add, remove, reorder, AI rewrite) so fields rebuild from the model.
  int _rev = 0;

  /// Keys of sections currently being improved by AI.
  final Set<String> _improving = {};

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _draft = ref.read(chatResumeProvider).draft.copy();
  }

  void _changed() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _restructure(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
      _rev++;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    _cleanUp();
    setState(() => _saving = true);
    try {
      await ref.read(chatResumeProvider.notifier).saveDraft(_draft);
      if (!mounted) return;
      _dirty = false;
      CustomToast.showSuccess(context, 'Resume saved');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) CustomToast.showError(context, e is ApiException ? e.message : 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Drops empty bullets and empty entries before saving.
  void _cleanUp() {
    for (final e in _draft.experience) {
      e.bullets.removeWhere((b) => b.trim().isEmpty);
    }
    for (final p in _draft.projects) {
      p.bullets.removeWhere((b) => b.trim().isEmpty);
    }
    _draft.experience.removeWhere((e) => e.title.trim().isEmpty && e.company.trim().isEmpty && e.bullets.isEmpty);
    _draft.education.removeWhere((e) => e.degree.trim().isEmpty && e.school.trim().isEmpty);
    _draft.projects.removeWhere((p) => p.title.trim().isEmpty && p.description.trim().isEmpty && p.bullets.isEmpty);
    _draft.certifications.removeWhere((c) => c.title.trim().isEmpty);
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes to your resume.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return discard == true;
  }

  // ---- AI ----

  Future<void> _improve(String key, String kind, String text, String context, void Function(List<String>) apply) async {
    if (text.trim().isEmpty) {
      CustomToast.showError(this.context, 'Write something first, then I can improve it.');
      return;
    }
    setState(() => _improving.add(key));
    try {
      final result = await ref.read(aiServiceProvider).improve(kind, text, context: context);
      if (!mounted || result.every((r) => r.trim().isEmpty)) return;
      final accepted = await _showSuggestion(kind == 'bullets' ? result.map((b) => '• $b').join('\n') : result.first);
      if (accepted == true) _restructure(() => apply(result));
    } catch (e) {
      if (mounted) CustomToast.showError(this.context, e is ApiException ? e.message : 'AI is unavailable right now.');
    } finally {
      if (mounted) setState(() => _improving.remove(key));
    }
  }

  Future<bool?> _showSuggestion(String suggestion) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: ResumeUi.accent),
                  SizedBox(width: 8),
                  Text('AI suggestion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: ResumeUi.softBlue, borderRadius: BorderRadius.circular(12)),
                    child: Text(suggestion, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.primaryText)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Use this', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Month picker ----

  Future<String?> _pickMonth(String current, {bool allowPresent = false}) {
    int year = DateTime.now().year;
    final match = RegExp(r'(\d{4})').firstMatch(current);
    if (match != null) year = int.parse(match.group(1)!);

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setDialogState(() => year--)),
                    Text('$year', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: year < DateTime.now().year + 6 ? () => setDialogState(() => year++) : null,
                    ),
                  ],
                ),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  childAspectRatio: 1.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _months
                      .map((m) => TextButton(
                            onPressed: () => Navigator.pop(context, '$m $year'),
                            child: Text(m, style: const TextStyle(color: AppColors.primaryText)),
                          ))
                      .toList(),
                ),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context, '$year'), child: const Text('Year only')),
                    const Spacer(),
                    if (allowPresent)
                      TextButton(onPressed: () => Navigator.pop(context, 'Present'), child: const Text('Present')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          setState(() => _dirty = false);
          Navigator.pop(this.context);
        }
      },
      child: Container(
        decoration: const BoxDecoration(gradient: ResumeUi.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.primaryText,
            title: const Text('Edit Resume', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ResumeUi.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      _buildSummary(),
                      _buildExperience(),
                      _buildEducation(),
                      _buildProjects(),
                      _buildCertifications(),
                      _buildChipSection('skills', 'Skills', _draft.skills, 'Add a skill', withSuggestions: true),
                      _buildChipSection('languages', 'Languages', _draft.languages, 'Add a language'),
                      _buildLinks(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: ResumeUi.heroGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_dirty ? 'Save changes' : 'Saved',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _draft.fullName.isNotEmpty ? _draft.fullName.toUpperCase() : 'YOUR NAME',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A), letterSpacing: 0.5),
              ),
            ),
            _tag('From profile', Icons.lock_outline),
          ],
        ),
        const SizedBox(height: 4),
        Text([_draft.email, _draft.phone].where((e) => e.isNotEmpty).join('  ·  '),
            style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
        const SizedBox(height: 10),
        _field(_draft.headline, (v) => _draft.headline = v, hint: 'Headline, e.g. Flutter Developer',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText), key: 'headline'),
        const SizedBox(height: 6),
        _field(_draft.city, (v) => _draft.city = v, hint: 'City', icon: Icons.location_on_outlined, key: 'city'),
        const SizedBox(height: 4),
        const Text('Name, email and phone come from your profile. Change them in Profile.',
            style: TextStyle(fontSize: 11, color: AppColors.borderDark)),
      ],
    );
  }

  Widget _buildSummary() {
    return _section(
      'Professional Summary',
      trailing: _improveButton('summary', () => _improve('summary', 'summary', _draft.summary, _draft.headline, (r) => _draft.summary = r.first)),
      child: _field(_draft.summary, (v) => _draft.summary = v,
          hint: '2–3 lines about who you are and what you\'re great at', maxLines: null, key: 'summary'),
    );
  }

  Widget _buildExperience() {
    return _section(
      'Experience',
      trailing: _addButton(() => _restructure(() => _draft.experience.add(ExperienceEntry()))),
      child: _reorderable(
        _draft.experience,
        (i) {
          final e = _draft.experience[i];
          return _entryCard(
            index: i,
            onDelete: () => _restructure(() => _draft.experience.removeAt(i)),
            children: [
              _field(e.title, (v) => e.title = v, hint: 'Job title', bold: true, key: 'exp$i-title'),
              Row(
                children: [
                  Expanded(child: _field(e.company, (v) => e.company = v, hint: 'Company', key: 'exp$i-company')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(e.location, (v) => e.location = v, hint: 'Location', key: 'exp$i-location')),
                ],
              ),
              _dateRow(e.start, e.end, (v) => e.start = v, (v) => e.end = v),
              _bullets(
                'exp$i',
                e.bullets,
                improveContext: '${e.title} at ${e.company}',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEducation() {
    return _section(
      'Education',
      trailing: _addButton(() => _restructure(() => _draft.education.add(EducationEntry()))),
      child: _reorderable(
        _draft.education,
        (i) {
          final e = _draft.education[i];
          return _entryCard(
            index: i,
            onDelete: () => _restructure(() => _draft.education.removeAt(i)),
            children: [
              _field(e.degree, (v) => e.degree = v, hint: 'Degree, e.g. B.E. Computer Engineering', bold: true, key: 'edu$i-degree'),
              _field(e.school, (v) => e.school = v, hint: 'College / University', key: 'edu$i-school'),
              _dateRow(e.start, e.end, (v) => e.start = v, (v) => e.end = v),
              _field(e.score, (v) => e.score = v, hint: 'Score (optional), e.g. 8.2 CGPA', key: 'edu$i-score'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProjects() {
    return _section(
      'Projects',
      trailing: _addButton(() => _restructure(() => _draft.projects.add(ProjectEntry()))),
      child: _reorderable(
        _draft.projects,
        (i) {
          final p = _draft.projects[i];
          return _entryCard(
            index: i,
            onDelete: () => _restructure(() => _draft.projects.removeAt(i)),
            children: [
              _field(p.title, (v) => p.title = v, hint: 'Project title', bold: true, key: 'proj$i-title'),
              _field(p.description, (v) => p.description = v, hint: 'One line on what you built', maxLines: null, key: 'proj$i-desc'),
              _bullets('proj$i', p.bullets, improveContext: 'Project: ${p.title}. ${p.description}'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCertifications() {
    return _section(
      'Certifications',
      trailing: _addButton(() => _restructure(() => _draft.certifications.add(CertificationEntry()))),
      child: _reorderable(
        _draft.certifications,
        (i) {
          final c = _draft.certifications[i];
          return _entryCard(
            index: i,
            onDelete: () => _restructure(() => _draft.certifications.removeAt(i)),
            children: [
              _field(c.title, (v) => c.title = v, hint: 'Certification', bold: true, key: 'cert$i-title'),
              Row(
                children: [
                  Expanded(flex: 3, child: _field(c.organization, (v) => c.organization = v, hint: 'Issued by', key: 'cert$i-org')),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _field(c.year, (v) => c.year = v, hint: 'Year', key: 'cert$i-year')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChipSection(String key, String title, List<String> items, String hint, {bool withSuggestions = false}) {
    return _section(
      title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < items.length; i++)
                  Chip(
                    label: Text(items[i], style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A8A))),
                    backgroundColor: ResumeUi.softBlue,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    deleteIconColor: AppColors.secondaryText,
                    onDeleted: () => _restructure(() => items.removeAt(i)),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          _ChipAdder(
            key: ValueKey('$key-adder-$_rev'),
            hint: hint,
            suggestions: withSuggestions ? _skillSuggestions : null,
            onAdd: (value) {
              if (items.any((s) => s.toLowerCase() == value.toLowerCase())) return;
              _restructure(() => items.add(value));
            },
          ),
        ],
      ),
    );
  }

  Future<List<String>> _skillSuggestions(String query) async {
    try {
      final response = await ref.read(apiClientProvider).get('/skills', queryParameters: {'q': query});
      return (response.data as List).map((s) => s['name'].toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Widget _buildLinks() {
    final l = _draft.links;
    return _section(
      'Links',
      child: Column(
        children: [
          _field(l.linkedin, (v) => l.linkedin = v, hint: 'LinkedIn URL', icon: Icons.link, key: 'linkedin'),
          _field(l.github, (v) => l.github = v, hint: 'GitHub URL', icon: Icons.code, key: 'github'),
          _field(l.portfolio, (v) => l.portfolio = v, hint: 'Portfolio URL', icon: Icons.language, key: 'portfolio'),
        ],
      ),
    );
  }

  // ---- Building blocks ----

  Widget _section(String title, {Widget? trailing, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E3A8A), width: 1.5))),
            child: Row(
              children: [
                Expanded(
                  child: Text(title.toUpperCase(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF1E3A8A))),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _reorderable(List<dynamic> list, Widget Function(int) itemBuilder) {
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text('Nothing added yet. Tap + Add.', style: TextStyle(fontSize: 13, color: AppColors.borderDark)),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: list.length,
      onReorder: (oldIndex, newIndex) => _restructure(() {
        if (newIndex > oldIndex) newIndex--;
        list.insert(newIndex, list.removeAt(oldIndex));
      }),
      itemBuilder: (context, i) => KeyedSubtree(key: ValueKey('${identityHashCode(list[i])}-$_rev'), child: itemBuilder(i)),
    );
  }

  Widget _entryCard({required int index, required VoidCallback onDelete, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3F1FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(top: 10, right: 2),
              child: Icon(Icons.drag_indicator, color: AppColors.borderDark, size: 20),
            ),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _dateRow(String start, String end, ValueChanged<String> setStart, ValueChanged<String> setEnd) {
    Widget box(String value, String hint, ValueChanged<String> set, {bool allowPresent = false}) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final picked = await _pickMonth(value, allowPresent: allowPresent);
            if (picked != null) _restructure(() => set(picked));
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.secondaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(value.isNotEmpty ? value : hint,
                      style: TextStyle(fontSize: 13, color: value.isNotEmpty ? AppColors.primaryText : AppColors.borderDark)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        box(start, 'Start', setStart),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('–')),
        box(end, 'End', setEnd, allowPresent: true),
      ],
    );
  }

  Widget _bullets(String key, List<String> bullets, {required String improveContext}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bullets.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, left: 4, right: 6), child: Text('•', style: TextStyle(fontSize: 16))),
              Expanded(
                child: _field(bullets[i], (v) => bullets[i] = v, hint: 'Achievement or responsibility', maxLines: null, key: '$key-b$i'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 16, color: AppColors.borderDark),
                onPressed: () => _restructure(() => bullets.removeAt(i)),
              ),
            ],
          ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _restructure(() => bullets.add('')),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Bullet'),
              style: TextButton.styleFrom(foregroundColor: ResumeUi.accent, visualDensity: VisualDensity.compact),
            ),
            const Spacer(),
            _improveButton(
              '$key-bullets',
              () => _improve('$key-bullets', 'bullets', bullets.where((b) => b.trim().isNotEmpty).join('\n'), improveContext, (r) {
                bullets
                  ..clear()
                  ..addAll(r);
              }),
              label: 'Improve bullets',
            ),
          ],
        ),
      ],
    );
  }

  Widget _improveButton(String key, VoidCallback onTap, {String label = 'Improve'}) {
    final busy = _improving.contains(key);
    return TextButton.icon(
      onPressed: busy ? null : onTap,
      icon: busy
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: ResumeUi.accent))
          : const Icon(Icons.auto_awesome, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(foregroundColor: ResumeUi.accent, visualDensity: VisualDensity.compact),
    );
  }

  Widget _addButton(VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Add'),
      style: TextButton.styleFrom(foregroundColor: ResumeUi.accent, visualDensity: VisualDensity.compact),
    );
  }

  Widget _tag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondaryText),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// An inline, document-style text field bound directly to the draft.
  Widget _field(
    String initial,
    ValueChanged<String> onChanged, {
    required String key,
    String? hint,
    TextStyle? style,
    bool bold = false,
    int? maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: TextFormField(
        key: ValueKey('$key-$_rev'),
        initialValue: initial,
        maxLines: maxLines,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (v) {
          onChanged(v);
          _changed();
        },
        style: style ??
            TextStyle(fontSize: 14, height: 1.4, color: AppColors.primaryText, fontWeight: bold ? FontWeight.w700 : FontWeight.normal),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.borderDark, fontWeight: FontWeight.normal, fontSize: 14),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.secondaryText) : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: ResumeUi.accent),
          ),
        ),
      ),
    );
  }
}

/// Inline "add a chip" field with optional autocomplete suggestions.
class _ChipAdder extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onAdd;
  final Future<List<String>> Function(String query)? suggestions;

  const _ChipAdder({super.key, required this.hint, required this.onAdd, this.suggestions});

  @override
  State<_ChipAdder> createState() => _ChipAdderState();
}

class _ChipAdderState extends State<_ChipAdder> {
  TextEditingController? _controller;

  void _submit() {
    final value = _controller?.text.trim() ?? '';
    if (value.isEmpty) return;
    widget.onAdd(value);
    _controller?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (value) async {
        if (widget.suggestions == null || value.text.trim().length < 2) return const [];
        return widget.suggestions!(value.text.trim());
      },
      onSelected: (value) {
        widget.onAdd(value);
        _controller?.clear();
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        _controller = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => _submit(),
          style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.borderDark, fontSize: 14),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: ResumeUi.accent),
            ),
            suffixIcon: IconButton(icon: const Icon(Icons.add_circle, color: ResumeUi.accent), onPressed: _submit),
          ),
        );
      },
    );
  }
}
