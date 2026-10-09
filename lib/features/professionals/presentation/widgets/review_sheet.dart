import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../data/professionals_repository.dart';
import '../../domain/professional_model.dart';
import '../providers/professional_reviews_provider.dart';

/// Write or update a review. Pops with `true` once saved.
class ReviewSheet extends ConsumerStatefulWidget {
  final Professional professional;

  const ReviewSheet({super.key, required this.professional});

  static Future<bool> show(BuildContext context, Professional professional) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewSheet(professional: professional),
    );
    return saved == true;
  }

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  final _comment = TextEditingController();
  double _rating = 0;
  bool _loading = true;
  bool _saving = false;
  bool _existing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(professionalsRepositoryProvider).getMyReview(widget.professional.id).then((review) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (review != null) {
          _existing = true;
          _rating = review.rating;
          _comment.text = review.comment ?? '';
        }
      });
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      setState(() => _error = 'Please choose a rating.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(professionalsRepositoryProvider).submitReview(widget.professional.id, _rating, _comment.text.trim());
      ref.invalidate(professionalReviewsProvider(widget.professional.id));
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 16),
                Text(_existing ? 'Update your review' : 'Write a review', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
                const SizedBox(height: 4),
                Text('How was your session with ${widget.professional.name}?', style: AppText.subtitle),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppUi.accent)))
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        iconSize: 40,
                        onPressed: () => setState(() => _rating = i + 1.0),
                        icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: i < _rating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1)),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comment,
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppText.body,
                    decoration: InputDecoration(
                      hintText: 'Share what went well or what could be better (optional)',
                      hintStyle: AppText.label,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppUi.accent)),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: AppText.label.copyWith(color: AppColors.error)),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(text: _saving ? 'Saving…' : (_existing ? 'Update review' : 'Submit review'), onPressed: _saving ? null : _save),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
