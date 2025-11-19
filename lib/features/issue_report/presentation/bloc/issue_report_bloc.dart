import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/api_exception.dart';
import '../../data/models/ticket_response.dart';
import '../../data/repositories/issue_report_repository.dart';

part 'issue_report_event.dart';
part 'issue_report_state.dart';

class IssueReportBloc extends Bloc<IssueReportEvent, IssueReportState> {
  IssueReportBloc(this._repository) : super(const IssueReportState()) {
    on<IssueReportSubmitted>(_onIssueReportSubmitted);
  }

  final IssueReportRepository _repository;

  Future<void> _onIssueReportSubmitted(
    IssueReportSubmitted event,
    Emitter<IssueReportState> emit,
  ) async {
    print('🟡 [IssueReportBloc] _onIssueReportSubmitted - Event received');
    print('🟡 [IssueReportBloc] Category: ${event.category}');
    print('🟡 [IssueReportBloc] Other text: ${event.otherText}');
    print('🟡 [IssueReportBloc] Media path: ${event.mediaPath}');
    
    emit(
      state.copyWith(
        status: IssueReportStatus.loading,
        clearMessage: true,
      ),
    );
    print('🟡 [IssueReportBloc] State changed to: loading');
    
    try {
      print('🟡 [IssueReportBloc] Calling repository.submitIssueReport...');
      final response = await _repository.submitIssueReport(
        category: event.category,
        otherText: event.otherText,
        mediaPath: event.mediaPath,
      );
      print('✅ [IssueReportBloc] Repository call successful');
      print('✅ [IssueReportBloc] Response message: ${response.message}');
      print('✅ [IssueReportBloc] Ticket ID: ${response.ticket.id}');
      print('✅ [IssueReportBloc] Ticket category: ${response.ticket.category}');
      
      emit(
        state.copyWith(
          status: IssueReportStatus.success,
          ticket: response.ticket,
          message: response.message,
        ),
      );
      print('✅ [IssueReportBloc] State changed to: success');
    } on ApiException catch (error) {
      print('❌ [IssueReportBloc] ApiException caught: ${error.message}');
      print('❌ [IssueReportBloc] Status code: ${error.statusCode}');
      emit(
        state.copyWith(
          status: IssueReportStatus.failure,
          message: error.message,
          statusCode: error.statusCode,
        ),
      );
      print('❌ [IssueReportBloc] State changed to: failure');
    } catch (e, stackTrace) {
      print('❌ [IssueReportBloc] Unexpected error: $e');
      print('❌ [IssueReportBloc] Stack trace: $stackTrace');
      emit(
        state.copyWith(
          status: IssueReportStatus.failure,
          message: 'Something went wrong. Please try again.',
        ),
      );
      print('❌ [IssueReportBloc] State changed to: failure');
    }
  }
}

