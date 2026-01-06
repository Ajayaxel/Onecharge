part of 'issue_report_bloc.dart';

enum IssueReportStatus { initial, loading, uploading, success, failure }

class IssueReportState extends Equatable {
  const IssueReportState({
    this.status = IssueReportStatus.initial,
    this.ticket,
    this.message,
    this.statusCode,
    this.uploadProgress,
    this.currentUploadingFile,
    this.totalFiles,
    this.currentFileProgress,
    this.currentFileName,
    this.elapsedSeconds,
    this.errors,
    this.paymentRequired,
    this.paymentUrl,
    this.isValidatingCoupon = false,
    this.couponValidated = false,
    this.couponValidationError,
    this.couponValidationData,
  });

  final IssueReportStatus status;
  final Ticket? ticket;
  final String? message;
  final int? statusCode;
  final double? uploadProgress; // 0.0 to 1.0 - overall progress across all files
  final int? currentUploadingFile; // Current file index being uploaded (1-based)
  final int? totalFiles; // Total number of files to upload
  final double? currentFileProgress; // 0.0 to 1.0 - progress of current file being uploaded
  final String? currentFileName; // Name of the current file being uploaded
  final int? elapsedSeconds; // Elapsed time in seconds since upload started
  final Map<String, List<String>>? errors; // Validation errors from API
  final bool? paymentRequired;
  final String? paymentUrl;
  final bool isValidatingCoupon;
  final bool couponValidated;
  final String? couponValidationError;
  final RedeemCodeValidationData? couponValidationData;

  IssueReportState copyWith({
    IssueReportStatus? status,
    Ticket? ticket,
    String? message,
    int? statusCode,
    double? uploadProgress,
    int? currentUploadingFile,
    int? totalFiles,
    double? currentFileProgress,
    String? currentFileName,
    int? elapsedSeconds,
    Map<String, List<String>>? errors,
    bool? paymentRequired,
    String? paymentUrl,
    bool? isValidatingCoupon,
    bool? couponValidated,
    String? couponValidationError,
    RedeemCodeValidationData? couponValidationData,
    bool clearMessage = false,
    bool clearUploadProgress = false,
    bool clearCurrentFileProgress = false,
    bool clearErrors = false,
  }) {
    return IssueReportState(
      status: status ?? this.status,
      ticket: ticket ?? this.ticket,
      message: clearMessage ? null : (message ?? this.message),
      statusCode: statusCode ?? this.statusCode,
      uploadProgress: clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      currentUploadingFile: currentUploadingFile ?? this.currentUploadingFile,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFileProgress: clearCurrentFileProgress ? null : (currentFileProgress ?? this.currentFileProgress),
      currentFileName: currentFileName ?? this.currentFileName,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      errors: clearErrors ? null : (errors ?? this.errors),
      paymentRequired: paymentRequired ?? this.paymentRequired,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      isValidatingCoupon: isValidatingCoupon ?? this.isValidatingCoupon,
      couponValidated: couponValidated ?? this.couponValidated,
      couponValidationError: couponValidationError ?? this.couponValidationError,
      couponValidationData: couponValidationData ?? this.couponValidationData,
    );
  }

  bool get isLoading => status == IssueReportStatus.loading || status == IssueReportStatus.uploading;
  bool get isUploading => status == IssueReportStatus.uploading;
  bool get isSuccess => status == IssueReportStatus.success;
  bool get isFailure => status == IssueReportStatus.failure;

  @override
  List<Object?> get props => [
        status,
        ticket,
        message,
        statusCode,
        uploadProgress,
        currentUploadingFile,
        totalFiles,
        currentFileProgress,
        currentFileName,
        elapsedSeconds,
        errors,
        paymentRequired,
        paymentUrl,
        isValidatingCoupon,
        couponValidated,
        couponValidationError,
        couponValidationData,
      ];
}

