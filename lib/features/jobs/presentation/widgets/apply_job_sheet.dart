import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/job_model.dart';
import '../providers/jobs_provider.dart';
import 'job_card.dart';

/// In-app application form: resume in use, cover letter and screening questions.
/// Pops with `true` once the application is submitted.
class ApplyJobSheet extends ConsumerStatefulWidget {
  final JobModel job;

  const ApplyJobSheet({super.key, required this.job});

  @override
  ConsumerState<ApplyJobSheet> createState() => _ApplyJobSheetState();
}

class _ApplyJobSheetState extends ConsumerState<ApplyJobSheet> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetter = TextEditingController();
  late final List<TextEditingController> _answers =
      widget.job.screeningQuestions.map((_) => TextEditingController()).toList();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _coverLetter.dispose();
    for (final c in _answers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(appliedJobsProvider.notifier).apply(
            widget.job,
            coverLetter: _coverLetter.text,
            screeningResponses: {
              for (var i = 0; i < widget.job.screeningQuestions.length; i++)
                widget.job.screeningQuestions[i]: _answers[i].text.trim(),
            },
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      if (e.statusCode == 409 && mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final resume = ref.watch(authProvider).currentUser?.resumeData;
    final resumeName = resume?['filename']?.toString();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CompanyAvatar(job: job, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Apply for', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                Text(job.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.cardTitle.copyWith(fontSize: 16)),
                                Text(job.companyName, style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _label('Resume'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: resumeName != null ? AppUi.softBlue : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(resumeName != null ? Icons.picture_as_pdf_rounded : Icons.warning_amber_rounded,
                                color: resumeName != null ? AppUi.accent : const Color(0xFFD97706)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                resumeName != null
                                    ? 'Your profile resume ($resumeName) will be shared.'
                                    : 'No resume in your profile yet. You can still apply, but adding one from Profile → My Resume improves your chances.',
                                style: const TextStyle(fontSize: 13, color: AppColors.primaryText, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(job.isCoverLetterRequired ? 'Cover letter *' : 'Cover letter (optional)'),
                      _field(
                        _coverLetter,
                        hint: 'Why are you a great fit for this role?',
                        maxLines: 5,
                        validator: (v) =>
                            job.isCoverLetterRequired && (v ?? '').trim().isEmpty ? 'A cover letter is required for this job' : null,
                      ),
                      if (job.screeningQuestions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _label('Screening questions'),
                        for (var i = 0; i < job.screeningQuestions.length; i++) ...[
                          Text('${i + 1}. ${job.screeningQuestions[i]}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                          const SizedBox(height: 6),
                          _field(
                            _answers[i],
                            hint: 'Your answer',
                            maxLines: 3,
                            validator: (v) => (v ?? '').trim().isEmpty ? 'Please answer this question' : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                          child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: GestureDetector(
                    onTap: _submitting ? null : _submit,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(gradient: AppUi.heroGradient, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: _submitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit application',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
      );

  Widget _field(TextEditingController c, {required String hint, int maxLines = 1, FormFieldValidator<String>? validator}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      minLines: 1,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.borderDark),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppUi.accent)),
      ),
    );
  }
}
