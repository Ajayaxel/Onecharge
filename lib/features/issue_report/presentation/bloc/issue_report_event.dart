part of 'issue_report_bloc.dart';

abstract class IssueReportEvent extends Equatable {
  const IssueReportEvent();

  @override
  List<Object?> get props => [];
}

class IssueReportSubmitted extends IssueReportEvent {
  const IssueReportSubmitted({
    required this.category,
    this.otherText,
    this.mediaPath,
  });

  final String category;
  final String? otherText;
  final String? mediaPath;

  @override
  List<Object?> get props => [category, otherText, mediaPath];
}

