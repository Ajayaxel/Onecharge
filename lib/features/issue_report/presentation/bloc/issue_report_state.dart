part of 'issue_report_bloc.dart';

enum IssueReportStatus { initial, loading, success, failure }

class IssueReportState extends Equatable {
  const IssueReportState({
    this.status = IssueReportStatus.initial,
    this.ticket,
    this.message,
    this.statusCode,
  });

  final IssueReportStatus status;
  final Ticket? ticket;
  final String? message;
  final int? statusCode;

  IssueReportState copyWith({
    IssueReportStatus? status,
    Ticket? ticket,
    String? message,
    int? statusCode,
    bool clearMessage = false,
  }) {
    return IssueReportState(
      status: status ?? this.status,
      ticket: ticket ?? this.ticket,
      message: clearMessage ? null : (message ?? this.message),
      statusCode: statusCode ?? this.statusCode,
    );
  }

  bool get isLoading => status == IssueReportStatus.loading;
  bool get isSuccess => status == IssueReportStatus.success;
  bool get isFailure => status == IssueReportStatus.failure;

  @override
  List<Object?> get props => [status, ticket, message, statusCode];
}

