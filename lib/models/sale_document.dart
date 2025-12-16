import 'package:timezone/timezone.dart' as tz;
import '../utils/timezone_util.dart';

class SaleDocument {
  final String id; // MongoDB _id
  final String saleId; // MongoDB ObjectId as string
  final String saleIdString; // SALE-00001
  final String documentName; // Display name (selected or custom)
  final String documentType; // KYC Documents, Proposal Form, etc.
  final String originalFileName; // Original file name
  final String documentUrl; // S3 public URL
  final String s3Key; // S3 object key
  final String fileType; // MIME type
  final int fileSize; // File size in bytes
  final String status; // active or deleted
  final tz.TZDateTime uploadedAt;
  final String uploadedBy; // User ID
  final String? uploadedByName; // User's first name + last name

  SaleDocument({
    required this.id,
    required this.saleId,
    required this.saleIdString,
    required this.documentName,
    required this.documentType,
    required this.originalFileName,
    required this.documentUrl,
    required this.s3Key,
    required this.fileType,
    required this.fileSize,
    required this.status,
    required this.uploadedAt,
    required this.uploadedBy,
    this.uploadedByName,
  });

  // Get file extension from original filename
  String get fileExtension {
    final parts = originalFileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  // Get human-readable file size
  String get fileSizeFormatted {
    if (fileSize == 0) return '0 Bytes';

    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    final i = (fileSize.toString().length - 1) ~/ 3;
    final size = (fileSize / (k * i)).toStringAsFixed(2);

    return '$size ${sizes[i]}';
  }

  // Get file icon emoji based on extension
  String get fileIcon {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return '🖼️';
      case 'txt':
        return '📃';
      default:
        return '📎';
    }
  }

  /// Parse UTC time from API response and convert to IST
  static tz.TZDateTime _parseIST(String dateString) {
    final parsed = DateTime.parse(dateString);
    return TimezoneUtil.utcToIST(parsed);
  }

  // Factory constructor to create SaleDocument from JSON
  factory SaleDocument.fromJson(Map<String, dynamic> json) {
    return SaleDocument(
      id: json['_id'] ?? '',
      saleId: json['saleId'] ?? '',
      saleIdString: json['saleIdString'] ?? '',
      documentName: json['documentName'] ?? '',
      documentType: json['documentType'] ?? '',
      originalFileName: json['originalFileName'] ?? '',
      documentUrl: json['documentUrl'] ?? '',
      s3Key: json['s3Key'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      status: json['status'] ?? 'active',
      uploadedAt: json['uploadedAt'] != null
          ? _parseIST(json['uploadedAt'] as String)
          : TimezoneUtil.nowIST(),
      uploadedBy: json['uploadedBy'] is Map
          ? json['uploadedBy']['_id'] ?? ''
          : json['uploadedBy'] ?? '',
      uploadedByName: json['uploadedBy'] is Map
          ? '${json['uploadedBy']['firstName'] ?? ''} ${json['uploadedBy']['lastName'] ?? ''}'.trim()
          : json['uploadedByName'],
    );
  }

  // Convert SaleDocument to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'saleId': saleId,
      'saleIdString': saleIdString,
      'documentName': documentName,
      'documentType': documentType,
      'originalFileName': originalFileName,
      'documentUrl': documentUrl,
      's3Key': s3Key,
      'fileType': fileType,
      'fileSize': fileSize,
      'status': status,
      'uploadedAt': TimezoneUtil.toApiString(uploadedAt),
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
    };
  }

  // Copy with method
  SaleDocument copyWith({
    String? id,
    String? saleId,
    String? saleIdString,
    String? documentName,
    String? documentType,
    String? originalFileName,
    String? documentUrl,
    String? s3Key,
    String? fileType,
    int? fileSize,
    String? status,
    tz.TZDateTime? uploadedAt,
    String? uploadedBy,
    String? uploadedByName,
  }) {
    return SaleDocument(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      saleIdString: saleIdString ?? this.saleIdString,
      documentName: documentName ?? this.documentName,
      documentType: documentType ?? this.documentType,
      originalFileName: originalFileName ?? this.originalFileName,
      documentUrl: documentUrl ?? this.documentUrl,
      s3Key: s3Key ?? this.s3Key,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
    );
  }

  @override
  String toString() {
    return 'SaleDocument(id: $id, documentName: $documentName, fileSize: $fileSize)';
  }
}
