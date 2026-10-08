import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'premium_bottom_sheet.dart';

class NoticePeriodBottomSheet extends ConsumerStatefulWidget {
  final String field;
  final String title;
  final int? initialValue;
  final Future<void> Function(String, dynamic) onSave;

  const NoticePeriodBottomSheet({
    super.key,
    required this.field,
    required this.title,
    this.initialValue,
    required this.onSave,
  });

  @override
  ConsumerState<NoticePeriodBottomSheet> createState() => _NoticePeriodBottomSheetState();
}

class _NoticePeriodBottomSheetState extends ConsumerState<NoticePeriodBottomSheet> {
  final _numberController = TextEditingController();
  bool _isLoading = false;
  String _selectedUnit = 'Days';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue! > 0) {
      if (widget.initialValue! % 30 == 0 && widget.initialValue! >= 30) {
        _selectedUnit = 'Months';
        _numberController.text = (widget.initialValue! ~/ 30).toString();
      } else {
        _selectedUnit = 'Days';
        _numberController.text = widget.initialValue!.toString();
      }
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _numberController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a number')),
      );
      return;
    }

    final number = int.tryParse(text);
    if (number == null || number <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final days = _selectedUnit == 'Months' ? number * 30 : number;
      await widget.onSave(widget.field, days);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save ${widget.title.toLowerCase()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetLayout(
      title: widget.title,
      buttonText: _isLoading ? 'Saving...' : 'Save Changes',
      isButtonEnabled: !_isLoading,
      onButtonPressed: _handleSave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black87, fontSize: 18),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 30',
                      hintStyle: TextStyle(color: Colors.black38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    _buildUnitChip('Days'),
                    const SizedBox(width: 8),
                    _buildUnitChip('Months'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUnitChip(String unit) {
    final isSelected = _selectedUnit == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUnit = unit;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0ea5e9).withValues(alpha: 0.2) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF0ea5e9) : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            unit,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0ea5e9) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
