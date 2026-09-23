import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'resume_pdf_generator.dart';
import 'edit_resume_screen.dart';

class ResumePreviewScreen extends ConsumerStatefulWidget {
  const ResumePreviewScreen({super.key});

  @override
  ConsumerState<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends ConsumerState<ResumePreviewScreen> {
  int _selectedTemplateIndex = 0;
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

  void _downloadPdf(BuildContext context) async {
    final user = ref.read(authProvider).currentUser;
    if (user == null) return;
    
    final pdfBytes = await ResumePdfGenerator.generateResume(user, _selectedTemplateIndex);
    await Printing.sharePdf(bytes: pdfBytes, filename: '${user.fullName.replaceAll(' ', '_')}_Resume.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(color: AppColors.background),
          
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedTemplateIndex = index;
                      });
                    },
                    itemCount: _designNames.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedTemplateIndex == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: IgnorePointer(
                          ignoring: !isSelected,
                          child: PdfPreview(
                            build: (format) => ResumePdfGenerator.generateResume(user, index),
                            allowPrinting: false,
                            allowSharing: false,
                            canChangePageFormat: false,
                            canChangeOrientation: false,
                            canDebug: false,
                            initialPageFormat: PdfPageFormat.a4,
                            useActions: false,
                            scrollViewDecoration: const BoxDecoration(color: AppColors.background),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Design ${ _selectedTemplateIndex + 1 } of 10: ${_designNames[_selectedTemplateIndex]}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText),
                  ),
                ),
                
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'Edit Details',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const EditResumeScreen()));
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Download PDF',
                          onPressed: () => _downloadPdf(context),
                        ),
                      )
                    ],
                  ),
                ),
                )
              ],
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Resume Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primaryText,
                  shadows: [Shadow(color: Colors.white, blurRadius: 10)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
