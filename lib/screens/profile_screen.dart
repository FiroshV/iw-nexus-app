import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  final bool showCompletionDialog;
  
  const ProfileScreen({
    super.key,
    this.showCompletionDialog = false,
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
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      _homePhoneController.text = _currentUser!['homePhoneNumber'] ?? '';
      _phoneController.text = _currentUser!['phoneNumber'] ?? '';
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
        'homePhoneNumber': _homePhoneController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      };

      if (_selectedDateOfBirth != null) {
        updateData['dateOfBirth'] = _selectedDateOfBirth!.toIso8601String();
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
        setState(() {
          _documents = List<Map<String, dynamic>>.from(documentsData);
        });
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

  Future<void> _pickAndUploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        await _uploadDocument(file, fileName);
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting document: $e');
    }
  }

  Future<void> _uploadDocument(File file, String originalFileName) async {
    setState(() {
      _isUploadingDocument = true;
    });

    try {
      final documentName = _documentNameController.text.trim().isEmpty
          ? null
          : _documentNameController.text.trim();

      final response = await ApiService.uploadDocument(file, documentName: documentName);

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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

                          _buildTextField(
                            controller: _homePhoneController,
                            label: 'Home',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),

                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
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
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upload Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(bottom: 24),
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
                                  Icons.cloud_upload,
                                  color: Color(0xFF272579),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Upload Document',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF272579),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Document Name Input
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: _documentNameController,
                                decoration: InputDecoration(
                                  labelText: 'Document Name (Optional)',
                                  hintText: 'Leave empty for auto-generated name',
                                  prefixIcon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF0071bf),
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF272579),
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
                              ),
                            ),

                            // Upload Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isUploadingDocument ? null : _pickAndUploadDocument,
                                icon: _isUploadingDocument
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.add),
                                label: Text(_isUploadingDocument ? 'Uploading...' : 'Select Document'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF272579),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Text(
                              'Supported formats: PDF, DOC, DOCX, JPG, PNG, TXT (Max 10MB)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Documents List Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
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
                                  Icons.folder,
                                  color: Color(0xFF272579),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'My Documents',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF272579),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_documents.length} documents',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (_isLoadingDocuments)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF272579),
                                ),
                              )
                            else if (_documents.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    style: BorderStyle.solid,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No documents uploaded yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload your first document using the button above',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...(_documents.map((document) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF272579).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getFileIcon(document['originalFileName'] ?? ''),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            document['documentName'] ?? 'Untitled',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF272579),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            document['originalFileName'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Uploaded on ${DateTime.parse(document['uploadedAt'] ?? '').toLocal().toString().split(' ')[0]}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _deleteDocument(document['_id']);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red, size: 20),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: Color(0xFF272579),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList()),
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