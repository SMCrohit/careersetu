import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  // A simple pre-defined Sudoku puzzle for the game
  final List<List<int>> _initialPuzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9]
  ];

  final List<List<int>> _solution = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9]
  ];

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
    _currentGrid = List.generate(9, (r) => List.generate(9, (c) => _initialPuzzle[r][c]));
    _isFixed = List.generate(9, (r) => List.generate(9, (c) => _initialPuzzle[r][c] != 0));
    _selectedRow = null;
    _selectedCol = null;
    _secondsElapsed = 0;
    _isFinished = false;
    _startTimer();
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
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
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

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text('You solved the puzzle in $_formattedTime.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initGame();
              });
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to hub
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // As requested: all background of Brain Game is white
      appBar: AppBar(
        title: const Text('Sudoku', style: TextStyle(color: AppColors.primaryBrand)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryBrand),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _initGame()),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: AppColors.secondaryText),
              const SizedBox(width: 8),
              Text(
                _formattedTime,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sudoku Grid
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryText, width: 2),
                    ),
                    child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemCount: 81,
                  itemBuilder: (context, index) {
                    final row = index ~/ 9;
                    final col = index % 9;
                    
                    final isSelected = row == _selectedRow && col == _selectedCol;
                    final isFixed = _isFixed[row][col];
                    final value = _currentGrid[row][col];
                    
                    final isRightBorder = col == 2 || col == 5;
                    final isBottomBorder = row == 2 || row == 5;

                    return GestureDetector(
                      onTap: () => _onCellTap(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primaryBrand.withValues(alpha: 0.2) 
                              : (isFixed ? Colors.grey.shade100 : Colors.white),
                          border: Border(
                            right: BorderSide(
                              color: isRightBorder ? AppColors.primaryText : Colors.grey.shade300,
                              width: isRightBorder ? 2 : 1,
                            ),
                            bottom: BorderSide(
                              color: isBottomBorder ? AppColors.primaryText : Colors.grey.shade300,
                              width: isBottomBorder ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            value == 0 ? '' : value.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
                              color: isFixed ? AppColors.primaryText : AppColors.primaryBrand,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      
      // Numpad Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) => _buildNumpadButton(index + 1)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...List.generate(4, (index) => _buildNumpadButton(index + 6)),
                    _buildNumpadButton(0, isErase: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(int number, {bool isErase = false}) {
    return GestureDetector(
      onTap: () => _onNumberTap(number),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: isErase 
              ? const Icon(Icons.backspace_outlined, color: Colors.red)
              : Text(number.toString(), style: const TextStyle(fontSize: 24, color: AppColors.primaryText)),
        ),
      ),
    );
  }
}