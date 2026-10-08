import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../jobs/data/jobs_repository.dart'; // for apiClientProvider
import 'premium_bottom_sheet.dart';

class ChipManagerBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String fieldKey;
  final List<dynamic> currentList;

  /// When set, the edited list is handed to this callback instead of being saved to the profile.
  final Future<bool> Function(String field, List<dynamic> value)? onSave;

  const ChipManagerBottomSheet({
    Key? key,
    required this.title,
    required this.fieldKey,
    required this.currentList,
    this.onSave,
  }) : super(key: key);

  @override
  ConsumerState<ChipManagerBottomSheet> createState() => _ChipManagerBottomSheetState();
}

class _ChipManagerBottomSheetState extends ConsumerState<ChipManagerBottomSheet> {
  late List<String> _items;
  final TextEditingController _controller = TextEditingController();
  TextEditingController? _internalController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _items = widget.currentList.map((e) => e.toString()).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem({String? value}) {
    final text = (value ?? _controller.text).trim();
    if (text.isNotEmpty && !_items.contains(text)) {
      setState(() {
        _items.add(text);
      });
    }
  }

  void _removeItem(String item) {
    setState(() {
      _items.remove(item);
    });
  }

  void _save() async {
    setState(() => _isLoading = true);
    
    final success = widget.onSave != null
        ? await widget.onSave!(widget.fieldKey, _items)
        : await ref.read(authProvider.notifier).updateProfileDetails({
            widget.fieldKey: _items,
          });
    
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      if (success && widget.onSave == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.title} updated successfully', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.success,
        ));
      } else if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update in database', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }


  Future<List<String>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    if (widget.fieldKey == 'skills') {
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.get('/skills?q=$query');
        final List<dynamic> data = response.data;
        return data.map((e) => e['name'].toString()).toList();
      } catch (e) {
        return []; // fail silently
      }
    } else if (widget.fieldKey == 'languages') {
      final List<String> allLangs = [
        'Hindi', 'English', 'Marathi', 'Gujarati', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Bengali', 'Punjabi', 'Odia', 'Urdu', 'Assamese', 'Sanskrit'
      ];
      return allLangs.where((lang) => lang.toLowerCase().contains(query.toLowerCase())).toList();
    }
    
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetLayout(
      title: 'Manage ${widget.title}',
      buttonText: 'Save',
      onButtonPressed: _save,
      isButtonEnabled: !_isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              return await _getSuggestions(textEditingValue.text);
            },
            onSelected: (String selection) {
              _addItem(value: selection);
              _internalController?.clear();
              _controller.clear();
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              _internalController = textEditingController;
              // Sync the local controller so _addItem can read it
              textEditingController.addListener(() {
                if (_controller.text != textEditingController.text) {
                  _controller.text = textEditingController.text;
                }
              });
              
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                onFieldSubmitted: (String value) {
                  _addItem(value: value);
                  textEditingController.clear();
                  _controller.clear();
                  onFieldSubmitted(); // Notify Autocomplete
                },
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Add ${widget.title}',
                  hintText: 'Type and press enter',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0ea5e9))),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF0ea5e9)),
                    onPressed: () {
                      _addItem(value: textEditingController.text);
                      textEditingController.clear();
                      _controller.clear();
                    }
                  ),
                ),
              );
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 48, // Padding compensation
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            // Important: Actually clear the internal controller!
                            // Because Autocomplete manages it, we need to clear via _controller sync if possible
                            // The easiest way is to let the user clear, or we clear it when selected if we have the reference.
                            // But here we rely on the parent logic.
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(option, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _items.map((item) {
              return Chip(
                label: Text(item, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                backgroundColor: Colors.white,
                deleteIconColor: const Color(0xFF0ea5e9),
                onDeleted: () => _removeItem(item),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
          const SizedBox(height: 180), // Extra space to ensure dropdown has room to render without going off-screen
        ],
      ),
    );
  }

}
