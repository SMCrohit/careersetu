import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';

class MathProblem {
  final String equation;
  final int answer;
  final List<int> options;

  const MathProblem({
    required this.equation,
    required this.answer,
    required this.options,
  });
}

class MathBlitzScreen extends StatefulWidget {
  const MathBlitzScreen({super.key});

  @override
  State<MathBlitzScreen> createState() => _MathBlitzScreenState();
}

class _MathBlitzScreenState extends State<MathBlitzScreen> with SingleTickerProviderStateMixin {
  static const int _initialDuration = 60;
  static final Random _random = Random();

  late MathProblem _currentProblem;
  int _score = 0;
  int _streak = 0;
  int _peakStreak = 0;
  int _correctCount = 0;
  int _totalAnswered = 0;
  int _secondsLeft = _initialDuration;

  Timer? _timer;
  bool _isPlaying = false;
  bool _isFinished = false;

  int? _selectedAnswer;
  bool? _lastAnswerCorrect;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      _secondsLeft = _initialDuration;
      _isPlaying = true;
      _isFinished = false;
      _selectedAnswer = null;
      _lastAnswerCorrect = null;
      _nextProblem();
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

  void _nextProblem() {
    _selectedAnswer = null;
    _lastAnswerCorrect = null;

    int difficulty = (_streak ~/ 5).clamp(0, 3);
    int opType = _random.nextInt(4); // 0: +, 1: -, 2: *, 3: /

    String eq = '';
    int ans = 0;

    if (opType == 0) {
      // Addition
      int a = _random.nextInt(25 + difficulty * 25) + 5;
      int b = _random.nextInt(25 + difficulty * 25) + 5;
      ans = a + b;
      eq = '$a + $b';
    } else if (opType == 1) {
      // Subtraction
      int a = _random.nextInt(40 + difficulty * 30) + 15;
      int b = _random.nextInt(a - 5) + 3;
      ans = a - b;
      eq = '$a - $b';
    } else if (opType == 2) {
      // Multiplication
      int a = _random.nextInt(7 + difficulty * 3) + 3;
      int b = _random.nextInt(9 + difficulty * 3) + 2;
      ans = a * b;
      eq = '$a × $b';
    } else {
      // Division
      int divisor = _random.nextInt(7 + difficulty * 2) + 2;
      int quotient = _random.nextInt(10 + difficulty * 3) + 2;
      int dividend = divisor * quotient;
      ans = quotient;
      eq = '$dividend ÷ $divisor';
    }

    // Generate 3 plausible unique distractors
    Set<int> opts = {ans};
    while (opts.length < 4) {
      int delta = (_random.nextInt(7) + 1) * (_random.nextBool() ? 1 : -1);
      int candidate = ans + delta;
      if (candidate > 0 && candidate != ans) {
        opts.add(candidate);
      }
    }

    List<int> shuffledOptions = opts.toList()..shuffle(_random);
    _currentProblem = MathProblem(equation: eq, answer: ans, options: shuffledOptions);
  }

  void _onAnswerSelected(int chosen) {
    if (!_isPlaying || _isFinished || _selectedAnswer != null) return;

    _totalAnswered++;
    final bool isCorrect = chosen == _currentProblem.answer;

    setState(() {
      _selectedAnswer = chosen;
      _lastAnswerCorrect = isCorrect;

      if (isCorrect) {
        _streak++;
        if (_streak > _peakStreak) _peakStreak = _streak;
        _correctCount++;
        final multiplier = (_streak ~/ 4) + 1;
        _score += 15 * multiplier;
        // Bonus 2 seconds for quick solving
        _secondsLeft = (_secondsLeft + 2).clamp(1, 99);
      } else {
        _streak = 0;
      }
    });

    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted && _isPlaying) {
        setState(() {
          _nextProblem();
        });
      }
    });
  }

  String get _performanceRating {
    if (_score >= 300) return 'Aptitude Genius 🏆';
    if (_score >= 180) return 'Speed Master ⚡';
    if (_score >= 90) return 'Solid Calculator 🎯';
    return 'Good Practice 🌱';
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
      title: 'Restart Math Blitz?',
      message: 'Your score and streak will be reset with a fresh 60s countdown.',
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
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: 'Round Complete! ⚡',
      message: 'You scored $_score pts. $_performanceRating',
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
            _statItem('Solved', '$_correctCount'),
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
          title: const Text('Math Blitz', style: AppText.screenTitle),
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
                    _pill(Icons.stars_rounded, '$_score pts'),
                    const SizedBox(width: 8),
                    _pill(Icons.local_fire_department_rounded, 'Streak: $_streak'),
                  ],
                ),
              ),

              // How-to-play instruction banner
              _buildHowToPlayPrompt(),

              // Big Equation Stage
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppUi.cardShadow,
                        border: Border.all(
                          color: _streak >= 5 ? AppUi.accent.withOpacity(0.6) : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'SOLVE THE EQUATION',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _currentProblem.equation,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: AppUi.ink,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_streak >= 3)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '⚡ +2s Time Bonus Active!',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
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

              // Educational Aptitude Tip below stage
              _buildAptitudeTip(),

              // 4 Option Buttons (2x2 Grid)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: _currentProblem.options.map((opt) => _buildOptionButton(opt)).toList(),
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
          Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rule: Select correct answer fast! Every hit adds +2s to timer.',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppUi.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAptitudeTip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppUi.softBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppUi.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aptitude Tip: For fast multiplication, decompose numbers into tens and ones (e.g. 14 × 6 = 10×6 + 4×6 = 84).',
              style: TextStyle(fontSize: 11, color: AppUi.ink.withOpacity(0.8), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int value) {
    Color bgColor = Colors.white;
    Color textColor = AppUi.ink;
    Border border = Border.all(color: const Color(0xFFE2E8F0), width: 1.5);

    if (_selectedAnswer != null) {
      if (value == _currentProblem.answer) {
        bgColor = const Color(0xFF10B981); // Emerald green
        textColor = Colors.white;
        border = Border.all(color: Colors.transparent);
      } else if (value == _selectedAnswer) {
        bgColor = AppColors.error;
        textColor = Colors.white;
        border = Border.all(color: Colors.transparent);
      }
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onAnswerSelected(value),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: border,
          ),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
