import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/resume_provider.dart';
import '../widgets/resume_ui.dart';
import 'resume_pdf_generator.dart';
import 'edit_resume_screen.dart';

class ResumePreviewScreen extends ConsumerStatefulWidget {
  const ResumePreviewScreen({super.key});

  @override
  ConsumerState<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends ConsumerState<ResumePreviewScreen> {
  int _selectedTemplateIndex = 0;
  bool _isDownloading = false;
  final PageController _pageController = PageController(viewportFraction: 1.0);

  final List<String> _designNames = [
    'Classic Navy',
    'Modern Noir',
    'Creative Teal',
    'Elegant Maroon',
    'Tech Slate',
    'Corporate Grey',
    'Vibrant Orange',
    'Traditional Green',
    'Compact Purple',
    'Executive Gold'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    final draft = ref.read(chatResumeProvider).draft;
    final imageUrl = ref.read(authProvider).currentUser?.profileImageUrl;
    setState(() => _isDownloading = true);
    try {
      final pdfBytes = await ResumePdfGenerator.generateResume(draft, imageUrl, _selectedTemplateIndex);
      final name = draft.fullName.isNotEmpty ? draft.fullName.replaceAll(' ', '_') : 'My';
      await Printing.sharePdf(bytes: pdfBytes, filename: '${name}_Resume.pdf');
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Could not create the PDF. Please try again.');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(chatResumeProvider).draft;
    final imageUrl = ref.watch(authProvider).currentUser?.profileImageUrl;
    final draftKey = draft.toJson().toString().hashCode;

    return Container(
      decoration: const BoxDecoration(gradient: ResumeUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: const Text('Resume Preview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        body: !draft.hasContent
            ? _buildEmptyState()
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _selectedTemplateIndex = index),
                      itemCount: _designNames.length,
                      itemBuilder: (context, index) {
                        return IgnorePointer(
                          ignoring: _selectedTemplateIndex != index,
                          child: PdfPreview(
                            // Re-render when the draft changes after editing.
                            key: ValueKey('$index-$draftKey'),
                            build: (format) => ResumePdfGenerator.generateResume(draft, imageUrl, index),
                            allowPrinting: false,
                            allowSharing: false,
                            canChangePageFormat: false,
                            canChangeOrientation: false,
                            canDebug: false,
                            initialPageFormat: PdfPageFormat.a4,
                            useActions: false,
                            scrollViewDecoration: const BoxDecoration(color: Colors.transparent),
                            pdfPreviewPageDecoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: ResumeUi.cardShadow,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildTemplateSwitcher(),
                  _buildActions(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(gradient: ResumeUi.accentGradient, shape: BoxShape.circle),
              child: const Icon(Icons.description_outlined, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Nothing to preview yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 6),
            const Text('Chat with the resume assistant to build your resume first.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: ResumeUi.accent,
            onPressed: _selectedTemplateIndex > 0
                ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(_designNames[_selectedTemplateIndex],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText)),
                Text('Design ${_selectedTemplateIndex + 1} of ${_designNames.length} · swipe to change',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            color: ResumeUi.accent,
            onPressed: _selectedTemplateIndex < _designNames.length - 1
                ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditResumeScreen())),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Edit resume', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _isDownloading ? null : _downloadPdf,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: ResumeUi.heroGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: _isDownloading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Download PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
