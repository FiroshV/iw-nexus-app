import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/timezone_util.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  
  String? selectedDepartment;
  String? selectedRole;
  String? selectedManagerId;
  DateTime? selectedJoiningDate;
  
  List<Map<String, dynamic>> managers = [];
  bool isLoadingManagers = false;
  bool isSubmitting = false;

  final List<String> departments = [
    'HR',
    'Engineering',
    'Marketing',
    'Sales',
    'Finance',
    'Operations',
    'Admin'
  ];
  
  final List<String> roles = [
    'employee',
    'manager',
    'field_staff',
    'telecaller',
    'director',
    'admin'
  ];

  @override
  void initState() {
    super.initState();
    selectedJoiningDate = null;
    _loadManagers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  String _formatRoleDisplay(String role) {
    switch (role) {
      case 'field_staff':
        return 'Field Staff';
      case 'telecaller':
        return 'Telecaller';
      default:
        return role.toUpperCase();
    }
  }

  Future<void> _loadManagers() async {
    setState(() {
      isLoadingManagers = true;
    });

    try {
      final response = await ApiService.getManagers();
      if (response.success && response.data != null) {
        setState(() {
          // Handle different response formats
          if (response.data is List) {
            managers = List<Map<String, dynamic>>.from(response.data as List);
          } else if (response.data is Map<String, dynamic>) {
            final responseMap = response.data as Map<String, dynamic>;
            managers = List<Map<String, dynamic>>.from(responseMap['data'] ?? []);
          } else {
            managers = [];
          }
          isLoadingManagers = false;
        });
      } else {
        setState(() {
          isLoadingManagers = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingManagers = false;
      });
    }
  }

  Future<void> _selectJoiningDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: (selectedJoiningDate ?? TimezoneUtil.nowIST()).toLocal(),
      firstDate: DateTime(2000),
      lastDate: TimezoneUtil.nowIST().add(const Duration(days: 365)).toLocal(),
    );
    
    if (date != null) {
      setState(() {
        selectedJoiningDate = date;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await ApiService.createUser(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phoneNumber: _phoneController.text.trim(),
        department: selectedDepartment,
        role: selectedRole!,
        designation: _designationController.text.trim(),
        dateOfJoining: selectedJoiningDate?.toIso8601String(),
        managerId: selectedManagerId,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User'),
        backgroundColor: const Color(0xFF272579),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF272579),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'First name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Last Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Last name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Work Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Work Information',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF272579),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('No Department')),
                          ...departments.map((dept) => 
                            DropdownMenuItem(value: dept, child: Text(dept))
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDepartment = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work),
                        ),
                        items: roles.map((role) => 
                          DropdownMenuItem(value: role, child: Text(_formatRoleDisplay(role)))
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a role';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _designationController,
                        decoration: const InputDecoration(
                          labelText: 'Designation *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Designation is required';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      InkWell(
                        onTap: _selectJoiningDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Joining (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            selectedJoiningDate != null
                                ? '${selectedJoiningDate!.day}/${selectedJoiningDate!.month}/${selectedJoiningDate!.year}'
                                : 'Select Date (Optional)',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: selectedManagerId,
                        decoration: const InputDecoration(
                          labelText: 'Manager (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.supervisor_account),
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('No Manager')),
                          ...managers.map((manager) => 
                            DropdownMenuItem<String>(
                              value: manager['_id'] as String,
                              child: Text('${manager['firstName']} ${manager['lastName']} (${manager['employeeId']})'),
                            )
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedManagerId = value;
                          });
                        },
                      ),
                      
                      if (isLoadingManagers)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Loading managers...', style: TextStyle(color: Colors.grey)),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF272579),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create User',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}