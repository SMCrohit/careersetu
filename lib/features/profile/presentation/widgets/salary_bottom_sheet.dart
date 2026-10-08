import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'premium_bottom_sheet.dart';

class SalaryBottomSheet extends ConsumerStatefulWidget {
  final String field;
  final String title;
  final int? initialValue;
  final Future<void> Function(String, dynamic) onSave;

  const SalaryBottomSheet({
    super.key,
    required this.field,
    required this.title,
    this.initialValue,
    required this.onSave,
  });

  @override
  ConsumerState<SalaryBottomSheet> createState() => _SalaryBottomSheetState();
}

class _SalaryBottomSheetState extends ConsumerState<SalaryBottomSheet> {
  late double _currentValue;
  bool _isLoading = false;
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _currentValue = (widget.initialValue ?? 100000).toDouble();
    if (_currentValue < 100000) _currentValue = 100000;
    if (_currentValue > 10000000) _currentValue = 10000000;
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      await widget.onSave(widget.field, _currentValue.toInt());
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
          Center(
            child: Text(
              _currencyFormat.format(_currentValue),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0ea5e9),
              ),
            ),
          ),
          Center(
            child: Text(
              'Per Year',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF0ea5e9),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF0ea5e9).withValues(alpha: 0.2),
              valueIndicatorColor: const Color(0xFF0ea5e9),
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: _currentValue,
              min: 100000,
              max: 10000000,
              divisions: 198, // (10000000 - 100000) / 50000 = 198
              label: _currencyFormat.format(_currentValue),
              onChanged: (value) {
                setState(() {
                  _currentValue = value;
                });
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹1 Lakh', style: TextStyle(color: Colors.black54, fontSize: 12)),
                Text('₹1 Crore', style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
