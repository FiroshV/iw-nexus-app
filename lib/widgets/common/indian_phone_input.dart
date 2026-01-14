import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

/// A standardized phone input widget with a separate +91 prefix box
/// and 10-digit input field for Indian mobile numbers.
///
/// Visual layout:
/// ```
/// +--------+  +---------------------------+
/// |  +91   |  |  9876543210               |
/// +--------+  +---------------------------+
/// ```
class IndianPhoneInput extends StatefulWidget {
  /// Controller for the phone number input (10 digits only, without prefix)
  final TextEditingController controller;

  /// Label text displayed above the input field
  final String? labelText;

  /// Hint text displayed inside the input field
  final String? hintText;

  /// Whether the field is required for form validation
  final bool isRequired;

  /// Whether the input is enabled
  final bool enabled;

  /// Whether the input is read-only
  final bool readOnly;

  /// Callback when the phone number value changes
  final ValueChanged<String>? onChanged;

  /// Callback when the field is tapped
  final VoidCallback? onTap;

  /// Callback when the field is submitted
  final ValueChanged<String>? onFieldSubmitted;

  /// Additional custom validator (runs after built-in validation)
  final String? Function(String?)? validator;

  /// Focus node for the input field
  final FocusNode? focusNode;

  /// Text input action for the keyboard
  final TextInputAction? textInputAction;

  /// Auto-validation mode
  final AutovalidateMode? autovalidateMode;

  const IndianPhoneInput({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.isRequired = true,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.onFieldSubmitted,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.autovalidateMode,
  });

  /// Validates an Indian mobile number (10 digits starting with 6-9)
  static String? validateIndianMobile(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Phone number is required' : null;
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length != 10) {
      return 'Please enter exactly 10 digits';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }

    return null;
  }

  /// Formats a phone number for API submission (adds +91 prefix)
  static String formatForApi(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    return phone;
  }

  /// Parses a phone number from API response (strips +91 prefix for display)
  static String parseFromApi(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return cleaned.substring(2);
    }
    if (cleaned.length == 10) {
      return cleaned;
    }
    // Return last 10 digits if longer
    if (cleaned.length > 10) {
      return cleaned.substring(cleaned.length - 10);
    }
    return phone;
  }

  @override
  State<IndianPhoneInput> createState() => _IndianPhoneInputState();
}

class _IndianPhoneInputState extends State<IndianPhoneInput> {
  bool _isFocused = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.labelText != null) ...[
          Row(
            children: [
              Text(
                widget.labelText!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CrmColors.textDark,
                ),
              ),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CrmColors.errorColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Input Row - IntrinsicHeight ensures both boxes have same height
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prefix Box (+91)
              Container(
                width: 60,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? Colors.white
                      : CrmColors.borderColor.withValues(alpha: 0.5),
                border: Border.all(
                  color: _errorText != null
                      ? CrmColors.errorColor
                      : _isFocused
                          ? CrmColors.primary
                          : CrmColors.borderColor,
                  width: _isFocused ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(CrmDesignSystem.radiusLarge),
                  bottomLeft: Radius.circular(CrmDesignSystem.radiusLarge),
                ),
              ),
              child: Center(
                child: Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
                        ? CrmColors.primary
                        : CrmColors.textLight,
                  ),
                ),
              ),
            ),

            // Input Field
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  setState(() {
                    _isFocused = hasFocus;
                  });
                },
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.textInputAction,
                  autovalidateMode: widget.autovalidateMode,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.enabled
                        ? CrmColors.textDark
                        : CrmColors.textLight,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Enter 10-digit number',
                    hintStyle: TextStyle(
                      color: CrmColors.textLight,
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: widget.enabled
                        ? Colors.white
                        : CrmColors.borderColor.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(CrmDesignSystem.radiusLarge),
                        bottomRight:
                            Radius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      borderSide: BorderSide(color: CrmColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(CrmDesignSystem.radiusLarge),
                        bottomRight:
                            Radius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      borderSide: BorderSide(color: CrmColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(CrmDesignSystem.radiusLarge),
                        bottomRight:
                            Radius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      borderSide: BorderSide(
                        color: CrmColors.primary,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(CrmDesignSystem.radiusLarge),
                        bottomRight:
                            Radius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      borderSide: BorderSide(color: CrmColors.errorColor),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(CrmDesignSystem.radiusLarge),
                        bottomRight:
                            Radius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      borderSide: BorderSide(
                        color: CrmColors.errorColor,
                        width: 1.5,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(CrmDesignSystem.radiusLarge),
                        bottomRight:
                            Radius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      borderSide: BorderSide(
                        color: CrmColors.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    // Hide default error text (we show it below the entire widget)
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  validator: (value) {
                    // Run built-in validation
                    final builtInError = IndianPhoneInput.validateIndianMobile(
                      value,
                      isRequired: widget.isRequired,
                    );

                    if (builtInError != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _errorText = builtInError;
                          });
                        }
                      });
                      return builtInError;
                    }

                    // Run custom validator if provided
                    if (widget.validator != null) {
                      final customError = widget.validator!(value);
                      if (customError != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _errorText = customError;
                            });
                          }
                        });
                        return customError;
                      }
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _errorText = null;
                        });
                      }
                    });
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        ),

        // Error Text
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _errorText!,
              style: TextStyle(
                fontSize: 12,
                color: CrmColors.errorColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
