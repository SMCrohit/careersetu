import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'premium_bottom_sheet.dart';

class ComplexListManagerBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String fieldKey;
  final List<dynamic> currentList;

  /// When set, the edited list is handed to this callback instead of being saved to the profile.
  final Future<bool> Function(String field, List<dynamic> value)? onSave;

  const ComplexListManagerBottomSheet({
    Key? key,
    required this.title,
    required this.fieldKey,
    required this.currentList,
    this.onSave,
  }) : super(key: key);

  @override
  ConsumerState<ComplexListManagerBottomSheet> createState() => _ComplexListManagerBottomSheetState();
}

class _ComplexListManagerBottomSheetState extends ConsumerState<ComplexListManagerBottomSheet> {
  late List<Map<String, dynamic>> _items;
  bool _isLoading = false;
  bool _isAddingNew = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _upToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.currentList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _yearController.dispose();
    _fromController.dispose();
    _upToController.dispose();
    super.dispose();
  }

  void _addNew() {
    setState(() {
      _isAddingNew = true;
    });
  }

  void _cancelAdd() {
    setState(() {
      _isAddingNew = false;
    });
    _titleController.clear();
    _subtitleController.clear();
    _yearController.clear();
    _fromController.clear();
    _upToController.clear();
  }

  void _saveNew() {
    if (_titleController.text.trim().isEmpty) return;

    final isRange = ['work_experience', 'education_history', 'projects'].contains(widget.fieldKey);
    final yearValue = isRange 
        ? '${_fromController.text.trim()} - ${_upToController.text.trim()}' 
        : _yearController.text.trim();

    Map<String, dynamic> newItem = {};
    if (widget.fieldKey == 'work_experience') {
      newItem = {
        'title': _titleController.text.trim(),
        'company': _subtitleController.text.trim(),
        'duration': yearValue,
      };
    } else if (widget.fieldKey == 'education_history') {
      newItem = {
        'degree': _titleController.text.trim(),
        'institution': _subtitleController.text.trim(),
        'year': yearValue,
      };
    } else if (widget.fieldKey == 'projects') {
      newItem = {
        'title': _titleController.text.trim(),
        'role': _subtitleController.text.trim(),
        'duration': yearValue,
      };
    } else if (widget.fieldKey == 'certifications') {
      newItem = {
        'title': _titleController.text.trim(),
        'organization': _subtitleController.text.trim(),
        'year': yearValue,
      };
    } else if (widget.fieldKey == 'achievements') {
      newItem = {
        'title': _titleController.text.trim(),
        'event': _subtitleController.text.trim(),
        'year': yearValue,
      };
    } else {
      newItem = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'year': yearValue,
      };
    }

    setState(() {
      _items.add(newItem);
      _isAddingNew = false;
    });
    
    _titleController.clear();
    _subtitleController.clear();
    _yearController.clear();
    _fromController.clear();
    _upToController.clear();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _saveAll() async {
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

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetLayout(
      title: 'Manage ${widget.title}',
      buttonText: _isAddingNew ? 'Add Item' : 'Save Changes',
      onButtonPressed: _isAddingNew ? _saveNew : _saveAll,
      isButtonEnabled: !_isLoading,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isAddingNew ? _buildAddForm() : _buildListView(),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      key: const ValueKey('ListView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No items added yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          )
        else
          ..._items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            String displayTitle = '';
            String displaySubtitle = '';
            String displayYear = '';

            if (widget.fieldKey == 'work_experience') {
              displayTitle = item['title'] ?? '';
              displaySubtitle = item['company'] ?? '';
              displayYear = item['duration'] ?? '';
            } else if (widget.fieldKey == 'education_history') {
              displayTitle = item['degree'] ?? '';
              displaySubtitle = item['institution'] ?? '';
              displayYear = item['year'] ?? '';
            } else if (widget.fieldKey == 'projects') {
              displayTitle = item['title'] ?? '';
              displaySubtitle = item['role'] ?? '';
              displayYear = item['duration'] ?? '';
            } else if (widget.fieldKey == 'certifications') {
              displayTitle = item['title'] ?? '';
              displaySubtitle = item['organization'] ?? '';
              displayYear = item['year'] ?? '';
            } else if (widget.fieldKey == 'achievements') {
              displayTitle = item['title'] ?? '';
              displaySubtitle = item['event'] ?? '';
              displayYear = item['year'] ?? '';
            } else {
              displayTitle = item['title'] ?? '';
              displaySubtitle = item['subtitle'] ?? '';
              displayYear = item['year'] ?? '';
            }

            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                subtitle: Text('$displaySubtitle • $displayYear', style: TextStyle(color: Colors.grey.shade600)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeItem(idx),
                ),
              ),
            );
          }),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _addNew,
          icon: const Icon(Icons.add, color: Color(0xFF0ea5e9)),
          label: Text('Add New ${widget.title}', style: const TextStyle(color: Color(0xFF0ea5e9), fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Map<String, dynamic> _getFieldConfig() {
    switch (widget.fieldKey) {
      case 'work_experience':
        return {
          'title': 'Job Title (e.g. Software Engineer)',
          'subtitle': 'Company Name (e.g. Google)',
          'isRange': true,
          'from': 'From (e.g. 2020)',
          'upto': 'Up To (e.g. Present)',
        };
      case 'education_history':
        return {
          'title': 'Degree (e.g. B.Tech in CS)',
          'subtitle': 'University / Institute (e.g. Stanford)',
          'isRange': true,
          'from': 'From (e.g. 2020)',
          'upto': 'Up To (e.g. 2024)',
        };
      case 'projects':
        return {
          'title': 'Project Name (e.g. E-Commerce App)',
          'subtitle': 'Role / Tech Stack (e.g. Lead Dev / Flutter)',
          'isRange': true,
          'from': 'From (e.g. Jan 2023)',
          'upto': 'Up To (e.g. Dec 2023)',
        };
      case 'certifications':
        return {
          'title': 'Certification Name (e.g. AWS Cloud Practitioner)',
          'subtitle': 'Issuing Organization (e.g. Amazon)',
          'isRange': false,
          'year': 'Issue Year (e.g. 2023)',
        };
      case 'achievements':
      default:
        return {
          'title': 'Achievement (e.g. 1st Place Hackathon)',
          'subtitle': 'Event / Organization (e.g. Google I/O)',
          'isRange': false,
          'year': 'Year (e.g. 2023)',
        };
    }
  }

  Widget _buildAddForm() {
    final config = _getFieldConfig();
    
    return Column(
      key: const ValueKey('AddForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
              onPressed: _cancelAdd,
            ),
            Text('Add New', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(_titleController, config['title'] as String),
        const SizedBox(height: 12),
        _buildTextField(_subtitleController, config['subtitle'] as String),
        const SizedBox(height: 12),
        if (config['isRange'] as bool)
          Row(
            children: [
              Expanded(child: _buildTextField(_fromController, config['from'] as String, isNumber: false)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_upToController, config['upto'] as String, isNumber: false)),
            ],
          )
        else
          _buildTextField(_yearController, config['year'] as String, isNumber: false),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0ea5e9))),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
