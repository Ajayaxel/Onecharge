import 'package:flutter/material.dart';
import 'package:onecharge/const/onebtn.dart';
import 'package:onecharge/resources/app_resources.dart';
import 'package:onecharge/features/issue_report/data/models/ticket_response.dart';
import 'package:onecharge/screen/issue_report/issue_status_screen.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    this.isSuccess = true,
    this.message,
    this.ticket,
  });

  final bool isSuccess;
  final String? message;
  final Ticket? ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon (Checkmark for success, Error for failure)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSuccess ? Colors.green : Colors.red,
                    width: 3,
                  ),
                ),
                child: Icon(
                  isSuccess ? Icons.check : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                isSuccess ? 'Successful' : 'Error',
                style: const TextStyle(
                  color: AppColors.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Ticket ID (only for success with ticket)
              if (isSuccess && ticket != null && ticket!.ticketId.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ticket ID',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket!.ticketId,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  message ??
                      (isSuccess
                          ? 'Service ticket created successfully'
                          : 'Something went wrong. Please try again.'),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Done Button
              if (isSuccess && ticket != null)
                OneBtn(
                  text: 'Done',
                  onPressed: () {
                    print('🟡 [SuccessScreen] Navigating to IssueStatusScreen');
                    print('🟡 [SuccessScreen] Ticket ID: "${ticket!.ticketId}"');
                    print('🟡 [SuccessScreen] Ticket ID is empty: ${ticket!.ticketId.isEmpty}');
                    
                    if (ticket!.ticketId.isEmpty) {
                      print('❌ [SuccessScreen] ERROR: Ticket ID is empty!');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error: Ticket ID is missing. Please contact support.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => IssueStatusScreen(
                          ticketIdInt: ticket!.id, // Use numerical ID, not string ticket_id
                          initialTicket: ticket, // Pass the ticket data we already have
                        ),
                      ),
                    );
                  },
                )
              else
                OneBtn(
                  text: isSuccess ? 'Done' : 'Go Back',
                  onPressed: () {
                    if (isSuccess) {
                      print('🟡 [SuccessScreen] Navigating to IssueStatusScreen (fallback)');
                      print('🟡 [SuccessScreen] Ticket: ${ticket?.ticketId ?? "null"}');
                      
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => IssueStatusScreen(
                            ticketIdInt: ticket?.id, // Use numerical ID, not string ticket_id
                            initialTicket: ticket, // Pass the ticket data we already have
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

