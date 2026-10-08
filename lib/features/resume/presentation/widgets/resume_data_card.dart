import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/resume_draft.dart';
import 'resume_ui.dart';

/// Compact summary of the resume data the assistant found. Expands to show everything.
class ResumeDataCard extends StatefulWidget {
  final ResumeDraft draft;

  const ResumeDataCard({super.key, required this.draft});

  @override
  State<ResumeDataCard> createState() => _ResumeDataCardState();
}

class _ResumeDataCardState extends State<ResumeDataCard> {
  bool _expanded = false;

  String _range(String a, String b) => [a, b].where((e) => e.isNotEmpty).join(' – ');

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final contact = [d.email, d.phone, d.city].where((e) => e.isNotEmpty).join(' · ');
    final jobs = _expanded ? d.experience : d.experience.take(2).toList();
    final schools = _expanded ? d.education : d.education.take(1).toList();
    final skills = _expanded ? d.skills : d.skills.take(6).toList();
    final hiddenCount = (d.experience.length - jobs.length) +
        (d.education.length - schools.length) +
        (d.skills.length - skills.length) +
        (_expanded ? 0 : d.projects.length + d.certifications.length);

    return Container(
      width: double.infinity,
      decoration: ResumeUi.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(gradient: ResumeUi.heroGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.fullName.isNotEmpty ? d.fullName : 'Your name',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                if (d.headline.isNotEmpty)
                  Text(d.headline, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(contact, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.summary.isNotEmpty)
                  _section(Icons.notes_rounded, 'Summary', [
                    Text(d.summary, maxLines: _expanded ? null : 3, overflow: _expanded ? null : TextOverflow.ellipsis, style: _body),
                  ]),
                if (jobs.isNotEmpty)
                  _section(Icons.work_outline_rounded, 'Experience (${d.experience.length})', [
                    for (final j in jobs) ...[
                      Text('${j.title}${j.company.isNotEmpty ? ' · ${j.company}' : ''}', style: _strong),
                      if (_range(j.start, j.end).isNotEmpty) Text(_range(j.start, j.end), style: _muted),
                      if (_expanded) ...j.bullets.map((b) => Text('• $b', style: _body)),
                      const SizedBox(height: 4),
                    ],
                  ]),
                if (schools.isNotEmpty)
                  _section(Icons.school_outlined, 'Education', [
                    for (final e in schools) ...[
                      Text(e.degree, style: _strong),
                      Text([e.school, _range(e.start, e.end)].where((x) => x.isNotEmpty).join(' · '), style: _muted),
                    ],
                  ]),
                if (skills.isNotEmpty)
                  _section(Icons.lightbulb_outline_rounded, 'Skills', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skills
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: ResumeUi.softBlue, borderRadius: BorderRadius.circular(8)),
                                child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))),
                              ))
                          .toList(),
                    ),
                  ]),
                if (_expanded && d.projects.isNotEmpty)
                  _section(Icons.integration_instructions_outlined, 'Projects',
                      d.projects.map((p) => Text(p.title, style: _strong)).toList()),
                if (_expanded && d.certifications.isNotEmpty)
                  _section(Icons.workspace_premium_outlined, 'Certifications',
                      d.certifications.map((c) => Text(c.title, style: _strong)).toList()),
                if (!d.hasContent)
                  const Text('No resume details yet. We\'ll add them together.', style: _muted),
                if (hiddenCount > 0 || _expanded)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_expanded ? 'Show less' : 'Show all (+$hiddenCount more)',
                          style: const TextStyle(color: ResumeUi.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _body = TextStyle(fontSize: 13, color: AppColors.primaryText, height: 1.35);
  static const _strong = TextStyle(fontSize: 13, color: AppColors.primaryText, fontWeight: FontWeight.w600);
  static const _muted = TextStyle(fontSize: 12, color: AppColors.secondaryText);

  Widget _section(IconData icon, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ResumeUi.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondaryText)),
                const SizedBox(height: 4),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
