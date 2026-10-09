import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late List<List<int>> _initialPuzzle;
  late List<List<int>> _solution;

  late List<List<int>> _currentGrid;
  late List<List<bool>> _isFixed;
  
  int? _selectedRow;
  int? _selectedCol;
  
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _generateSudoku();
    _currentGrid = List.generate(6, (r) => List.generate(6, (c) => _initialPuzzle[r][c]));
    _isFixed = List.generate(6, (r) => List.generate(6, (c) => _initialPuzzle[r][c] != 0));
    _selectedRow = null;
    _selectedCol = null;
    _secondsElapsed = 0;
    _isFinished = false;
    _startTimer();
  }

  void _generateSudoku() {
    final random = Random();
    
    // Base solved 6x6 Sudoku
    List<List<int>> base = [
      [1, 2, 3, 4, 5, 6],
      [4, 5, 6, 1, 2, 3],
      [2, 3, 1, 5, 6, 4],
      [5, 6, 4, 2, 3, 1],
      [3, 1, 2, 6, 4, 5],
      [6, 4, 5, 3, 1, 2]
    ];

    // Number substitution
    List<int> numbers = [1, 2, 3, 4, 5, 6];
    numbers.shuffle(random);
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        base[r][c] = numbers[base[r][c] - 1];
      }
    }

    // Swap rows within blocks (block height is 2)
    for (int b = 0; b < 3; b++) {
      int r1 = b * 2;
      int r2 = r1 + 1;
      if (random.nextBool()) {
        List<int> temp = base[r1];
        base[r1] = base[r2];
        base[r2] = temp;
      }
    }

    // Swap columns within blocks (block width is 3)
    for (int b = 0; b < 2; b++) {
      for (int i = 0; i < 3; i++) {
        int c1 = b * 3 + i;
        int c2 = b * 3 + random.nextInt(3);
        for (int r = 0; r < 6; r++) {
          int temp = base[r][c1];
          base[r][c1] = base[r][c2];
          base[r][c2] = temp;
        }
      }
    }

    _solution = List.generate(6, (r) => List.from(base[r]));
    _initialPuzzle = List.generate(6, (r) => List.from(base[r]));

    // Determine difficulty: random between easy, medium, hard
    // Total cells = 36
    // Easy: remove ~16 cells, Medium: remove ~20 cells, Hard: remove ~24 cells
    int difficulty = random.nextInt(3);
    int cellsToRemove = difficulty == 0 ? random.nextInt(3) + 15 : (difficulty == 1 ? random.nextInt(3) + 19 : random.nextInt(3) + 23);

    int removed = 0;
    while (removed < cellsToRemove) {
      int r = random.nextInt(6);
      int c = random.nextInt(6);
      if (_initialPuzzle[r][c] != 0) {
        _initialPuzzle[r][c] = 0;
        removed++;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isFinished) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onCellTap(int row, int col) {
    if (_isFinished) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _onNumberTap(int number) {
    if (_isFinished || _selectedRow == null || _selectedCol == null) return;
    if (_isFixed[_selectedRow!][_selectedCol!]) return;

    setState(() {
      _currentGrid[_selectedRow!][_selectedCol!] = number;
      _checkWinCondition();
    });
  }

  void _checkWinCondition() {
    bool isWin = true;
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        if (_currentGrid[r][c] != _solution[r][c]) {
          isWin = false;
          break;
        }
      }
    }
    
    if (isWin) {
      _isFinished = true;
      _timer?.cancel();
      _showWinDialog();
    }
  }

  int get _filledCount => _currentGrid.expand((r) => r).where((v) => v != 0).length;

  /// True when the value at (row, col) repeats in its row, column or 2×3 box.
  bool _hasConflict(int row, int col) {
    final v = _currentGrid[row][col];
    if (v == 0) return false;
    for (var i = 0; i < 6; i++) {
      if (i != col && _currentGrid[row][i] == v) return true;
      if (i != row && _currentGrid[i][col] == v) return true;
    }
    final br = (row ~/ 2) * 2, bc = (col ~/ 3) * 3;
    for (var r = br; r < br + 2; r++) {
      for (var c = bc; c < bc + 3; c++) {
        if ((r != row || c != col) && _currentGrid[r][c] == v) return true;
      }
    }
    return false;
  }

  Future<void> _showSheet({required IconData icon, required Color iconColor, required String title, required String message, required List<Widget> actions, bool dismissible = true}) {
    return showModalBottomSheet(
      context: context,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: AppText.subtitle),
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
      title: 'Reset puzzle?',
      message: 'All the numbers you\'ve entered will be cleared and the timer restarts.',
      actions: [
        SecondaryButton(text: 'Keep playing', onPressed: () => Navigator.pop(context)),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(_initGame);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _showWinDialog() {
    _showSheet(
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: 'You solved it! 🎉',
      message: 'Finished in $_formattedTime. Great focus!',
      dismissible: false,
      actions: [
        SecondaryButton(
          text: 'Back to games',
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
        PrimaryButton(
          text: 'Play again',
          onPressed: () {
            Navigator.pop(context);
            setState(_initGame);
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
          title: const Text('Sudoku', style: AppText.screenTitle),
          actions: [
            IconButton(tooltip: 'Reset', icon: const Icon(Icons.refresh_rounded), onPressed: _showResetConfirmation),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pill(Icons.timer_outlined, _formattedTime),
                    const SizedBox(width: 10),
                    _pill(Icons.grid_view_rounded, 'Filled $_filledCount/36'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Fill every row, column and box with 1–6.', style: AppText.label),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: AppUi.card(),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: AppUi.ink, width: 2), borderRadius: BorderRadius.circular(4)),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                            itemCount: 36,
                            itemBuilder: (context, index) => _cell(index ~/ 6, index % 6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) => _buildNumpadButton(i + 1)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ...List.generate(2, (i) => _buildNumpadButton(i + 5)),
                        _buildNumpadButton(0, isErase: true),
                        const SizedBox(width: 56),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppUi.cardShadow),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppUi.accent),
        const SizedBox(width: 6),
        Text(text, style: AppText.value.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }

  Widget _cell(int row, int col) {
    final isSelected = row == _selectedRow && col == _selectedCol;
    final inLine = _selectedRow != null && (row == _selectedRow || col == _selectedCol);
    final isFixed = _isFixed[row][col];
    final value = _currentGrid[row][col];
    final conflict = !isFixed && _hasConflict(row, col);

    Color background = Colors.white;
    if (isFixed) background = const Color(0xFFF8FAFC);
    if (inLine) background = AppUi.softBlue;
    if (isSelected) background = AppUi.iconTile;

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(
            right: col == 5 ? BorderSide.none : BorderSide(color: col == 2 ? AppUi.ink : const Color(0xFFE2E8F0), width: col == 2 ? 2 : 1),
            bottom: row == 5 ? BorderSide.none : BorderSide(color: row == 1 || row == 3 ? AppUi.ink : const Color(0xFFE2E8F0), width: row == 1 || row == 3 ? 2 : 1),
          ),
        ),
        child: Center(
          child: Text(
            value == 0 ? '' : '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: isFixed ? FontWeight.w700 : FontWeight.w600,
              color: conflict ? AppColors.error : (isFixed ? AppUi.ink : AppUi.accent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadButton(int number, {bool isErase = false}) {
    return GestureDetector(
      onTap: () => _onNumberTap(number),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isErase ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppUi.cardShadow,
        ),
        child: Center(
          child: isErase
              ? const Icon(Icons.backspace_outlined, color: AppColors.error)
              : Text('$number', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppUi.accent)),
        ),
      ),
    );
  }
}
