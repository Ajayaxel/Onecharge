import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/ticket_response.dart';

class IssueReportApiService {
  IssueReportApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<TicketResponse> submitIssueReport({
    required String category,
    String? otherText,
    String? mediaPath,
  }) async {
    print('🔵 [IssueReportApiService] submitIssueReport called');

    try {
      /// Get token
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Please login to continue.', statusCode: 401);
      }
      print('✅ Token loaded');

      /// Build FormData
      final formDataMap = <String, dynamic>{
        'category': category,
      };

      if (otherText != null && otherText.trim().isNotEmpty) {
        formDataMap['other_text'] = otherText.trim();
      }

      /// FIXED MEDIA HANDLING — EXACT LIKE POSTMAN
      if (mediaPath != null && mediaPath.trim().isNotEmpty) {
        final file = File(mediaPath);

        if (!await file.exists()) {
          throw ApiException('Selected media file not found.', statusCode: 400);
        }

        /// Keep original filename (VERY IMPORTANT)
        final originalFileName = mediaPath.split('/').last;

        print('📎 Preparing media: $originalFileName');

        /// Do NOT set contentType
        /// Do NOT use bytes
        formDataMap['media'] = await MultipartFile.fromFile(
          file.path,
          filename: originalFileName,
        );

        print('✅ Media attached to FormData');
      }

      final formData = FormData.fromMap(formDataMap);

      /// Log form data
      formData.fields.forEach((e) {
        print("📋 field => ${e.key}: ${e.value}");
      });
      formData.files.forEach((e) {
        print("📎 file => ${e.key}: ${e.value.filename}");
      });

      /// Send request
      final response = await _dio.post(
        ApiConfig.tickets,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      print('✅ Response: ${response.statusCode}');
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
}
