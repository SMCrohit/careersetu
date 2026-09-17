import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';

class ResumePdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String filename;

  const ResumePdfViewerScreen({
    Key? key,
    required this.filePath,
    required this.filename,
  }) : super(key: key);

  @override
  State<ResumePdfViewerScreen> createState() => _ResumePdfViewerScreenState();
}

class _ResumePdfViewerScreenState extends State<ResumePdfViewerScreen> {
  bool _isDownloading = false;

  void _downloadResume() async {
    setState(() => _isDownloading = true);
    try {
      final file = File(widget.filePath);
      final bytes = await file.readAsBytes();
      
      final filename = widget.filename;
      final nameWithoutExt = filename.contains('.') 
          ? filename.substring(0, filename.lastIndexOf('.')) 
          : filename;

      final String? savedPath = await FileSaver.instance.saveAs(
        name: nameWithoutExt,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        setState(() => _isDownloading = false);
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to: $savedPath', style: const TextStyle(color: Colors.white)), 
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download resume', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.filename, style: const TextStyle(fontSize: 18, color: AppColors.primaryText)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        actions: [
          if (_isDownloading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(
              icon: const Icon(Icons.download, color: AppColors.primaryBrand),
              tooltip: 'Download',
              onPressed: _downloadResume,
            ),
        ],
      ),
      body: PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: true,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
      ),
    );
  }
}
