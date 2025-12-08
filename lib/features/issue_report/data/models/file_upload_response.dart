class FileUploadResponse {
  FileUploadResponse({
    required this.status,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.message,
  });

  final String status;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String? message;

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      status: json['status'] as String? ?? '',
      filePath: json['file_path'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      if (message != null) 'message': message,
    };
  }
}

