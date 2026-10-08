import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../jobs/data/jobs_repository.dart';
import 'premium_bottom_sheet.dart';

class EditProfileBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String fieldKey;
  final String currentValue;

  /// When set, the edited value(s) are handed to this callback instead of being saved to the profile.
  final Future<bool> Function(Map<String, dynamic> data)? onSave;

  /// Starting city/state/pincode for the 'city' field. Defaults to the signed-in user's values.
  final Map<String, String>? initialLocation;

  const EditProfileBottomSheet({
    super.key,
    required this.title,
    required this.fieldKey,
    required this.currentValue,
    this.onSave,
    this.initialLocation,
  });

  @override
  ConsumerState<EditProfileBottomSheet> createState() => EditProfileBottomSheetState();
}

class EditProfileBottomSheetState extends ConsumerState<EditProfileBottomSheet> {
  late TextEditingController _controller;
  late TextEditingController _otpController;
  
  // Location specific
  late TextEditingController _pincodeController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  List<String> _areas = [];
  bool _isLoadingLocation = false;
  String? _locationError;
  
  String? _selectedValue;
  bool _isLoading = false;
  bool _otpSent = false;
  String _verificationId = '';

  List<String> _goals = [];
  bool _isLoadingGoals = false;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatuses = ['Single', 'Married', 'Divorced', 'Widowed'];
  List<String> _acquisitionSources = [];
  bool _isLoadingSources = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    
    _pincodeController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();

    if (widget.fieldKey == 'city') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = ref.read(authProvider).currentUser;
        final location = widget.initialLocation ??
            (user != null ? {'city': user.city, 'state': user.state, 'pincode': user.pincode} : null);
        if (location != null) {
          final city = location['city'] ?? '';
          _pincodeController.text = location['pincode'] ?? '';
          _cityController.text = city;
          _stateController.text = location['state'] ?? '';
          // Split city if it contains area
          if (city.contains(', ')) {
            final parts = city.split(', ');
            _selectedValue = parts[0];
            _cityController.text = parts[1];
            _areas = [parts[0]];
            setState(() {});
          }
        }
      });
    }
    
    String initialText = widget.currentValue;
    if (widget.fieldKey == 'dob' && initialText.isNotEmpty) {
      try {
        // Try parsing YYYY-MM-DD
        final parsed = DateTime.parse(initialText);
        initialText = DateFormat('dd MMMM yyyy').format(parsed);
      } catch (e) {
        // Leave as is if already formatted or invalid
      }
    }
    _controller = TextEditingController(text: initialText);
    
    if (widget.fieldKey == 'goal') {
      _selectedValue = widget.currentValue.isNotEmpty ? widget.currentValue : null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchGoals());
    } else if (widget.fieldKey == 'gender') {
      _selectedValue = widget.currentValue.isNotEmpty ? widget.currentValue : 'Male';
    } else if (widget.fieldKey == 'marital_status') {
      _selectedValue = widget.currentValue.isNotEmpty ? widget.currentValue : 'Single';
    } else if (widget.fieldKey == 'acquisition_source') {
      _selectedValue = widget.currentValue.isNotEmpty ? widget.currentValue : null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAcquisitionSources());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _otpController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _fetchPincodeDetails(String pincode) async {
    if (pincode.length != 6) return;
    
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
      _areas = [];
      _selectedValue = null;
      _cityController.clear();
      _stateController.clear();
    });

    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List;
          if (postOffices.isNotEmpty) {
            _cityController.text = postOffices[0]['District'] ?? '';
            _stateController.text = postOffices[0]['State'] ?? '';
            _areas = postOffices.map((po) => po['Name'].toString()).toList();
            _selectedValue = _areas.first;
          }
        } else {
          _locationError = 'Invalid Pincode';
        }
      } else {
        _locationError = 'Failed to fetch details';
      }
    } catch (e) {
      _locationError = 'Network error';
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _fetchGoals() async {
    setState(() => _isLoadingGoals = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/goals');
      final List<dynamic> data = response.data;
      if (mounted) {
        setState(() {
          _goals = data.map((g) => g['name'].toString()).toList();
          if (_selectedValue != null && !_goals.contains(_selectedValue)) {
            _selectedValue = _goals.isNotEmpty ? _goals.first : null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _goals = ['engineer', 'teacher', 'doctor', 'other'];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoals = false);
    }
  }

  Future<void> _fetchAcquisitionSources() async {
    setState(() => _isLoadingSources = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/acquisition-sources');
      final List<dynamic> data = response.data;
      if (mounted) {
        setState(() {
          _acquisitionSources = data.map((g) => g['name'].toString()).toList();
          if (_selectedValue != null && !_acquisitionSources.contains(_selectedValue)) {
            _selectedValue = _acquisitionSources.isNotEmpty ? _acquisitionSources.first : null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _acquisitionSources = ['Social Media', 'Friend', 'Advertisement', 'Search Engine', 'Other'];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingSources = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    try {
      if (_controller.text.isNotEmpty) {
        initialDate = DateFormat('dd MMMM yyyy').parse(_controller.text);
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _controller.text = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  void _save() async {
    if (widget.fieldKey == 'mobile_number') {
      Navigator.pop(context);
      return;
    }

    final text = _controller.text.trim();
    if (widget.fieldKey == 'whatsapp_number') {
      if (text.length != 10 || int.tryParse(text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit number', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
        return;
      }
    } else if (text.isNotEmpty && widget.fieldKey == 'linkedin_url') {
      if (!RegExp(r'^(https?:\/\/)?(www\.)?linkedin\.com\/.*$', caseSensitive: false).hasMatch(text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid LinkedIn URL', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
        return;
      }
    } else if (text.isNotEmpty && widget.fieldKey == 'github_url') {
      if (!RegExp(r'^(https?:\/\/)?(www\.)?github\.com\/.*$', caseSensitive: false).hasMatch(text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid GitHub URL', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
        return;
      }
    } else if (text.isNotEmpty && widget.fieldKey == 'portfolio_url') {
      if (!RegExp(r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$', caseSensitive: false).hasMatch(text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid URL (e.g., https://yourwebsite.com)', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
        return;
      }
    }

    setState(() => _isLoading = true);
    
    dynamic value;
    if (['goal', 'gender', 'marital_status', 'acquisition_source'].contains(widget.fieldKey)) {
      value = _selectedValue;
    } else if (['years_of_experience'].contains(widget.fieldKey)) {
      value = double.tryParse(_controller.text.trim()) ?? 0.0;
    } else if (['expected_salary', 'current_salary', 'notice_period_days'].contains(widget.fieldKey)) {
      value = int.tryParse(_controller.text.trim()) ?? 0;
    } else if (widget.fieldKey == 'city') {
      value = _selectedValue != null && _selectedValue!.isNotEmpty ? '$_selectedValue, ${_cityController.text.trim()}' : _cityController.text.trim();
    } else {
      value = _controller.text.trim();
    }
    
    if (widget.fieldKey == 'dob' && value.toString().isNotEmpty) {
      try {
        final parsed = DateFormat('dd MMMM yyyy').parse(value);
        value = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (e) {
        // Leave as is
      }
    }
    
    if (widget.fieldKey == 'mobile_number') {
      if (!_otpSent) {
        final exists = await ref.read(authRepositoryProvider).requestOtp(value as String);
        if (exists) {
          setState(() => _isLoading = false);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number already in use by another account.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
          return;
        }

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: '+91$value',
          verificationCompleted: (PhoneAuthCredential credential) async {},
          verificationFailed: (FirebaseAuthException e) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to new number.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.primaryBrand));
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
        return;
      } else {
        try {
          final credential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: _otpController.text.trim());
          await FirebaseAuth.instance.currentUser!.updatePhoneNumber(credential);
          await FirebaseAuth.instance.currentUser!.getIdToken(true);
          
          final success = await ref.read(authProvider.notifier).updateProfileDetails({widget.fieldKey: value});
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pop(context);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number updated successfully', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update in database', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
            }
          }
        } on FirebaseAuthException catch (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Invalid OTP', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
        } catch (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
        }
        return;
      }
    }

    Map<String, dynamic> updateData = {widget.fieldKey: value};
    if (widget.fieldKey == 'city') {
      updateData['state'] = _stateController.text.trim();
      updateData['pincode'] = _pincodeController.text.trim();
    }
    final success = widget.onSave != null
        ? await widget.onSave!(updateData)
        : await ref.read(authProvider.notifier).updateProfileDetails(updateData);
    
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      if (success && widget.onSave == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.title} updated successfully', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
      } else if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update in database', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetLayout(
      title: widget.fieldKey == 'mobile_number' ? widget.title : 'Edit ${widget.title}',
      buttonText: widget.fieldKey == 'mobile_number' ? 'Close' : 'Save Changes',
      onButtonPressed: _save,
      isButtonEnabled: !_isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            if (['goal', 'gender', 'marital_status', 'acquisition_source'].contains(widget.fieldKey))
              (widget.fieldKey == 'goal' && _isLoadingGoals) || (widget.fieldKey == 'acquisition_source' && _isLoadingSources)
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9))))
                : Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: (widget.fieldKey == 'goal' ? _goals : widget.fieldKey == 'gender' ? _genders : widget.fieldKey == 'marital_status' ? _maritalStatuses : _acquisitionSources).map((g) {
                      final isSelected = _selectedValue == g;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedValue = g),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? const Color(0xFF0ea5e9) : AppColors.borderDark),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? const Color(0xFF0ea5e9) : AppColors.secondaryText,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    g.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xFF0ea5e9) : AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            else if (widget.fieldKey == 'city')
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Enter a 6-digit pin code to auto-fetch the city and state.', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (val) {
                      if (val.length == 6) _fetchPincodeDetails(val);
                    },
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Pincode',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0ea5e9))),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: "",
                    ),
                  ),
                  if (_isLoadingLocation) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: Color(0xFF0ea5e9))),
                  if (_locationError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_locationError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                  const SizedBox(height: 16),
                  if (_areas.isNotEmpty) ...[
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _areas.map((a) {
                            final isSelected = _selectedValue == a;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () => setState(() => _selectedValue = a),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? const Color(0xFF0ea5e9) : AppColors.borderDark),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                        color: isSelected ? const Color(0xFF0ea5e9) : AppColors.secondaryText,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          a,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? const Color(0xFF0ea5e9) : AppColors.primaryText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          readOnly: true,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          readOnly: true,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (widget.fieldKey == 'dob')
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: widget.title,
                      hintText: 'dd MMMM yyyy',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0ea5e9))),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF0ea5e9)),
                    ),
                  ),
                ),
              )
            else
              TextFormField(
                controller: _controller,
                readOnly: widget.fieldKey == 'mobile_number',
                keyboardType: ['mobile_number', 'whatsapp_number', 'expected_salary', 'current_salary', 'notice_period_days'].contains(widget.fieldKey) ? TextInputType.number : (widget.fieldKey == 'years_of_experience' ? TextInputType.numberWithOptions(decimal: true) : (['summary', 'address'].contains(widget.fieldKey) ? TextInputType.multiline : TextInputType.text)),
                maxLines: ['summary', 'address'].contains(widget.fieldKey) ? 4 : 1,
                maxLength: ['mobile_number', 'whatsapp_number'].contains(widget.fieldKey) ? 10 : null,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: widget.title,
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0ea5e9))),
                  filled: true,
                  fillColor: widget.fieldKey == 'mobile_number' ? Colors.grey.shade100 : Colors.white,
                  counterText: "",
                  prefixText: ['mobile_number', 'whatsapp_number'].contains(widget.fieldKey) ? '+91 ' : null,
                  prefixStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 16),
                ),
              ),
            if (_otpSent && widget.fieldKey == 'mobile_number') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'OTP',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0ea5e9))),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: "",
                ),
              ),
            ],
        ]
      )
    );
  }
}
