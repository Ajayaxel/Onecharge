import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/features/issue_report/data/repositories/issue_report_repository.dart';
import 'package:onecharge/features/issue_report/data/models/ticket_response.dart';
import 'package:onecharge/core/error/api_exception.dart';

class IssueStatusScreen extends StatefulWidget {
  const IssueStatusScreen({
    super.key,
    this.ticketId, // Numerical ID (int) - deprecated, use ticketIdInt instead
    this.ticketIdInt, // Numerical ID (int) - preferred
    this.initialTicket,
  });

  final String? ticketId; // Deprecated - kept for backward compatibility
  final int? ticketIdInt; // Numerical ID from ticket.id
  final Ticket? initialTicket; // Use ticket data from creation response

  @override
  State<IssueStatusScreen> createState() => _IssueStatusScreenState();
}

class _IssueStatusScreenState extends State<IssueStatusScreen> {
  final IssueReportRepository _repository = IssueReportRepository();
  Timer? _statusTimer;
  Ticket? _currentTicket;
  bool _isLoading = true;
  String? _errorMessage;
  String? _previousStatus; // Track previous status to detect changes
  bool _hasStatusChanged = false; // Flag to show status change notification
  
  int _currentStage = 0; // 0: We received, 1: Partner Assigned, 2: Issue Resolved

  @override
  void initState() {
    super.initState();
    
    // Get the numerical ID from initialTicket or ticketIdInt
    final numericalId = widget.ticketIdInt ?? widget.initialTicket?.id;
    
    // If we have initial ticket data, use it immediately
    if (widget.initialTicket != null) {
      print('✅ [IssueStatusScreen] Using initial ticket data');
      print('✅ [IssueStatusScreen] Initial status: ${widget.initialTicket!.status}');
      print('✅ [IssueStatusScreen] Ticket numerical ID: ${widget.initialTicket!.id}');
      _currentTicket = widget.initialTicket;
      _previousStatus = widget.initialTicket!.status;
      _updateStageFromStatus(widget.initialTicket!.status);
      _isLoading = false;
    } else if (numericalId != null && numericalId > 0) {
      // Only fetch once on initial load if we don't have initial ticket data
      // Wait 2 seconds to give database time to sync
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _fetchTicketStatus();
        }
      });
    } else {
      _isLoading = false;
      _errorMessage = 'No ticket ID provided';
    }
    
    // Start automatic polling every 2 minutes to check for status updates
    // Stop polling if status is already completed
    if (numericalId != null && numericalId > 0) {
      // Only start polling if initial status is not completed
      if (widget.initialTicket == null || 
          (!widget.initialTicket!.status.toLowerCase().contains('resolved') &&
           !widget.initialTicket!.status.toLowerCase().contains('closed') &&
           widget.initialTicket!.status.toLowerCase() != 'completed')) {
        _statusTimer = Timer.periodic(const Duration(minutes: 2), (_) {
          if (mounted) {
            // Check if current status is completed before polling
            final currentStatus = _currentTicket?.status.toLowerCase() ?? '';
            if (currentStatus.contains('resolved') || 
                currentStatus.contains('closed') || 
                currentStatus == 'completed') {
              // Stop polling if completed
              _statusTimer?.cancel();
              return;
            }
            _fetchTicketStatus(silent: true); // Silent fetch to avoid showing loading
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTicketStatus({bool silent = false}) async {
    // Get numerical ID from ticketIdInt or initialTicket
    final numericalId = widget.ticketIdInt ?? widget.initialTicket?.id;
    
    if (numericalId == null || numericalId <= 0) {
      print('⚠️ [IssueStatusScreen] No ticket numerical ID provided');
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No ticket ID provided';
        });
      }
      return;
    }
    
    try {
      if (!silent) {
        print('🟡 [IssueStatusScreen] ========== Fetching Ticket Status ==========');
        print('🟡 [IssueStatusScreen] Ticket numerical ID: $numericalId');
        print('🟡 [IssueStatusScreen] Calling repository...');
      }
      
      final response = await _repository.getTicketById(numericalId);
      
      if (mounted) {
        final newStatus = response.ticket.status;
        final statusChanged = _previousStatus != null && _previousStatus != newStatus;
        
        setState(() {
          _currentTicket = response.ticket;
          if (!silent) {
            _isLoading = false;
          }
          _errorMessage = null;
          
          // Detect status change
          if (statusChanged && _previousStatus != null) {
            _hasStatusChanged = true;
            // Auto-hide notification after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _hasStatusChanged = false;
                });
              }
            });
          }
          
          _previousStatus = newStatus;
          _updateStageFromStatus(newStatus);
        });
        
        // Stop polling if status is completed
        final lowerStatus = newStatus.toLowerCase();
        if (lowerStatus.contains('resolved') || 
            lowerStatus.contains('closed') || 
            lowerStatus == 'completed') {
          _statusTimer?.cancel();
          _statusTimer = null;
        }
        
        // Check if completed and auto-navigate
        _checkAndNavigateIfCompleted(newStatus);
        
        if (!silent) {
          print('✅ [IssueStatusScreen] Ticket status updated: $newStatus');
          print('✅ [IssueStatusScreen] Ticket ID from API: ${response.ticket.ticketId}');
          print('✅ [IssueStatusScreen] ========== Fetch Success ==========');
        } else if (statusChanged) {
          print('🔄 [IssueStatusScreen] Status changed from $_previousStatus to $newStatus');
        }
      }
    } on ApiException catch (e) {
      // Only show errors if not silent mode
      if (!silent) {
        print('❌ [IssueStatusScreen] ========== API EXCEPTION ==========');
        print('❌ [IssueStatusScreen] Error message: ${e.message}');
        print('❌ [IssueStatusScreen] Status code: ${e.statusCode}');
        final numericalId = widget.ticketIdInt ?? widget.initialTicket?.id;
        print('❌ [IssueStatusScreen] Ticket numerical ID used: $numericalId');
        print('❌ [IssueStatusScreen] ========== API EXCEPTION END ==========');
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message.isNotEmpty 
                ? e.message 
                : 'Failed to fetch ticket status. Please try again.';
          });
        }
      }
    } catch (e) {
      // Only show errors if not silent mode
      if (!silent) {
        print('❌ [IssueStatusScreen] ========== UNEXPECTED ERROR ==========');
        print('❌ [IssueStatusScreen] Unexpected error: $e');
        print('❌ [IssueStatusScreen] Error type: ${e.runtimeType}');
        final numericalId = widget.ticketIdInt ?? widget.initialTicket?.id;
        print('❌ [IssueStatusScreen] Ticket numerical ID used: $numericalId');
        print('❌ [IssueStatusScreen] ========== UNEXPECTED ERROR END ==========');
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to fetch ticket status. Please try again.';
          });
        }
      }
    }
  }

  void _updateStageFromStatus(String status) {
    // Map API status to UI stages
    // Common statuses: pending, in_progress, assigned, resolved, closed
    final lowerStatus = status.toLowerCase();
    
    if (lowerStatus.contains('resolved') || lowerStatus.contains('closed') || lowerStatus == 'completed') {
      _currentStage = 2;
    } else if (lowerStatus.contains('assigned') || lowerStatus.contains('partner') || lowerStatus == 'in_progress') {
      _currentStage = 1;
    } else {
      _currentStage = 0; // pending, received, etc.
    }
  }

  void _checkAndNavigateIfCompleted(String status) {
    // Auto-navigate if status is completed
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('resolved') || lowerStatus.contains('closed') || lowerStatus == 'completed') {
      // Wait a moment to show the completed status, then navigate
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Issue Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),
              const SizedBox(height: 40),
              
              // Main Illustration
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Image.asset(
                          _getImageForStage(),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status Change Notification
              if (_hasStatusChanged) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Status updated!',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Status Text
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              
              // Show real-time status from API
              if (_currentTicket != null && _currentTicket!.status.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated status indicator
                      if (_hasStatusChanged)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                      Text(
                        'Status: ${_currentTicket!.status.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Action Button - Always Refresh (except when completed, it will auto-navigate)
              SizedBox(
                width: double.infinity,
                child: _currentStage == 2
                    ? OneBtn(
                        text: 'Done',
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      )
                    : OneBtn(
                        text: _isLoading ? 'Loading...' : 'Refresh',
                        onPressed: _isLoading ? null : _fetchTicketStatus,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step 1: We received
        _buildStep(
          stepNumber: 1,
          label: 'We received',
          isActive: _currentStage >= 0,
          isCompleted: _currentStage > 0,
        ),
        _buildConnector(isActive: _currentStage > 0),
        
        // Step 2: Partner Assigned
        _buildStep(
          stepNumber: 2,
          label: 'Partner Assigned',
          isActive: _currentStage >= 1,
          isCompleted: _currentStage > 1,
        ),
        _buildConnector(isActive: _currentStage > 1),
        
        // Step 3: Issue Resolved / Real-time Status
        _buildStep(
          stepNumber: 3,
          label: _currentStage >= 2 
              ? (_currentTicket?.status != null && _currentTicket!.status.isNotEmpty
                  ? _currentTicket!.status.toUpperCase()
                  : 'Issue Resolved')
              : '',
          isActive: _currentStage >= 2,
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.black : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? Colors.black : Colors.grey.shade300,
    );
  }

  String _getImageForStage() {
    switch (_currentStage) {
      case 0:
        return 'assets/issue/Group 1000005867.png';
      case 1:
        return 'assets/issue/Group 1000005868.png';
      case 2:
        return 'assets/issue/Group 1000005869.png';
      default:
        return 'assets/issue/Group 1000005867.png';
    }
  }

  String _getStatusText() {
    // If we have real-time status from API, use it
    if (_currentTicket != null && _currentTicket!.status.isNotEmpty) {
      final status = _currentTicket!.status.toLowerCase();
      if (status.contains('resolved') || status.contains('closed') || status == 'completed') {
        return 'All the issues you mentioned have been resolved';
      } else if (status.contains('assigned') || status.contains('partner') || status == 'in_progress') {
        return 'The Partner we assigned has already reached your location and he will contact you.';
      } else {
        return 'We have received your issue. For the next stage, we have assigned a partner to resolve it.';
      }
    }
    
    // Fallback to stage-based text
    switch (_currentStage) {
      case 0:
        return 'We have received your issue. For the next stage, we have assigned a partner to resolve it.';
      case 1:
        return 'The Partner we assigned has already reached your location and he will contact you.';
      case 2:
        return 'All the issues you mentioned have been resolved';
      default:
        return '';
    }
  }
}

