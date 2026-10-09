import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _supportEmail = 'support@careersetu.com';
  String _appVersion = '…';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    } catch (_) {
      if (mounted) setState(() => _appVersion = '1.0.0 (1)');
    }
  }

  Future<void> _launchURL(String urlString) async {
    try {
      if (!await launchUrl(Uri.parse(urlString), mode: LaunchMode.inAppWebView) && mounted) {
        CustomToast.showError(context, 'Could not open the page.');
      }
    } catch (_) {
      if (mounted) CustomToast.showError(context, 'Could not open the page.');
    }
  }

  Future<void> _contactUs() async {
    bool opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'mailto', path: _supportEmail));
    } catch (_) {}
    if (!opened) {
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      if (mounted) CustomToast.showSuccess(context, 'Email address copied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: const Text('Settings', style: AppText.screenTitle),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.of(context).padding.bottom),
          children: [
            _header(),
            _sectionTitle('General'),
            _group([
              _tile(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () => _launchURL('https://www.google.com')),
              _tile(Icons.article_outlined, 'Terms & Conditions', onTap: () => _launchURL('https://www.google.com')),
            ]),
            _sectionTitle('Support'),
            _group([
              _tile(Icons.mail_outline_rounded, 'Contact Us', subtitle: _supportEmail, onTap: _contactUs),
              _tile(Icons.help_outline_rounded, 'Help Center', onTap: () => _launchURL('https://www.google.com')),
            ]),
            const SizedBox(height: 28),
            Center(child: Text('Made with ❤️ for students across India', style: AppText.label)),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppUi.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Career Setu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Version $_appVersion', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
        child: Text(title, style: AppText.sectionTitle),
      );

  /// White card holding rows separated by thin dividers.
  Widget _group(List<Widget> tiles) {
    return Container(
      decoration: AppUi.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1) const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, {String? subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppUi.iconTile, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppUi.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle),
                    if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle, style: AppText.label)],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right, color: AppColors.secondaryText, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
