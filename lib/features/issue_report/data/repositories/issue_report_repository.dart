import '../datasources/issue_report_api_service.dart';
import '../models/ticket_response.dart';

class IssueReportRepository {
  IssueReportRepository({IssueReportApiService? apiService})
      : _apiService = apiService ?? IssueReportApiService();

  final IssueReportApiService _apiService;

  Future<TicketResponse> submitIssueReport({
    required String category,
    String? otherText,
    String? mediaPath,
  }) async {
    print('🟢 [IssueReportRepository] submitIssueReport called');
    print('🟢 [IssueReportRepository] Category: $category');
    print('🟢 [IssueReportRepository] Other text: $otherText');
    print('🟢 [IssueReportRepository] Media path: $mediaPath');
    
    final response = await _apiService.submitIssueReport(
      category: category,
      otherText: otherText,
      mediaPath: mediaPath,
    );
    
    print('✅ [IssueReportRepository] API service returned successfully');
    return response;
  }
}

