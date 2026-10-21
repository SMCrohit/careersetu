import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../data/word_bank.dart';

enum LetterStatus {
  initial,
  notInWord,
  wrongPosition,
  correctPosition,
}

class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  static const int _maxGuesses = 6;
  static const int _wordLength = 5;

  late WordEntry _targetWordEntry;
  bool _hasInitialGame = false;
  List<String> _guesses = [];
  String _currentGuess = '';
  bool _isGameOver = false;
  bool _hasWon = false;
  String? _errorMessage;

  // Track keyboard letter statuses
  final Map<String, LetterStatus> _keyboardStatus = {};

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    final String? previousWord = _hasInitialGame ? _targetWordEntry.word : null;
    setState(() {
      _targetWordEntry = WordBank.getRandomWord(
        excludeWord: previousWord,
      );
      _hasInitialGame = true;
      _guesses = [];
      _currentGuess = '';
      _isGameOver = false;
      _hasWon = false;
      _errorMessage = null;
      _keyboardStatus.clear();
    });
  }

  void _onKeyPressed(String key) {
    if (_isGameOver) return;

    setState(() {
      _errorMessage = null;
      if (key == 'ENTER') {
        _submitGuess();
      } else if (key == 'DEL') {
        if (_currentGuess.isNotEmpty) {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
        }
      } else if (_currentGuess.length < _wordLength) {
        _currentGuess += key;
      }
    });
  }

  void _submitGuess() {
    if (_currentGuess.length < _wordLength) {
      _showToast('Word must be 5 letters');
      return;
    }

    if (!WordBank.isValidGuess(_currentGuess)) {
      _showToast('Not a valid 5-letter word');
      return;
    }

    final guess = _currentGuess.toUpperCase();
    _guesses.add(guess);

    // Update keyboard statuses
    final target = _targetWordEntry.word;
    for (int i = 0; i < _wordLength; i++) {
      final char = guess[i];
      if (target[i] == char) {
        _keyboardStatus[char] = LetterStatus.correctPosition;
      } else if (target.contains(char)) {
        if (_keyboardStatus[char] != LetterStatus.correctPosition) {
          _keyboardStatus[char] = LetterStatus.wrongPosition;
        }
      } else {
        if (_keyboardStatus[char] == null || _keyboardStatus[char] == LetterStatus.initial) {
          _keyboardStatus[char] = LetterStatus.notInWord;
        }
      }
    }

    if (guess == target) {
      _isGameOver = true;
      _hasWon = true;
      _showEndGameDialog(won: true);
    } else if (_guesses.length >= _maxGuesses) {
      _isGameOver = true;
      _hasWon = false;
      _showEndGameDialog(won: false);
    }

    _currentGuess = '';
  }

  void _showToast(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  LetterStatus _getLetterStatus(String guess, int index) {
    final char = guess[index];
    final target = _targetWordEntry.word;

    if (target[index] == char) {
      return LetterStatus.correctPosition;
    }

    // Accurate frequency check for duplicate letters
    int targetCount = 0;
    int previousMatchesOrGreens = 0;

    for (int i = 0; i < _wordLength; i++) {
      if (target[i] == char) targetCount++;
    }

    for (int i = 0; i < _wordLength; i++) {
      if (guess[i] == char) {
        if (target[i] == char) {
          targetCount--; // Green has priority
        }
      }
    }

    for (int i = 0; i <= index; i++) {
      if (guess[i] == char && target[i] != char) {
        previousMatchesOrGreens++;
      }
    }

    if (previousMatchesOrGreens <= targetCount) {
      return LetterStatus.wrongPosition;
    }

    return LetterStatus.notInWord;
  }

  Color _getStatusColor(LetterStatus status) {
    switch (status) {
      case LetterStatus.correctPosition:
        return const Color(0xFF10B981); // Emerald green
      case LetterStatus.wrongPosition:
        return const Color(0xFFF59E0B); // Amber
      case LetterStatus.notInWord:
        return const Color(0xFF64748B); // Slate grey
      case LetterStatus.initial:
        return Colors.white;
    }
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
    _showSheet(
      icon: Icons.refresh_rounded,
      iconColor: AppColors.error,
      title: 'Start a new game?',
      message: 'Your current progress will be lost and a fresh secret word will be picked.',
      actions: [
        SecondaryButton(text: 'Keep playing', onPressed: () => Navigator.pop(context)),
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
            child: const Text('New Word', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _showEndGameDialog({required bool won}) {
    _showSheet(
      dismissible: false,
      icon: won ? Icons.emoji_events_rounded : Icons.lightbulb_outline_rounded,
      iconColor: won ? const Color(0xFFF59E0B) : AppUi.accent,
      title: won ? 'Brilliant deduction! 🎉' : 'Nice try!',
      message: won
          ? 'You solved the word in ${_guesses.length} / $_maxGuesses tries.'
          : 'The secret word was "${_targetWordEntry.word}".',
      extraContent: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppUi.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppUi.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_targetWordEntry.category, style: AppText.badge.copyWith(color: AppUi.accent)),
                ),
                const SizedBox(width: 8),
                Text(
                  _targetWordEntry.word,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppUi.ink, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_targetWordEntry.hint, style: AppText.label.copyWith(fontSize: 13, height: 1.4)),
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
          text: 'Next Word',
          onPressed: () {
            Navigator.pop(context);
            _startNewGame();
          },
        ),
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
          title: const Text('Word Guess', style: AppText.screenTitle),
          actions: [
            IconButton(
              tooltip: 'New Word',
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pill(Icons.category_rounded, 'Category: ${_targetWordEntry.category}'),
                    const SizedBox(width: 10),
                    _pill(Icons.edit_note_rounded, 'Try ${_guesses.length + (_isGameOver ? 0 : 1)}/$_maxGuesses'),
                  ],
                ),
              ),

              // Toast error banner if word is incomplete
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),

              // Word Guess 6x5 Grid
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int r = 0; r < _maxGuesses; r++) _buildWordRow(r),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // "How to Play" rule banner so the screen never looks blank
              _buildHowToPlayBanner(),

              // On-screen Virtual Keyboard
              _buildVirtualKeyboard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppUi.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppUi.accent),
          const SizedBox(width: 6),
          Text(text, style: AppText.value.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildWordRow(int rowIndex) {
    final bool isCompletedRow = rowIndex < _guesses.length;
    final bool isCurrentRow = rowIndex == _guesses.length;
    final String rowGuess = isCompletedRow
        ? _guesses[rowIndex]
        : (isCurrentRow ? _currentGuess : '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_wordLength, (colIndex) {
          final String letter = colIndex < rowGuess.length ? rowGuess[colIndex] : '';
          final LetterStatus status = isCompletedRow
              ? _getLetterStatus(_guesses[rowIndex], colIndex)
              : LetterStatus.initial;

          Color bgColor = Colors.white;
          Color textColor = AppUi.ink;
          Border border = Border.all(color: const Color(0xFFCBD5E1), width: 1.5);

          if (isCompletedRow) {
            bgColor = _getStatusColor(status);
            textColor = Colors.white;
            border = Border.all(color: Colors.transparent);
          } else if (isCurrentRow && letter.isNotEmpty) {
            border = Border.all(color: AppUi.accent, width: 2);
          }

          return Container(
            width: 52,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: isCompletedRow ? null : AppUi.cardShadow,
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHowToPlayBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _guideItem(const Color(0xFF10B981), 'Right Spot'),
          Container(width: 1, height: 16, color: Colors.grey.shade300),
          _guideItem(const Color(0xFFF59E0B), 'Wrong Spot'),
          Container(width: 1, height: 16, color: Colors.grey.shade300),
          _guideItem(const Color(0xFF64748B), 'Not in Word'),
        ],
      ),
    );
  }

  Widget _guideItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
      ],
    );
  }

  Widget _buildVirtualKeyboard() {
    const List<String> row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
    const List<String> row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
    const List<String> row3 = ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'];

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 14),
      child: Column(
        children: [
          _buildKeyboardRow(row1),
          const SizedBox(height: 5),
          _buildKeyboardRow(row2),
          const SizedBox(height: 5),
          _buildKeyboardRow(row3),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((k) {
        final bool isSpecial = k == 'ENTER' || k == 'DEL';
        final LetterStatus? status = _keyboardStatus[k];

        Color btnColor = Colors.white;
        Color textColor = AppUi.ink;

        if (status != null && !isSpecial) {
          btnColor = _getStatusColor(status);
          textColor = Colors.white;
        } else if (isSpecial) {
          btnColor = const Color(0xFFE2E8F0);
          textColor = AppUi.ink;
        }

        return Expanded(
          flex: isSpecial ? 3 : 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: btnColor,
              borderRadius: BorderRadius.circular(8),
              elevation: 1,
              shadowColor: Colors.black12,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _onKeyPressed(k),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: isSpecial && k == 'DEL'
                      ? const Icon(Icons.backspace_outlined, size: 18, color: AppUi.ink)
                      : Text(
                          k,
                          style: TextStyle(
                            fontSize: isSpecial ? 11 : 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
