import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';

class StroopColor {
  final String name;
  final Color color;

  const StroopColor(this.name, this.color);
}

class StroopTestScreen extends StatefulWidget {
  const StroopTestScreen({super.key});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends State<StroopTestScreen> with SingleTickerProviderStateMixin {
  static const int _gameDurationSeconds = 45;
  static final Random _random = Random();

  static const List<StroopColor> _palette = [
    StroopColor('RED', Color(0xFFEF4444)),
    StroopColor('BLUE', Color(0xFF2563EB)),
    StroopColor('GREEN', Color(0xFF10B981)),
    StroopColor('YELLOW', Color(0xFFD97706)),
    StroopColor('PURPLE', Color(0xFF9333EA)),
  ];

  late StroopColor _currentWord;
  late StroopColor _currentInk;
  List<StroopColor> _options = [];

  int _score = 0;
  int _streak = 0;
  int _peakStreak = 0;
  int _correctCount = 0;
  int _totalAnswered = 0;
  int _secondsLeft = _gameDurationSeconds;

  Timer? _timer;
  bool _isPlaying = false;
  bool _isFinished = false;

  late AnimationController _pulseController;
  Color? _feedbackFlashColor;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startNewGame() {
    _timer?.cancel();
    setState(() {
      _score = 0;
      _streak = 0;
      _peakStreak = 0;
      _correctCount = 0;
      _totalAnswered = 0;
      _secondsLeft = _gameDurationSeconds;
      _isPlaying = true;
      _isFinished = false;
      _feedbackFlashColor = null;
      _nextRound();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        setState(() {
          _secondsLeft = 0;
          _isPlaying = false;
          _isFinished = true;
        });
        _showEndGameDialog();
      }
    });
  }

  void _nextRound() {
    // Pick random word and random ink color
    final wordIndex = _random.nextInt(_palette.length);
    _currentWord = _palette[wordIndex];

    // 70% clash probability, 30% match
    final bool shouldClash = _random.nextDouble() < 0.70;
    if (shouldClash) {
      List<StroopColor> candidates = _palette.where((c) => c.name != _currentWord.name).toList();
      _currentInk = candidates[_random.nextInt(candidates.length)];
    } else {
      _currentInk = _currentWord;
    }

    // Pick 4 options including the correct ink color, and shuffle
    final otherColors = _palette.where((c) => c.name != _currentInk.name).toList()..shuffle(_random);
    _options = [_currentInk, otherColors[0], otherColors[1], otherColors[2]]..shuffle(_random);
  }

  void _onOptionSelected(StroopColor chosen) {
    if (!_isPlaying || _isFinished) return;

    _totalAnswered++;
    final bool isCorrect = chosen.name == _currentInk.name;

    setState(() {
      if (isCorrect) {
        _streak++;
        if (_streak > _peakStreak) _peakStreak = _streak;
        _correctCount++;
        // Streak multiplier scoring
        final multiplier = (_streak ~/ 4) + 1;
        _score += 10 * multiplier;
        _feedbackFlashColor = const Color(0xFF10B981).withOpacity(0.2);
      } else {
        _streak = 0;
        _feedbackFlashColor = AppColors.error.withOpacity(0.2);
      }
    });

    _pulseController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted && _isPlaying) {
        setState(() {
          _feedbackFlashColor = null;
          _nextRound();
        });
      }
    });
  }

  String get _performanceRating {
    if (_score >= 250) return 'Lightning Reflexes ⚡';
    if (_score >= 150) return 'Sharp Mind 🎯';
    if (_score >= 80) return 'Focused Thinker 🧠';
    return 'Getting Started 🌱';
  }

  Future<void> _showSheet({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    Widget? extraContent,
    required List<Widget> actions,
    bool dismissible = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: const BoxDecoration(
          gradient: AppUi.backgroundGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 34),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: AppText.subtitle),
              if (extraContent != null) ...[
                const SizedBox(height: 14),
                extraContent,
              ],
              const SizedBox(height: 20),
              Row(children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: actions[i]),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    _timer?.cancel();
    _showSheet(
      icon: Icons.refresh_rounded,
      iconColor: AppColors.error,
      title: 'Restart Blitz?',
      message: 'Your current score and streak will be reset with a fresh 45s countdown.',
      actions: [
        SecondaryButton(
          text: 'Resume',
          onPressed: () {
            Navigator.pop(context);
            if (!_isFinished && _secondsLeft > 0) {
              _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (_secondsLeft > 1) {
                  setState(() => _secondsLeft--);
                } else {
                  _timer?.cancel();
                  setState(() {
                    _secondsLeft = 0;
                    _isPlaying = false;
                    _isFinished = true;
                  });
                  _showEndGameDialog();
                }
              });
            }
          },
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Restart', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _showEndGameDialog() {
    final accuracy = _totalAnswered > 0 ? ((_correctCount / _totalAnswered) * 100).toInt() : 0;

    _showSheet(
      dismissible: false,
      icon: Icons.bolt_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: 'Time\'s Up! ⏱️',
      message: 'You scored $_score points. $_performanceRating',
      extraContent: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppUi.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Accuracy', '$accuracy%'),
            Container(width: 1, height: 32, color: Colors.grey.shade200),
            _statItem('Best Combo', '🔥 $_peakStreak'),
            Container(width: 1, height: 32, color: Colors.grey.shade200),
            _statItem('Correct', '$_correctCount/$_totalAnswered'),
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          text: 'Back to games',
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
        PrimaryButton(
          text: 'Play Again',
          onPressed: () {
            Navigator.pop(context);
            _startNewGame();
          },
        ),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppUi.ink)),
        const SizedBox(height: 2),
        Text(label, style: AppText.label.copyWith(fontSize: 11)),
      ],
    );
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
          title: const Text('Color Reflex', style: AppText.screenTitle),
          actions: [
            IconButton(
              tooltip: 'Restart',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _showResetConfirmation,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header Status Pills
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pill(Icons.timer_rounded, '${_secondsLeft}s', isUrgent: _secondsLeft <= 10),
                    const SizedBox(width: 8),
                    _pill(Icons.star_rounded, '$_score pts'),
                    const SizedBox(width: 8),
                    _pill(Icons.local_fire_department_rounded, 'Streak: $_streak'),
                  ],
                ),
              ),

              // How-to-play instruction banner at the top
              _buildHowToPlayPrompt(),

              // Big Word Display Card
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _feedbackFlashColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppUi.cardShadow,
                        border: Border.all(
                          color: _streak > 3 ? AppUi.accent.withOpacity(0.5) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'WHAT IS THE INK COLOR?',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _currentWord.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: _currentInk.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_streak >= 3)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '🔥 Combo x${(_streak ~/ 4) + 1} Multiplier!',
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Educational Science Note below the card
              _buildBrainScienceNote(),

              // 4 Color Option Pads
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  children: _options.map((opt) => _buildOptionButton(opt)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, {bool isUrgent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppUi.cardShadow,
        border: isUrgent ? Border.all(color: AppColors.error, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isUrgent ? AppColors.error : AppUi.accent),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppText.value.copyWith(
              fontSize: 13,
              color: isUrgent ? AppColors.error : AppUi.ink,
              fontWeight: isUrgent ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayPrompt() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppUi.accent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rule: Tap the INK color of the text, ignore the word itself!',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppUi.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrainScienceNote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppUi.softBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, size: 18, color: AppUi.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Stroop Effect trains your brain\'s prefrontal cortex to resist automatic habits and sharpen mental speed.',
              style: TextStyle(fontSize: 11, color: AppUi.ink.withOpacity(0.8), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(StroopColor colorOption) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onOptionSelected(colorOption),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorOption.color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colorOption.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                colorOption.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorOption.color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
