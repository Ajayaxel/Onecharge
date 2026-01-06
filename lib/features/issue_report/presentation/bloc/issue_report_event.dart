part of 'issue_report_bloc.dart';

abstract class IssueReportEvent extends Equatable {
  const IssueReportEvent();

  @override
  List<Object?> get props => [];
}

class IssueReportSubmitted extends IssueReportEvent {
  const IssueReportSubmitted({
    required this.issueCategoryId,
    required this.vehicleTypeId,
    required this.brandId,
    required this.modelId,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.mediaPaths,
    this.numberPlate,
    this.description,
    this.redeemCode,
  });

  final int issueCategoryId;
  final int vehicleTypeId;
  final int brandId;
  final int modelId;
  final String location;
  final double latitude;
  final double longitude;
  final List<String>? mediaPaths;
  final String? numberPlate;
  final String? description;
  final String? redeemCode;

  @override
  List<Object?> get props => [
        issueCategoryId,
        vehicleTypeId,
        brandId,
        modelId,
        location,
        latitude,
        longitude,
        mediaPaths,
        numberPlate,
        description,
        redeemCode,
      ];
}

class CreateTicketSubmitted extends IssueReportEvent {
  const CreateTicketSubmitted({
    required this.issueCategoryId,
    required this.vehicleTypeId,
    required this.brandId,
    required this.modelId,
    required this.numberPlate,
    required this.location,
    this.latitude,
    this.longitude,
    this.description,
    this.mediaPaths,
    this.redeemCode,
  });

  final int issueCategoryId;
  final int vehicleTypeId;
  final int brandId;
  final int modelId;
  final String numberPlate;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final List<String>? mediaPaths;
  final String? redeemCode;

  @override
  List<Object?> get props => [
        issueCategoryId,
        vehicleTypeId,
        brandId,
        modelId,
        numberPlate,
        location,
        latitude,
        longitude,
        description,
        mediaPaths,
        redeemCode,
      ];
}

class FileUploadProgress extends IssueReportEvent {
  const FileUploadProgress({
    required this.fileIndex,
    required this.progress,
    required this.totalFiles,
  });

  final int fileIndex;
  final double progress; // 0.0 to 1.0
  final int totalFiles;

  @override
  List<Object?> get props => [fileIndex, progress, totalFiles];
}

class ValidateRedeemCode extends IssueReportEvent {
  const ValidateRedeemCode({
    required this.redeemCode,
  });

  final String redeemCode;

  @override
  List<Object?> get props => [redeemCode];
}

