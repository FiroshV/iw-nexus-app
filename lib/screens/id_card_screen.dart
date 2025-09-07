import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/api_service.dart';

enum IDCardAction { share }

class IDCardScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final IDCardAction action;

  const IDCardScreen({
    super.key,
    this.userData,
    required this.action,
  });

  @override
  State<IDCardScreen> createState() => _IDCardScreenState();
}

class _IDCardScreenState extends State<IDCardScreen> {
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeAction();
    });
  }

  Future<void> _executeAction() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Generating ID card for sharing...';
    });

    try {
      // Request PDF from backend
      final response = await ApiService.generateIdCard();
      
      if (!response.success) {
        throw Exception(response.message);
      }

      // Convert response to PDF file
      final pdfFile = await _createPdfFileFromResponse(response.data);
      
      await _shareFile(pdfFile);

      setState(() {
        _isProcessing = false;
        _statusMessage = 'ID card shared successfully!';
      });

      // Auto close after 2 seconds
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<File> _createPdfFileFromResponse(dynamic responseData) async {
    // The backend returns PDF as binary data
    // We need to save it to a temporary file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/id_card_${DateTime.now().millisecondsSinceEpoch}.pdf');
    
    if (responseData is List<int>) {
      // Direct binary data
      await file.writeAsBytes(responseData);
    } else if (responseData is String) {
      // Base64 encoded data
      final bytes = responseData.codeUnits;
      await file.writeAsBytes(bytes);
    } else {
      throw Exception('Invalid PDF data format received from server');
    }
    
    return file;
  }

  Future<void> _shareFile(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'My ID Card',
        subject: 'Employee ID Card',
      );
      
      // Show success feedback
      HapticFeedback.heavyImpact();
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share ID Card'),
        backgroundColor: const Color(0xFF272579),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Processing indicator
              if (_isProcessing) ...[
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF272579),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ] else ...[
                // Success/Error icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _statusMessage.contains('Error')
                        ? Colors.red
                        : const Color(0xFF5cfbd8),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    _statusMessage.contains('Error')
                        ? Icons.error_outline
                        : Icons.check,
                    color: _statusMessage.contains('Error')
                        ? Colors.white
                        : const Color(0xFF272579),
                    size: 40,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Status message
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _statusMessage.contains('Error')
                      ? Colors.red
                      : const Color(0xFF272579),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Action buttons
              if (!_isProcessing) ...[
                if (_statusMessage.contains('Error')) ...[
                  ElevatedButton(
                    onPressed: _executeAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF272579),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}