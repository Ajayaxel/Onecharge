import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/ticket_response.dart';
import '../../data/models/create_ticket_request.dart';
import '../../data/repositories/issue_report_repository.dart';

part 'issue_report_event.dart';
part 'issue_report_state.dart';

class IssueReportBloc extends Bloc<IssueReportEvent, IssueReportState> {
  IssueReportBloc(this._repository) : super(const IssueReportState()) {
    on<IssueReportSubmitted>(_onIssueReportSubmitted);
    on<CreateTicketSubmitted>(_onCreateTicketSubmitted);
    on<FileUploadProgress>(_onFileUploadProgress);
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
      // First upload files if any
      List<String>? uploadedAttachments;
      if (event.mediaPaths != null && event.mediaPaths!.isNotEmpty) {
        print('📤 [IssueReportBloc] Uploading ${event.mediaPaths!.length} files...');
        uploadedAttachments = await _repository.uploadFiles(event.mediaPaths!);
        print('✅ [IssueReportBloc] Files uploaded: ${uploadedAttachments.length}');
      }

      print('🟡 [IssueReportBloc] Calling repository...');
      
      // Use CreateTicketRequest if numberPlate is provided, otherwise use legacy method
      TicketResponse response;
      if (event.numberPlate != null && event.numberPlate!.isNotEmpty) {
        print('🟡 [IssueReportBloc] Using CreateTicketRequest with number plate');
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
          attachments: uploadedAttachments,
        );
        response = await _repository.createTicket(request);
      } else {
        print('🟡 [IssueReportBloc] Using legacy submitIssueReport method');
        response = await _repository.submitIssueReport(
          issueCategoryId: event.issueCategoryId,
          vehicleTypeId: event.vehicleTypeId,
          brandId: event.brandId,
          modelId: event.modelId,
          location: event.location,
          latitude: event.latitude,
          longitude: event.longitude,
          attachments: uploadedAttachments,
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
      // First upload files if any
      List<String>? uploadedAttachments;
      if (event.mediaPaths != null && event.mediaPaths!.isNotEmpty) {
        print('📤 [IssueReportBloc] Uploading ${event.mediaPaths!.length} files...');
        
        final token = await TokenStorage.readToken();
        if (token == null || token.isEmpty) {
          _uploadTimer?.cancel();
          throw ApiException('Please login to continue.', statusCode: 401);
        }

        uploadedAttachments = [];
        final totalFiles = event.mediaPaths!.length;
        
        for (int i = 0; i < event.mediaPaths!.length; i++) {
          final filePath = event.mediaPaths![i];
          final file = File(filePath);
          final fileName = filePath.split('/').last;
          
          if (!await file.exists()) {
            print('⚠️ [IssueReportBloc] File not found: $filePath');
            continue;
          }

          // Emit progress for current file start
          emit(
            state.copyWith(
              status: IssueReportStatus.uploading,
              currentUploadingFile: i + 1,
              totalFiles: totalFiles,
              uploadProgress: i / totalFiles, // Progress before this file
              currentFileProgress: 0.0,
              currentFileName: fileName,
            ),
          );

          try {
            // Upload file with progress tracking
            final uploadedPath = await _repository.uploadFile(
              file,
              token,
              onProgress: (sent, total) {
                // Calculate overall progress
                // Progress = (completed files + current file progress) / total files
                final fileProgress = total > 0 ? sent / total : 0.0;
                final overallProgress = (i + fileProgress) / totalFiles;
                
                // Emit progress update
                emit(
                  state.copyWith(
                    status: IssueReportStatus.uploading,
                    currentUploadingFile: i + 1,
                    totalFiles: totalFiles,
                    uploadProgress: overallProgress,
                    currentFileProgress: fileProgress,
                    currentFileName: fileName,
                  ),
                );
              },
            );
            uploadedAttachments.add(uploadedPath);
            
            // Emit progress after successful upload
            emit(
              state.copyWith(
                status: IssueReportStatus.uploading,
                currentUploadingFile: i + 1,
                totalFiles: totalFiles,
                uploadProgress: (i + 1) / totalFiles,
                currentFileProgress: 1.0,
                currentFileName: fileName,
              ),
            );
            
            print('✅ [IssueReportBloc] File ${i + 1}/$totalFiles uploaded: $uploadedPath');
          } catch (e) {
            print('❌ [IssueReportBloc] Error uploading file $filePath: $e');
            // Continue with other files even if one fails
          }
        }
        
        print('✅ [IssueReportBloc] Files uploaded: ${uploadedAttachments.length}');
      }

      // Stop timer and change status to loading for ticket creation
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

      print('🟡 [IssueReportBloc] Creating ticket...');
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
        attachments: uploadedAttachments,
      );
      
      final response = await _repository.createTicket(request);
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
}

