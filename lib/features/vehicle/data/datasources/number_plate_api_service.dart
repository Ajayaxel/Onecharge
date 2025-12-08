import 'package:dio/dio.dart';

// ignore: unused_import
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
// ignore: unused_import
import '../../../../core/network/api_config.dart';
// ignore: unused_import
import '../../../../core/storage/token_storage.dart';
import '../models/number_plate_response.dart';

class NumberPlateApiService {
  NumberPlateApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  // ignore: unused_field
  final Dio _dio;

  Future<NumberPlateResponse> saveNumberPlate({
    required String plateNumber,
  }) async {
    // DUMMY API - Commented out actual API call
    // final token = await TokenStorage.readToken();
    // if (token == null || token.isEmpty) {
    //   throw ApiException('Please login to continue.', statusCode: 401);
    // }

    // try {
    //   final payload = {'plate_number': plateNumber, 'image': null};

    //   final response = await _dio.post(
    //     ApiConfig.numberPlate,
    //     data: payload,
    //     options: Options(
    //       headers: {
    //         'Authorization': 'Bearer $token',
    //         'Accept': 'application/json',
    //       },
    //     ),
    //   );

    //   return NumberPlateResponse.fromJson(response.data);
    // } on DioException catch (error) {
    //   final status = error.response?.statusCode;
    //   final data = error.response?.data;
    //   String message = 'Unable to save number plate.';

    //   if (data is Map<String, dynamic>) {
    //     if (data['message'] != null) {
    //       message = data['message'].toString();
    //     } else if (data['error'] != null) {
    //       message = data['error'].toString();
    //     }
    //   }

    //   throw ApiException(message, statusCode: status);
    // } catch (_) {
    //   throw ApiException('Something went wrong while saving number plate.');
    // }

    // DUMMY DATA - Return mock success response
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    return NumberPlateResponse.fromJson({
      'status': true,
      'message': 'Vehicle number plate saved successfully',
      'data': {
        'id': 1,
        'plate_number': plateNumber,
        'image': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    });
  }
}
