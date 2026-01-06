import 'dart:io';
import '../datasources/issue_report_api_service.dart';
import '../models/ticket_response.dart';
import '../models/issue_category.dart';
import '../models/create_ticket_request.dart';
import '../models/vehicle_type.dart';
import '../models/brand_model.dart';
import '../models/model_item.dart';
import '../models/driver_location_response.dart';
import '../models/redeem_code_validation_response.dart';
import '../../../../core/storage/token_storage.dart';

class IssueReportRepository {
  IssueReportRepository({IssueReportApiService? apiService})
      : _apiService = apiService ?? IssueReportApiService();

  final IssueReportApiService _apiService;

  Future<List<String>> uploadFiles(List<String> filePaths) async {
    print('🟢 [IssueReportRepository] uploadFiles called');
    return await _apiService.uploadFiles(filePaths);
  }

  Future<TicketResponse> submitIssueReport({
    required int issueCategoryId,
    required int vehicleTypeId,
    required int brandId,
    required int modelId,
    required String location,
    required double latitude,
    required double longitude,
    List<String>? attachments,
  }) async {
    print('🟢 [IssueReportRepository] ========== submitIssueReport START ==========');
    print('🟢 [IssueReportRepository] submitIssueReport called');
    print('🟢 [IssueReportRepository] issueCategoryId: $issueCategoryId');
    print('🟢 [IssueReportRepository] vehicleTypeId: $vehicleTypeId');
    print('🟢 [IssueReportRepository] brandId: $brandId');
    print('🟢 [IssueReportRepository] modelId: $modelId');
    print('🟢 [IssueReportRepository] location: $location');
    print('🟢 [IssueReportRepository] latitude: $latitude, longitude: $longitude');
    print('🟢 [IssueReportRepository] attachments: ${attachments?.length ?? 0}');
    
    final response = await _apiService.submitIssueReport(
      issueCategoryId: issueCategoryId,
      vehicleTypeId: vehicleTypeId,
      brandId: brandId,
      modelId: modelId,
      location: location,
      latitude: latitude,
      longitude: longitude,
      attachments: attachments,
    );
    
    print('✅ [IssueReportRepository] API service returned successfully');
    print('✅ [IssueReportRepository] ========== submitIssueReport SUCCESS ==========');
    return response;
  }

  Future<List<IssueCategory>> fetchIssueCategories() async {
    print('🟢 [IssueReportRepository] ========== fetchIssueCategories START ==========');
    print('🟢 [IssueReportRepository] fetchIssueCategories called');
    print('🟢 [IssueReportRepository] Calling API service...');
    
    try {
      final categories = await _apiService.fetchIssueCategories();
      
      print('✅ [IssueReportRepository] API service returned successfully');
      print('✅ [IssueReportRepository] Total categories received: ${categories.length}');
      print('✅ [IssueReportRepository] Categories list:');
      for (var i = 0; i < categories.length; i++) {
        print('   ${i + 1}. ID: ${categories[i].id}, Name: ${categories[i].name}');
      }
      print('✅ [IssueReportRepository] ========== fetchIssueCategories SUCCESS ==========');
      return categories;
    } catch (e) {
      print('❌ [IssueReportRepository] Error in fetchIssueCategories: $e');
      print('❌ [IssueReportRepository] ========== fetchIssueCategories FAILED ==========');
      rethrow;
    }
  }

  Future<List<VehicleType>> getVehicleTypes() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.getVehicleTypes(token);
  }

  Future<List<BrandModel>> getBrands(int vehicleTypeId) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.getBrands(token, vehicleTypeId);
  }

  Future<List<ModelItem>> getModels(int brandId) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.getModels(token, brandId);
  }

  Future<TicketResponse> createTicket(CreateTicketRequest request) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.createTicket(token, request);
  }

  Future<String> uploadFile(
    File file,
    String token, {
    void Function(int sent, int total)? onProgress,
  }) async {
    return await _apiService.uploadFile(file, token, onProgress: onProgress);
  }

  Future<TicketResponse> getTicketById(int ticketId) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.getTicketById(token, ticketId);
  }

  Future<List<Ticket>> getAllTickets() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.getAllTickets(token);
  }

  Future<DriverLocationResponse> getDriverLocation(int ticketId) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.getDriverLocation(token, ticketId);
  }

  Future<List<int>> downloadInvoice(int ticketId) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.downloadInvoice(token, ticketId);
  }

  Future<RedeemCodeValidationResponse> validateRedeemCode(String redeemCode) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue.');
    }
    return await _apiService.validateRedeemCode(token, redeemCode);
  }
}

