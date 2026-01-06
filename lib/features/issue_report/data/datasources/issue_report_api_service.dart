import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/ticket_response.dart';
import '../models/issue_category.dart';
import '../models/file_upload_response.dart';
import '../models/create_ticket_request.dart';
import '../models/vehicle_type.dart';
import '../models/brand_model.dart';
import '../models/model_item.dart';
import '../models/driver_location_response.dart';
import '../models/redeem_code_validation_response.dart';

class IssueReportApiService {
  IssueReportApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  /// Upload a single file using the simple upload endpoint
  /// Returns the file path from the response
  /// [onProgress] callback receives (sent, total) bytes
  Future<String> uploadFile(
    File file,
    String token, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final isVideo = _isVideoFile(file.path);
    
    print('📤 [IssueReportApiService] Uploading file: $fileName');
    print('📤 [IssueReportApiService] File type: ${isVideo ? "Video" : "Image"}');
    print('📤 [IssueReportApiService] File size: ${await file.length()} bytes');
    
    try {
      // Determine content type based on file extension for logging
      final contentType = _getContentType(file.path);
      print('📤 [IssueReportApiService] Content-Type: $contentType');
      
      // Create multipart file
      // Note: Dio 5.x doesn't support contentType in fromFile, server will detect from extension
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      // Use longer timeout for videos
      final timeout = isVideo 
          ? const Duration(seconds: 400) // 6 minutes for videos
          : const Duration(seconds: 60); // 1 minute for images

      print('📤 [IssueReportApiService] Upload timeout: ${timeout.inSeconds}s');

      final response = await _dio.post(
        ApiConfig.uploadSimple,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Upload-For': 'tickets',
            'Accept': 'application/json',
          },
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = (sent / total * 100).toStringAsFixed(1);
            print('📤 [IssueReportApiService] Upload progress: $progress% ($sent/$total bytes)');
            // Call the progress callback if provided
            onProgress?.call(sent, total);
          }
        },
      );

      print('✅ [IssueReportApiService] Upload response: ${response.data}');
      
      final uploadResponse = FileUploadResponse.fromJson(response.data as Map<String, dynamic>);
      
      if (uploadResponse.status == 'success' && uploadResponse.filePath.isNotEmpty) {
        print('✅ [IssueReportApiService] File uploaded successfully: ${uploadResponse.filePath}');
        print('✅ [IssueReportApiService] File name: ${uploadResponse.fileName}');
        print('✅ [IssueReportApiService] File size: ${uploadResponse.fileSize} bytes');
        return uploadResponse.filePath;
      } else {
        throw ApiException('File upload failed: ${uploadResponse.message ?? "Unknown error"}');
      }
    } on DioException catch (e) {
      print('❌ [IssueReportApiService] Error uploading file: $e');
      print('❌ [IssueReportApiService] Error type: ${e.type}');
      print('❌ [IssueReportApiService] Error message: ${e.message}');
      print('❌ [IssueReportApiService] Response status: ${e.response?.statusCode}');
      print('❌ [IssueReportApiService] Response data: ${e.response?.data}');
      
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'File upload failed')
          : (e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout
              ? 'Upload timeout. The file may be too large. Please try a smaller file.'
              : 'File upload failed: ${e.message ?? "Unknown error"}');
      throw ApiException(message, statusCode: e.response?.statusCode);
    } catch (e) {
      print('❌ [IssueReportApiService] Unexpected error uploading file: $e');
      throw ApiException('File upload failed: ${e.toString()}');
    }
  }

  /// Check if file is a video
  bool _isVideoFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.mkv') ||
        lowerPath.endsWith('.m4v') ||
        lowerPath.endsWith('.3gp') ||
        lowerPath.endsWith('.webm');
  }

  /// Get content type based on file extension
  String? _getContentType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (lowerPath.endsWith('.png')) {
      return 'image/png';
    } else if (lowerPath.endsWith('.gif')) {
      return 'image/gif';
    } else if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    } else if (lowerPath.endsWith('.mp4')) {
      return 'video/mp4';
    } else if (lowerPath.endsWith('.mov')) {
      return 'video/quicktime';
    } else if (lowerPath.endsWith('.avi')) {
      return 'video/x-msvideo';
    } else if (lowerPath.endsWith('.mkv')) {
      return 'video/x-matroska';
    } else if (lowerPath.endsWith('.m4v')) {
      return 'video/x-m4v';
    } else if (lowerPath.endsWith('.3gp')) {
      return 'video/3gpp';
    } else if (lowerPath.endsWith('.webm')) {
      return 'video/webm';
    }
    return null; // Let server determine content type
  }

  /// Upload multiple files and return file paths
  Future<List<String>> uploadFiles(List<String> filePaths) async {
    print('🔵 [IssueReportApiService] uploadFiles called with ${filePaths.length} files');
    
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Please login to continue.', statusCode: 401);
    }

    final uploadedPaths = <String>[];
    
    for (String filePath in filePaths) {
      if (filePath.trim().isEmpty) continue;
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('⚠️ File not found: $filePath');
        continue;
      }

      try {
        final uploadedPath = await uploadFile(file, token);
        uploadedPaths.add(uploadedPath);
      } catch (e) {
        print('❌ [IssueReportApiService] Error uploading file $filePath: $e');
        // Continue with other files even if one fails
      }
    }

    print('✅ [IssueReportApiService] Total files uploaded: ${uploadedPaths.length}');
    return uploadedPaths;
  }

  /// Create a ticket with the provided request data
  Future<TicketResponse> createTicket(String token, CreateTicketRequest request) async {
    print('🔵 [IssueReportApiService] ========== createTicket START ==========');
    print('🔵 [IssueReportApiService] createTicket called');
    print('🔵 [IssueReportApiService] Request: ${request.toJson()}');

    try {
      // Build form data
      final formDataMap = <String, dynamic>{
        'issue_category_id': request.issueCategoryId.toString(),
        'vehicle_type_id': request.vehicleTypeId.toString(),
        'brand_id': request.brandId.toString(),
        'model_id': request.modelId.toString(),
        'number_plate': request.numberPlate,
        'location': request.location,
      };

      // Add optional fields
      if (request.latitude != null) {
        formDataMap['latitude'] = request.latitude.toString();
      }
      if (request.longitude != null) {
        formDataMap['longitude'] = request.longitude.toString();
      }
      if (request.description != null && request.description!.isNotEmpty) {
        formDataMap['description'] = request.description;
      }
      if (request.redeemCode != null && request.redeemCode!.isNotEmpty) {
        formDataMap['redeem_code'] = request.redeemCode;
      }

      // Handle file attachments - if attachments are file paths, convert them to MultipartFile
      // Otherwise, if they're already uploaded URLs, add them as strings
      if (request.attachments != null && request.attachments!.isNotEmpty) {
        final attachmentFiles = <MultipartFile>[];
        final attachmentUrls = <String>[];
        
        for (final attachment in request.attachments!) {
          // Check if it's a local file path or a URL
          if (attachment.startsWith('http://') || attachment.startsWith('https://')) {
            // It's already an uploaded URL
            attachmentUrls.add(attachment);
          } else {
            // It's a local file path - try to create MultipartFile
            final file = File(attachment);
            if (await file.exists()) {
              final fileName = attachment.split('/').last;
              final multipartFile = await MultipartFile.fromFile(
                attachment,
                filename: fileName,
              );
              attachmentFiles.add(multipartFile);
            }
          }
        }
        
        // Add file attachments as MultipartFile array
        if (attachmentFiles.isNotEmpty) {
          formDataMap['attachments[]'] = attachmentFiles;
        }
        
        // If we have URLs, we might need to send them differently
        // For now, we'll prioritize files over URLs if both exist
        // If only URLs exist, we might need to adjust the API call
        // This depends on API requirements - assuming files take precedence
      }

      final formData = FormData.fromMap(formDataMap);

      print('🔵 [IssueReportApiService] FormData created with ${formDataMap.length} fields');
      if (request.attachments != null) {
        print('🔵 [IssueReportApiService] Attachments count: ${request.attachments!.length}');
      }

      /// Send request as form-data
      final response = await _dio.post(
        ApiConfig.tickets,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            // Don't set Content-Type - Dio will set it automatically for FormData with boundary
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      print('✅ [IssueReportApiService] Response Status: ${response.statusCode}');
      print('✅ [IssueReportApiService] Response Data: ${response.data}');
      print('✅ [IssueReportApiService] ========== createTicket SUCCESS ==========');
      
      return TicketResponse.fromJson(response.data);
    }

    /// Handle DIO Exception
    on DioException catch (error) {
      print('❌ DioException: ${error.message}');
      final status = error.response?.statusCode;
      final data = error.response?.data;

      String message = "Something went wrong";
      Map<String, List<String>>? errors;

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) message = data['message'];

        if (data['errors'] != null && data['errors'] is Map) {
          errors = {};
          (data['errors'] as Map).forEach((key, value) {
            errors![key] = List<String>.from(value.map((e) => e.toString()));
          });
        }

        if (errors != null && errors.isNotEmpty) {
          message = errors.entries
              .map((e) => "${e.key.toUpperCase()}: ${e.value.join(', ')}")
              .join("\n");
        }
      }

      throw ApiException(message, statusCode: status, errors: errors);
    }

    /// Unknown error
    catch (e) {
      throw ApiException('Unable to process your request');
    }
  }

  /// Legacy method for backward compatibility
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
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Please login to continue.', statusCode: 401);
    }

    final request = CreateTicketRequest(
      issueCategoryId: issueCategoryId,
      vehicleTypeId: vehicleTypeId,
      brandId: brandId,
      modelId: modelId,
      numberPlate: '', // Legacy - will be empty
      location: location,
      latitude: latitude,
      longitude: longitude,
      attachments: attachments,
    );

    return createTicket(token, request);
  }

  Future<List<IssueCategory>> fetchIssueCategories() async {
    try {
      print('🔵 [IssueReportApiService] ========== fetchIssueCategories START ==========');
      print('🔵 [IssueReportApiService] Starting fetchIssueCategories');
      
      final token = await TokenStorage.readToken();
      print('🔵 [IssueReportApiService] Token exists: ${token != null && token.isNotEmpty}');
      
      // Build headers - only include Authorization if token exists
      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('🔵 [IssueReportApiService] Authorization header added');
      } else {
        print('⚠️ [IssueReportApiService] No token found, making unauthenticated request');
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.issueCategories}';
      print('🔵 [IssueReportApiService] Request URL: $url');
      print('🔵 [IssueReportApiService] Request Headers: $headers');
      print('🔵 [IssueReportApiService] Making GET request...');

      final response = await _dio.get(
        ApiConfig.issueCategories,
        options: Options(
          headers: headers,
        ),
      );
      
      print('🔵 [IssueReportApiService] ========== RESPONSE RECEIVED ==========');
      print('🔵 [IssueReportApiService] Response Status Code: ${response.statusCode}');
      print('🔵 [IssueReportApiService] Response Data Type: ${response.data.runtimeType}');
      print('🔵 [IssueReportApiService] Response Data: ${response.data}');
      
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        print('✅ [IssueReportApiService] Success flag: $success');
        
        if (success) {
          final dataMap = data['data'] as Map<String, dynamic>?;
          print('📦 [IssueReportApiService] Data map: $dataMap');
          
          final rawCategories =
              (dataMap?['issue_categories'] as List<dynamic>? ?? <dynamic>[]);
          print('📋 [IssueReportApiService] Raw categories count: ${rawCategories.length}');
          print('📋 [IssueReportApiService] Raw categories: $rawCategories');
          
          final categories = rawCategories
              .whereType<Map<String, dynamic>>()
              .map(IssueCategory.fromJson)
              .toList();
          
          print('✅ [IssueReportApiService] Parsed categories count: ${categories.length}');
          print('📝 [IssueReportApiService] Categories: ${categories.map((c) => '${c.id}: ${c.name}').join(', ')}');
          
          for (var category in categories) {
            print('   - ID: ${category.id}, Name: ${category.name}');
          }
          
          print('✅ [IssueReportApiService] ========== fetchIssueCategories SUCCESS ==========');
          return categories;
        }
        
        final errorMessage = data['message'] as String? ?? 'Unable to load issue categories.';
        print('❌ [IssueReportApiService] API returned success=false');
        print('❌ [IssueReportApiService] Error message: $errorMessage');
        throw ApiException(errorMessage);
      }

      print('❌ [IssueReportApiService] Unexpected response type: ${data.runtimeType}');
      throw ApiException('Unexpected response while loading issue categories.');
    } on DioException catch (error) {
      print('❌ [IssueReportApiService] ========== DIO EXCEPTION ==========');
      print('❌ [IssueReportApiService] DioException occurred');
      print('❌ [IssueReportApiService] Error message: ${error.message}');
      print('❌ [IssueReportApiService] Error type: ${error.type}');
      print('❌ [IssueReportApiService] Status code: ${error.response?.statusCode}');
      print('❌ [IssueReportApiService] Response data: ${error.response?.data}');
      
      final statusCode = error.response?.statusCode;
      
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message'] as String? ??
              'Failed to load issue categories.')
          : 'Failed to load issue categories.';
      
      print('❌ [IssueReportApiService] Throwing ApiException: $message');
      throw ApiException(
        message,
        statusCode: statusCode,
      );
    } on ApiException catch (e) {
      print('❌ [IssueReportApiService] ApiException rethrown: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('❌ [IssueReportApiService] ========== UNKNOWN ERROR ==========');
      print('❌ [IssueReportApiService] Unknown error: $e');
      print('❌ [IssueReportApiService] Stack trace: $stackTrace');
      throw ApiException('Something went wrong. Please try again.');
    }
  }

  /// Get vehicle types
  Future<List<VehicleType>> getVehicleTypes(String token) async {
    try {
      print('🔵 [IssueReportApiService] Fetching vehicle types');
      
      final response = await _dio.get(
        ApiConfig.vehicleCategories,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final dataMap = data['data'] as Map<String, dynamic>?;
        final rawTypes = (dataMap?['vehicle_types'] as List<dynamic>? ?? <dynamic>[]);
        
        final types = rawTypes
            .whereType<Map<String, dynamic>>()
            .map(VehicleType.fromJson)
            .toList();
        
        print('✅ [IssueReportApiService] Fetched ${types.length} vehicle types');
        return types;
      }
      
      throw ApiException(data['message'] as String? ?? 'Unable to load vehicle types.');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Failed to load vehicle types')
          : 'Failed to load vehicle types';
      throw ApiException(message, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Failed to load vehicle types: ${e.toString()}');
    }
  }

  /// Get brands by vehicle type
  Future<List<BrandModel>> getBrands(String token, int vehicleTypeId) async {
    try {
      print('🔵 [IssueReportApiService] Fetching brands for vehicle type: $vehicleTypeId');
      
      final response = await _dio.get(
        '${ApiConfig.brands}?vehicle_type_id=$vehicleTypeId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final dataMap = data['data'] as Map<String, dynamic>?;
        final rawBrands = (dataMap?['brands'] as List<dynamic>? ?? <dynamic>[]);
        
        final brands = rawBrands
            .whereType<Map<String, dynamic>>()
            .where((brandJson) {
              final vtId = (brandJson['vehicle_type_id'] as num?)?.toInt();
              return vtId == vehicleTypeId;
            })
            .map(BrandModel.fromJson)
            .toList();
        
        print('✅ [IssueReportApiService] Fetched ${brands.length} brands');
        return brands;
      }
      
      throw ApiException(data['message'] as String? ?? 'Unable to load brands.');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Failed to load brands')
          : 'Failed to load brands';
      throw ApiException(message, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Failed to load brands: ${e.toString()}');
    }
  }

  /// Get models by brand
  Future<List<ModelItem>> getModels(String token, int brandId) async {
    try {
      print('🔵 [IssueReportApiService] Fetching models for brand: $brandId');
      
      final response = await _dio.get(
        '${ApiConfig.models}?brand_id=$brandId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final dataMap = data['data'] as Map<String, dynamic>?;
        final rawModels = (dataMap?['models'] as List<dynamic>? ?? <dynamic>[]);
        
        final models = rawModels
            .whereType<Map<String, dynamic>>()
            .where((modelJson) {
              final bId = (modelJson['brand_id'] as num?)?.toInt();
              return bId == brandId;
            })
            .map(ModelItem.fromJson)
            .toList();
        
        print('✅ [IssueReportApiService] Fetched ${models.length} models');
        return models;
      }
      
      throw ApiException(data['message'] as String? ?? 'Unable to load models.');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Failed to load models')
          : 'Failed to load models';
      throw ApiException(message, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Failed to load models: ${e.toString()}');
    }
  }

  /// Get ticket by numerical ID (not ticket_id string)
  Future<TicketResponse> getTicketById(String token, int ticketId) async {
    try {
      print('🔵 [IssueReportApiService] ========== getTicketById START ==========');
      print('🔵 [IssueReportApiService] Ticket numerical ID: $ticketId');
      print('🔵 [IssueReportApiService] Token exists: ${token.isNotEmpty}');
      print('🔵 [IssueReportApiService] Token length: ${token.length}');
      
      // API expects numerical ID in the path, not the string ticket_id
      final url = '${ApiConfig.tickets}/$ticketId';
      final fullUrl = '${ApiConfig.baseUrl}$url';
      print('🔵 [IssueReportApiService] Request URL: $fullUrl');
      print('🔵 [IssueReportApiService] Making GET request...');
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ [IssueReportApiService] Response Status: ${response.statusCode}');
      print('✅ [IssueReportApiService] Response Data: ${response.data}');
      print('✅ [IssueReportApiService] ========== getTicketByTicketId SUCCESS ==========');
      
      return TicketResponse.fromJson(response.data);
    } on DioException catch (error) {
      print('❌ [IssueReportApiService] ========== DIO EXCEPTION ==========');
      print('❌ [IssueReportApiService] DioException type: ${error.type}');
      print('❌ [IssueReportApiService] DioException message: ${error.message}');
      print('❌ [IssueReportApiService] Response status code: ${error.response?.statusCode}');
      print('❌ [IssueReportApiService] Response data: ${error.response?.data}');
      
      final status = error.response?.statusCode;
      final data = error.response?.data;

      String message = "Something went wrong";
      Map<String, List<String>>? errors;

      // Handle different DioException types
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        message = 'Connection timeout. Please check your internet connection.';
      } else if (error.type == DioExceptionType.connectionError) {
        message = 'No internet connection. Please check your network.';
      } else if (status == 401) {
        message = 'Unauthorized. Please login again.';
      } else if (status == 404) {
        message = 'Ticket not found.';
      } else if (status == 500) {
        message = 'Server error. Please try again later.';
      } else if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          message = data['message'] as String;
        }

        if (data['errors'] != null && data['errors'] is Map) {
          errors = {};
          (data['errors'] as Map).forEach((key, value) {
            errors![key] = List<String>.from(value.map((e) => e.toString()));
          });
        }

        if (errors != null && errors.isNotEmpty) {
          message = errors.entries
              .map((e) => "${e.key.toUpperCase()}: ${e.value.join(', ')}")
              .join("\n");
        }
      } else if (error.message != null) {
        message = error.message!;
      }

      print('❌ [IssueReportApiService] Final error message: $message');
      print('❌ [IssueReportApiService] ========== DIO EXCEPTION END ==========');
      
      throw ApiException(message, statusCode: status, errors: errors);
    } catch (e) {
      print('❌ [IssueReportApiService] ========== UNEXPECTED ERROR ==========');
      print('❌ [IssueReportApiService] Unexpected error: $e');
      print('❌ [IssueReportApiService] Error type: ${e.runtimeType}');
      print('❌ [IssueReportApiService] ========== UNEXPECTED ERROR END ==========');
      throw ApiException('Unable to fetch ticket status: ${e.toString()}');
    }
  }

  /// Get all tickets for the current user
  Future<List<Ticket>> getAllTickets(String token) async {
    try {
      print('🔵 [IssueReportApiService] ========== getAllTickets START ==========');
      print('🔵 [IssueReportApiService] Fetching all tickets for user');
      
      final response = await _dio.get(
        ApiConfig.tickets,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ [IssueReportApiService] Response Status: ${response.statusCode}');
      print('✅ [IssueReportApiService] Response Data: ${response.data}');
      
      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final dataMap = data['data'] as Map<String, dynamic>?;
        final ticketsList = (dataMap?['tickets'] as List<dynamic>? ?? <dynamic>[]);
        
        final tickets = ticketsList
            .whereType<Map<String, dynamic>>()
            .map((ticketJson) => Ticket.fromJson(ticketJson))
            .toList();
        
        print('✅ [IssueReportApiService] Fetched ${tickets.length} tickets');
        print('✅ [IssueReportApiService] ========== getAllTickets SUCCESS ==========');
        return tickets;
      }
      
      throw ApiException(data['message'] as String? ?? 'Unable to fetch tickets');
    } on DioException catch (error) {
      print('❌ [IssueReportApiService] DioException: ${error.message}');
      final status = error.response?.statusCode;
      final data = error.response?.data;

      String message = "Something went wrong";
      if (data is Map<String, dynamic> && data['message'] != null) {
        message = data['message'] as String;
      } else if (error.message != null) {
        message = error.message!;
      }

      throw ApiException(message, statusCode: status);
    } catch (e) {
      print('❌ [IssueReportApiService] Unexpected error: $e');
      throw ApiException('Unable to fetch tickets: ${e.toString()}');
    }
  }

  /// Get driver location for a specific ticket
  Future<DriverLocationResponse> getDriverLocation(String token, int ticketId) async {
    try {
      print('🔵 [IssueReportApiService] ========== getDriverLocation START ==========');
      print('🔵 [IssueReportApiService] Ticket ID: $ticketId');
      
      final url = '${ApiConfig.driverLocation}/$ticketId/driver';
      final fullUrl = '${ApiConfig.baseUrl}$url';
      print('🔵 [IssueReportApiService] Request URL: $fullUrl');
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ [IssueReportApiService] Response Status: ${response.statusCode}');
      print('✅ [IssueReportApiService] Response Data: ${response.data}');
      print('✅ [IssueReportApiService] ========== getDriverLocation SUCCESS ==========');
      
      return DriverLocationResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      print('❌ [IssueReportApiService] ========== DIO EXCEPTION ==========');
      print('❌ [IssueReportApiService] DioException type: ${error.type}');
      print('❌ [IssueReportApiService] DioException message: ${error.message}');
      print('❌ [IssueReportApiService] Status code: ${error.response?.statusCode}');
      print('❌ [IssueReportApiService] Response data: ${error.response?.data}');
      print('❌ [IssueReportApiService] ========== DIO EXCEPTION END ==========');
      
      final status = error.response?.statusCode;
      final data = error.response?.data;

      String message = "Unable to fetch driver location";
      if (data is Map<String, dynamic> && data['message'] != null) {
        message = data['message'] as String;
      } else if (error.message != null) {
        message = error.message!;
      }

      throw ApiException(message, statusCode: status);
    } catch (e) {
      print('❌ [IssueReportApiService] ========== UNEXPECTED ERROR ==========');
      print('❌ [IssueReportApiService] Unexpected error: $e');
      print('❌ [IssueReportApiService] Error type: ${e.runtimeType}');
      print('❌ [IssueReportApiService] ========== UNEXPECTED ERROR END ==========');
      throw ApiException('Unable to fetch driver location: ${e.toString()}');
    }
  }

  /// Download invoice PDF for a ticket
  Future<List<int>> downloadInvoice(String token, int ticketId) async {
    try {
      print('🔵 [IssueReportApiService] ========== downloadInvoice START ==========');
      print('🔵 [IssueReportApiService] Ticket ID: $ticketId');
      
      final url = ApiConfig.invoiceDownload(ticketId);
      final fullUrl = '${ApiConfig.baseUrl}$url';
      print('🔵 [IssueReportApiService] Request URL: $fullUrl');
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/pdf',
          },
          responseType: ResponseType.bytes,
        ),
      );

      print('✅ [IssueReportApiService] Response Status: ${response.statusCode}');
      print('✅ [IssueReportApiService] PDF size: ${(response.data as List<int>).length} bytes');
      print('✅ [IssueReportApiService] ========== downloadInvoice SUCCESS ==========');
      
      return response.data as List<int>;
    } on DioException catch (error) {
      print('❌ [IssueReportApiService] DioException: ${error.message}');
      final status = error.response?.statusCode;
      final data = error.response?.data;

      String message = "Unable to download invoice";
      
      // Handle 404 specifically - invoice not found
      if (status == 404) {
        message = "Invoice not available for this ticket. It may not have been generated yet.";
      } else if (data is Map<String, dynamic> && data['message'] != null) {
        message = data['message'] as String;
      } else if (error.message != null) {
        message = error.message!;
      }

      throw ApiException(message, statusCode: status);
    } catch (e) {
      print('❌ [IssueReportApiService] Unexpected error: $e');
      throw ApiException('Unable to download invoice: ${e.toString()}');
    }
  }

  /// Validate redeem code
  Future<RedeemCodeValidationResponse> validateRedeemCode(
    String token,
    String redeemCode,
  ) async {
    try {
      print('🔵 [IssueReportApiService] ========== validateRedeemCode START ==========');
      print('🔵 [IssueReportApiService] Redeem code: $redeemCode');
      
      final response = await _dio.post(
        ApiConfig.validateRedeemCode,
        data: {
          'code': redeemCode,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ [IssueReportApiService] Response Status: ${response.statusCode}');
      print('✅ [IssueReportApiService] Response Data: ${response.data}');
      print('✅ [IssueReportApiService] ========== validateRedeemCode SUCCESS ==========');
      
      return RedeemCodeValidationResponse.fromJson(response.data);
    } on DioException catch (error) {
      print('❌ [IssueReportApiService] DioException: ${error.message}');
      final status = error.response?.statusCode;
      final data = error.response?.data;

      String message = "Something went wrong";
      if (data is Map<String, dynamic> && data['message'] != null) {
        message = data['message'] as String;
      } else if (error.message != null) {
        message = error.message!;
      }

      throw ApiException(message, statusCode: status);
    } catch (e) {
      print('❌ [IssueReportApiService] Unexpected error: $e');
      throw ApiException('Unable to validate redeem code: ${e.toString()}');
    }
  }
}
