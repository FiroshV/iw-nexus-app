import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/user_avatar.dart';
import '../widgets/document_category_bottom_sheet.dart';
import '../widgets/common/indian_phone_input.dart';
import '../constants/document_categories.dart';

class ProfileScreen extends StatefulWidget {
  final bool showCompletionDialog;
  final int initialTab;

  const ProfileScreen({
    super.key,
    this.showCompletionDialog = false,
    this.initialTab = 0,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isLoadingDocuments = false;
  bool _isUploadingDocument = false;

  // Tab controller
  late TabController _tabController;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _designationController = TextEditingController();
  final _addressController = TextEditingController();
  final _homePhoneController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNameController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedBloodGroup;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _documents = [];
  Set<String> _uploadedCategories = {};
  Map<String, Map<String, dynamic>> _documentsByCategory = {};
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _loadUserProfile();
    _loadDocuments();

    // Show completion dialog if requested
    if (widget.showCompletionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfileCompletionDialog();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _designationController.dispose();
    _addressController.dispose();
    _homePhoneController.dispose();
    _phoneController.dispose();
    _documentNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getUserProfile();
      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data;
          _populateFields();
        });
      } else {
        _showErrorSnackBar('Failed to load profile data');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading profile: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _populateFields() {
    if (_currentUser != null) {
      _firstNameController.text = _currentUser!['firstName'] ?? '';
      _lastNameController.text = _currentUser!['lastName'] ?? '';
      _emailController.text = _currentUser!['email'] ?? '';
      _designationController.text = _currentUser!['designation'] ?? '';
      _addressController.text = _currentUser!['address'] ?? '';
      // Strip +91 prefix for display in IndianPhoneInput
      _homePhoneController.text = IndianPhoneInput.parseFromApi(_currentUser!['homePhoneNumber']);
      _phoneController.text = IndianPhoneInput.parseFromApi(_currentUser!['phoneNumber']);
      _selectedBloodGroup = _currentUser!['bloodGroup'];

      if (_currentUser!['dateOfBirth'] != null) {
        _selectedDateOfBirth = DateTime.parse(_currentUser!['dateOfBirth']);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'address': _addressController.text.trim(),
        // Format phone numbers with +91 prefix for API
        'homePhoneNumber': _homePhoneController.text.trim().isEmpty
            ? ''
            : IndianPhoneInput.formatForApi(_homePhoneController.text.trim()),
        'phoneNumber': _phoneController.text.trim().isEmpty
            ? ''
            : IndianPhoneInput.formatForApi(_phoneController.text.trim()),
      };

      if (_selectedDateOfBirth != null) {
        final dob = _selectedDateOfBirth!;
        // Store date at midnight IST (Asia/Kolkata timezone)
        final istDob = DateTime(dob.year, dob.month, dob.day, 0, 0, 0);
        updateData['dateOfBirth'] = istDob.toIso8601String();
      }

      if (_selectedBloodGroup != null) {
        updateData['bloodGroup'] = _selectedBloodGroup!;
      }

      final response = await ApiService.updateUserProfile(profileData: updateData);
      
      if (response.success) {
        setState(() {
          _currentUser = response.data;
        });
        _showSuccessSnackBar('Profile updated successfully!');
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Color(0xFF272579))),
        backgroundColor: const Color(0xFF5cfbd8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showProfileCompletionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF272579).withValues(alpha: 0.1),
              
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card,
              size: 30,
              color: Color(0xFF272579),
            ),
          ),
          title: const Text(
            'Complete Your Profile',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Please complete your profile information to generate your ID card and access all features.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF272579),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF272579),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          color: readOnly ? Colors.grey[600] : const Color(0xFF272579),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: readOnly ? Colors.grey[400] : const Color(0xFF0071bf),
          ),
          labelStyle: TextStyle(
            color: readOnly ? Colors.grey[400] : const Color(0xFF272579),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF0071bf),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey[50] : Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _selectDateOfBirth,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Icon(
              Icons.calendar_today,
              color: const Color(0xFF0071bf),
            ),
            labelStyle: TextStyle(
              color: const Color(0xFF272579),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          child: Text(
            _selectedDateOfBirth != null
                ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                : 'Select Date of Birth',
            style: TextStyle(
              color: const Color(0xFF272579),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBloodGroup,
        onChanged: (String? newValue) {
          setState(() {
            _selectedBloodGroup = newValue;
          });
        },
        decoration: InputDecoration(
          labelText: 'Blood Group',
          prefixIcon: Icon(
            Icons.bloodtype,
            color: const Color(0xFF0071bf),
          ),
          labelStyle: TextStyle(
            color: const Color(0xFF272579),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF0071bf),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        items: _bloodGroups.map((String bloodGroup) {
          return DropdownMenuItem<String>(
            value: bloodGroup,
            child: Text(bloodGroup),
          );
        }).toList(),
        hint: const Text('Select Blood Group'),
        style: TextStyle(
          color: const Color(0xFF272579),
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _showImagePickerDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_currentUser?['avatar'] != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfilePhoto();
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _uploadProfilePhoto(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfilePhoto(File imageFile) async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final response = await ApiService.uploadProfilePhoto(imageFile);
      
      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data!['user'];
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _deleteProfilePhoto() async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final response = await ApiService.deleteProfilePhoto();
      
      if (response.success) {
        setState(() {
          _currentUser = response.data;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  // Document management methods
  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
    });

    try {
      final response = await ApiService.getUserDocuments();
      if (response.success && response.data != null) {
        // The backend returns: { data: [documents], count: number }
        final documentsData = response.data is List
            ? response.data
            : response.data['data'] ?? [];
        final docsList = List<Map<String, dynamic>>.from(documentsData);

        // Build uploaded categories set and documents by category map
        final uploadedCats = <String>{};
        final docsByCat = <String, Map<String, dynamic>>{};
        for (final doc in docsList) {
          final category = doc['documentCategory'] as String?;
          if (category != null) {
            uploadedCats.add(category);
            // Store the first document for each category (for viewing)
            if (!docsByCat.containsKey(category)) {
              docsByCat[category] = doc;
            }
          }
        }

        setState(() {
          _documents = docsList;
          _uploadedCategories = uploadedCats;
          _documentsByCategory = docsByCat;
        });

        // Clear the ProfileService cache so it picks up new documents
        ProfileService.clearDocumentCache();
      } else {
        _showErrorSnackBar('Failed to load documents');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading documents: $e');
    }

    setState(() {
      _isLoadingDocuments = false;
    });
  }

  Future<String?> _showDocumentNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Document Name',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF272579),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter document name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF272579), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF272579),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadDocument({String? preselectedCategory}) async {
    // Show category selection bottom sheet if no category pre-selected
    String? category = preselectedCategory;
    if (category == null) {
      category = await DocumentCategoryBottomSheet.show(
        context: context,
        uploadedCategories: _uploadedCategories,
      );
    }

    if (category == null) return; // User cancelled

    // For "other" category, prompt for custom document name
    String? customDocumentName;
    if (category == DocumentCategories.other) {
      customDocumentName = await _showDocumentNameDialog();
      if (customDocumentName == null) return; // User cancelled
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        await _uploadDocument(file, fileName, category, customName: customDocumentName);
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting document: $e');
    }
  }

  Future<void> _uploadDocument(File file, String originalFileName, String category, {String? customName}) async {
    setState(() {
      _isUploadingDocument = true;
    });

    try {
      final documentName = customName ??
          (_documentNameController.text.trim().isEmpty
              ? DocumentCategories.getLabel(category)
              : _documentNameController.text.trim());

      final response = await ApiService.uploadDocument(
        file,
        documentCategory: category,
        documentName: documentName,
      );

      if (response.success) {
        _documentNameController.clear();
        await _loadDocuments(); // Refresh documents list
        _showSuccessSnackBar('Document uploaded successfully!');
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading document: $e');
    }

    setState(() {
      _isUploadingDocument = false;
    });
  }

  Future<void> _deleteDocument(String documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteDocument(documentId);
        if (response.success) {
          await _loadDocuments(); // Refresh documents list
          _showSuccessSnackBar('Document deleted successfully!');
        } else {
          _showErrorSnackBar(response.message);
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting document: $e');
      }
    }
  }

  String _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      case 'txt':
        return '📄';
      default:
        return '📁';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case DocumentCategories.educationalCertificate:
        return Icons.school_outlined;
      case DocumentCategories.experienceCertificate:
        return Icons.work_outline;
      case DocumentCategories.salarySlips:
        return Icons.receipt_long_outlined;
      case DocumentCategories.identityProof:
        return Icons.badge_outlined;
      case DocumentCategories.addressProof:
        return Icons.home_outlined;
      case DocumentCategories.bankStatement:
        return Icons.account_balance_outlined;
      case DocumentCategories.panCard:
        return Icons.credit_card_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Widget _buildDocumentChecklistItem({
    required String category,
    required bool isUploaded,
    Map<String, dynamic>? document,
  }) {
    final label = DocumentCategories.getLabel(category);
    final description = DocumentCategories.getDescription(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isUploaded ? null : () => _pickAndUploadDocument(preselectedCategory: category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUploaded
                ? const Color(0xFF10B981).withValues(alpha: 0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUploaded
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isUploaded
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFF272579).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUploaded ? Icons.check_circle : _getCategoryIcon(category),
                  color: isUploaded
                      ? const Color(0xFF10B981)
                      : const Color(0xFF272579),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Category info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isUploaded
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUploaded
                          ? (document?['originalFileName'] as String? ?? 'Uploaded')
                          : description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Action button
              if (isUploaded && document != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View/Download button
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      color: const Color(0xFF272579),
                      onPressed: () async {
                        final documentId = document['_id'] as String?;
                        if (documentId != null && documentId.isNotEmpty) {
                          final messenger = ScaffoldMessenger.of(context);

                          // Fetch signed URL from backend
                          final response = await ApiService.getDocumentSignedUrl(documentId);

                          if (response.success && response.data != null) {
                            final uri = Uri.parse(response.data!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open document'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(response.message.isNotEmpty ? response.message : 'Failed to get document URL'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      tooltip: 'View Document',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red[400],
                      onPressed: () => _deleteDocument(document['_id']),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF272579),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Upload',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentListItem(Map<String, dynamic> document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF272579).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _getFileIcon(document['originalFileName'] ?? ''),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['documentName'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  document['originalFileName'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red[400],
            onPressed: () => _deleteDocument(document['_id']),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!_isLoading && _tabController.index == 0)
            TextButton(
              onPressed: _updateProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF5cfbd8),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.person),
              text: 'Personal Info',
            ),
            Tab(
              icon: Icon(Icons.folder),
              text: 'Documents',
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading profile...')
          : TabBarView(
              controller: _tabController,
              children: [
                // Personal Info Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF272579), Color(0xFF0071bf)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          UserAvatarWithUpload(
                            avatarUrl: _currentUser?['avatar'],
                            firstName: _currentUser?['firstName'],
                            lastName: _currentUser?['lastName'],
                            radius: 40,
                            isLoading: _isUploadingPhoto,
                            onTap: _showImagePickerDialog,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_currentUser?['firstName'] ?? ''} ${_currentUser?['lastName'] ?? ''}'.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser?['designation'] ?? 'Employee',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Personal Information Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF272579),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF272579),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Form Fields
                          _buildTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            icon: Icons.person_outline,
                            readOnly: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),

                          _buildTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            icon: Icons.person_outline,
                            readOnly: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),

                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            readOnly: true,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          _buildTextField(
                            controller: _designationController,
                            label: 'Designation',
                            icon: Icons.work_outline,
                            readOnly: true,
                          ),

                          _buildDateField(),

                          _buildDropdownField(),

                          _buildTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                          ),

                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: IndianPhoneInput(
                              controller: _homePhoneController,
                              labelText: 'Home Phone',
                              isRequired: false,
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: IndianPhoneInput(
                              controller: _phoneController,
                              labelText: 'Mobile Phone',
                              isRequired: false,
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Documents Tab
                _isLoadingDocuments
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF272579)),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mandatory Documents Checklist
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF272579).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.checklist,
                                          color: Color(0xFF272579),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Required Documents',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF272579),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_uploadedCategories.where((c) => DocumentCategories.mandatoryCategories.contains(c)).length}/${DocumentCategories.mandatoryCategories.length} completed',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _uploadedCategories.where((c) => DocumentCategories.mandatoryCategories.contains(c)).length /
                                          DocumentCategories.mandatoryCategories.length,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _uploadedCategories.where((c) => DocumentCategories.mandatoryCategories.contains(c)).length ==
                                                DocumentCategories.mandatoryCategories.length
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF272579),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Category checklist
                                  ...DocumentCategories.mandatoryCategories.map((category) {
                                    final isUploaded = _uploadedCategories.contains(category);
                                    final doc = _documentsByCategory[category];
                                    return _buildDocumentChecklistItem(
                                      category: category,
                                      isUploaded: isUploaded,
                                      document: doc,
                                    );
                                  }),
                                ],
                              ),
                            ),

                            // Upload Additional Documents Button
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: OutlinedButton.icon(
                                onPressed: _isUploadingDocument
                                    ? null
                                    : () => _pickAndUploadDocument(
                                          preselectedCategory: DocumentCategories.other,
                                        ),
                                icon: _isUploadingDocument
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add),
                                label: Text(
                                  _isUploadingDocument ? 'Uploading...' : 'Upload Other Documents',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF272579),
                                  side: const BorderSide(color: Color(0xFF272579)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            // Other Documents Section
                            if (_documents.where((d) => d['documentCategory'] == DocumentCategories.other).isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.folder_outlined,
                                          color: Color(0xFF272579),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Other Documents',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF272579),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ..._documents
                                        .where((d) => d['documentCategory'] == DocumentCategories.other)
                                        .map((document) => _buildDocumentListItem(document)),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ],
            ),
    );
  }
}