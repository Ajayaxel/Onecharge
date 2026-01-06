import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/api_exception.dart';
import '../../data/models/ticket_response.dart';
import '../../data/models/create_ticket_request.dart';
import '../../data/models/redeem_code_validation_response.dart';
import '../../data/repositories/issue_report_repository.dart';

part 'issue_report_event.dart';
part 'issue_report_state.dart';

class IssueReportBloc extends Bloc<IssueReportEvent, IssueReportState> {
  IssueReportBloc(this._repository) : super(const IssueReportState()) {
    on<IssueReportSubmitted>(_onIssueReportSubmitted);
    on<CreateTicketSubmitted>(_onCreateTicketSubmitted);
    on<FileUploadProgress>(_onFileUploadProgress);
    on<ValidateRedeemCode>(_onValidateRedeemCode);
  }

  final IssueReportRepository _repository;
  Timer? _uploadTimer;
  DateTime? _uploadStartTime;

  @override
  Future<void> close() {
    _uploadTimer?.cancel();
    _uploadStartTime = null;
    return super.close();
  }

  Future<void> _onIssueReportSubmitted(
    IssueReportSubmitted event,
    Emitter<IssueReportState> emit,
  ) async {
    print('🟡 [IssueReportBloc] ========== _onIssueReportSubmitted START ==========');
    print('🟡 [IssueReportBloc] Event received');
    print('🟡 [IssueReportBloc] issueCategoryId: ${event.issueCategoryId}');
    print('🟡 [IssueReportBloc] vehicleTypeId: ${event.vehicleTypeId}');
    print('🟡 [IssueReportBloc] brandId: ${event.brandId}');
    print('🟡 [IssueReportBloc] modelId: ${event.modelId}');
    print('🟡 [IssueReportBloc] location: ${event.location}');
    print('🟡 [IssueReportBloc] latitude: ${event.latitude}, longitude: ${event.longitude}');
    print('🟡 [IssueReportBloc] numberPlate: ${event.numberPlate}');
    print('🟡 [IssueReportBloc] description: ${event.description}');
    print('🟡 [IssueReportBloc] Media paths: ${event.mediaPaths?.length ?? 0}');
    
    emit(
      state.copyWith(
        status: IssueReportStatus.loading,
        clearMessage: true,
      ),
    );
    print('🟡 [IssueReportBloc] State changed to: loading');
    
    try {
      print('🟡 [IssueReportBloc] Calling repository...');
      
      // Use CreateTicketRequest if numberPlate is provided, otherwise use legacy method
      TicketResponse response;
      if (event.numberPlate != null && event.numberPlate!.isNotEmpty) {
        print('🟡 [IssueReportBloc] Using CreateTicketRequest with number plate');
        // Pass file paths directly to match API requirements
        final request = CreateTicketRequest(
          issueCategoryId: event.issueCategoryId,
          vehicleTypeId: event.vehicleTypeId,
          brandId: event.brandId,
          modelId: event.modelId,
          numberPlate: event.numberPlate!,
          location: event.location,
          latitude: event.latitude,
          longitude: event.longitude,
          description: event.description,
          attachments: event.mediaPaths, // Pass file paths directly
          redeemCode: event.redeemCode,
        );
        response = await _repository.createTicket(request);
      } else {
        print('🟡 [IssueReportBloc] Using legacy submitIssueReport method');
        // Pass file paths directly to match API requirements
        response = await _repository.submitIssueReport(
          issueCategoryId: event.issueCategoryId,
          vehicleTypeId: event.vehicleTypeId,
          brandId: event.brandId,
          modelId: event.modelId,
          location: event.location,
          latitude: event.latitude,
          longitude: event.longitude,
          attachments: event.mediaPaths, // Pass file paths directly
        );
      }
      print('✅ [IssueReportBloc] Repository call successful');
      print('✅ [IssueReportBloc] Response success: ${response.success}');
      print('✅ [IssueReportBloc] Response message: ${response.message}');
      print('✅ [IssueReportBloc] Ticket ID: ${response.ticket.id}');
      print('✅ [IssueReportBloc] Ticket ID (ticket_id): ${response.ticket.ticketId}');
      print('✅ [IssueReportBloc] Ticket status: ${response.ticket.status}');
      
      emit(
        state.copyWith(
          status: IssueReportStatus.success,
          ticket: response.ticket,
          message: response.message,
          paymentRequired: response.paymentRequired,
          paymentUrl: response.paymentUrl,
        ),
      );
      print('✅ [IssueReportBloc] State changed to: success');
      print('✅ [IssueReportBloc] ========== _onIssueReportSubmitted SUCCESS ==========');
    } on ApiException catch (error) {
      _uploadTimer?.cancel();
      _uploadStartTime = null;
      print('❌ [IssueReportBloc] ApiException caught: ${error.message}');
      print('❌ [IssueReportBloc] Status code: ${error.statusCode}');
      print('❌ [IssueReportBloc] Errors: ${error.errors}');
      emit(
        state.copyWith(
          status: IssueReportStatus.failure,
          message: error.message,
          statusCode: error.statusCode,
          errors: error.errors,
        ),
      );
      print('❌ [IssueReportBloc] State changed to: failure');
    } catch (e, stackTrace) {
      _uploadTimer?.cancel();
      _uploadStartTime = null;
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

  Future<void> _onCreateTicketSubmitted(
    CreateTicketSubmitted event,
    Emitter<IssueReportState> emit,
  ) async {
    print('🟡 [IssueReportBloc] ========== _onCreateTicketSubmitted START ==========');
    print('🟡 [IssueReportBloc] Event received');
    print('🟡 [IssueReportBloc] issueCategoryId: ${event.issueCategoryId}');
    print('🟡 [IssueReportBloc] vehicleTypeId: ${event.vehicleTypeId}');
    print('🟡 [IssueReportBloc] brandId: ${event.brandId}');
    print('🟡 [IssueReportBloc] modelId: ${event.modelId}');
    print('🟡 [IssueReportBloc] numberPlate: ${event.numberPlate}');
    print('🟡 [IssueReportBloc] location: ${event.location}');
    print('🟡 [IssueReportBloc] latitude: ${event.latitude}, longitude: ${event.longitude}');
    print('🟡 [IssueReportBloc] description: ${event.description}');
    print('🟡 [IssueReportBloc] Media paths: ${event.mediaPaths?.length ?? 0}');
    
    emit(
      state.copyWith(
        status: IssueReportStatus.uploading,
        clearMessage: true,
        clearUploadProgress: true,
        elapsedSeconds: 0,
      ),
    );
    print('🟡 [IssueReportBloc] State changed to: uploading');
    
    // Start timer for tracking upload duration
    _uploadStartTime = DateTime.now();
    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isClosed && _uploadStartTime != null && state.status == IssueReportStatus.uploading) {
        final elapsed = DateTime.now().difference(_uploadStartTime!).inSeconds;
        emit(
          state.copyWith(
            elapsedSeconds: elapsed,
          ),
        );
      } else {
        timer.cancel();
      }
    });
    
    try {
      // Files will be sent directly in the ticket creation request
      // Change status to loading for ticket creation (which includes file upload)
      _uploadTimer?.cancel();
      _uploadStartTime = null;
      emit(
        state.copyWith(
          status: IssueReportStatus.loading,
          clearUploadProgress: true,
          clearCurrentFileProgress: true,
          currentFileName: null,
        ),
      );

      print('🟡 [IssueReportBloc] Creating ticket with files...');
      // Pass file paths directly to match API requirements
      // The API service will handle sending files as MultipartFile
      final request = CreateTicketRequest(
        issueCategoryId: event.issueCategoryId,
        vehicleTypeId: event.vehicleTypeId,
        brandId: event.brandId,
        modelId: event.modelId,
        numberPlate: event.numberPlate,
        location: event.location,
        latitude: event.latitude,
        longitude: event.longitude,
        description: event.description,
        attachments: event.mediaPaths, // Pass file paths directly
        redeemCode: event.redeemCode,
      );
      
      final response = await _repository.createTicket(request);
      print('✅ [IssueReportBloc] Repository call successful');
      print('✅ [IssueReportBloc] Response success: ${response.success}');
      print('✅ [IssueReportBloc] Response message: ${response.message}');
      print('✅ [IssueReportBloc] Payment required: ${response.paymentRequired}');
      print('✅ [IssueReportBloc] Payment URL: ${response.paymentUrl}');
      print('✅ [IssueReportBloc] Ticket ID: ${response.ticket.id}');
      print('✅ [IssueReportBloc] Ticket ID (ticket_id): ${response.ticket.ticketId}');
      print('✅ [IssueReportBloc] Ticket status: ${response.ticket.status}');
      
      emit(
        state.copyWith(
          status: IssueReportStatus.success,
          ticket: response.ticket,
          message: response.message,
          paymentRequired: response.paymentRequired,
          paymentUrl: response.paymentUrl,
        ),
      );
      print('✅ [IssueReportBloc] State changed to: success');
      print('✅ [IssueReportBloc] ========== _onCreateTicketSubmitted SUCCESS ==========');
    } on ApiException catch (error) {
      _uploadTimer?.cancel();
      _uploadStartTime = null;
      print('❌ [IssueReportBloc] ApiException caught: ${error.message}');
      print('❌ [IssueReportBloc] Status code: ${error.statusCode}');
      print('❌ [IssueReportBloc] Errors: ${error.errors}');
      emit(
        state.copyWith(
          status: IssueReportStatus.failure,
          message: error.message,
          statusCode: error.statusCode,
          errors: error.errors,
        ),
      );
      print('❌ [IssueReportBloc] State changed to: failure');
    } catch (e, stackTrace) {
      _uploadTimer?.cancel();
      _uploadStartTime = null;
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

  void _onFileUploadProgress(
    FileUploadProgress event,
    Emitter<IssueReportState> emit,
  ) {
    emit(
      state.copyWith(
        status: IssueReportStatus.uploading,
        uploadProgress: event.progress,
        currentUploadingFile: event.fileIndex,
        totalFiles: event.totalFiles,
      ),
    );
  }

  Future<void> _onValidateRedeemCode(
    ValidateRedeemCode event,
    Emitter<IssueReportState> emit,
  ) async {
    print('🟡 [IssueReportBloc] ========== _onValidateRedeemCode START ==========');
    print('🟡 [IssueReportBloc] Validating redeem code: ${event.redeemCode}');
    
    emit(
      state.copyWith(
        isValidatingCoupon: true,
        couponValidated: false,
        couponValidationError: null,
        couponValidationData: null,
      ),
    );

    try {
      final response = await _repository.validateRedeemCode(event.redeemCode);
      
      print('✅ [IssueReportBloc] Validation successful');
      print('✅ [IssueReportBloc] Valid: ${response.data.valid}');
      print('✅ [IssueReportBloc] Discount amount: ${response.data.discountAmount}');
      
      if (response.success && response.data.valid) {
        emit(
          state.copyWith(
            isValidatingCoupon: false,
            couponValidated: true,
            couponValidationError: null,
            couponValidationData: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isValidatingCoupon: false,
            couponValidated: false,
            couponValidationError: response.message,
            couponValidationData: null,
          ),
        );
      }
    } on ApiException catch (error) {
      print('❌ [IssueReportBloc] ApiException: ${error.message}');
      emit(
        state.copyWith(
          isValidatingCoupon: false,
          couponValidated: false,
          couponValidationError: error.message,
          couponValidationData: null,
        ),
      );
    } catch (e) {
      print('❌ [IssueReportBloc] Unexpected error: $e');
      emit(
        state.copyWith(
          isValidatingCoupon: false,
          couponValidated: false,
          couponValidationError: 'Failed to validate coupon code. Please try again.',
          couponValidationData: null,
        ),
      );
    }
    
    print('✅ [IssueReportBloc] ========== _onValidateRedeemCode END ==========');
  }
}

