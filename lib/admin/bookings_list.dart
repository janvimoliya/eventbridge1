import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/event_service.dart';

class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({super.key, this.isTab = false});

  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EventService>();
    final dateFormat = DateFormat('dd MMM');

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bookings Management',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('User Name')),
              DataColumn(label: Text('Event Name')),
              DataColumn(label: Text('Tickets')),
              DataColumn(label: Text('Amount ₹')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Actions')),
            ],
            rows: service.bookings
                .map(
                  (booking) => DataRow(
                    cells: [
                      DataCell(Text(booking.userName)),
                      DataCell(Text(booking.eventName)),
                      DataCell(Text('${booking.tickets}')),
                      DataCell(Text('₹${booking.amount.toStringAsFixed(0)}')),
                      DataCell(Text(booking.paymentStatus)),
                      DataCell(Text(dateFormat.format(booking.date))),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Cancel',
                              onPressed: booking.isCancelled
                                  ? null
                                  : () async {
                                      try {
                                        await service.cancelBooking(booking.id);
                                      } catch (error) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to cancel booking: $error',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                            ),
                            IconButton(
                              icon: const Icon(Icons.currency_rupee_rounded),
                              tooltip: 'Refund',
                              onPressed: booking.isRefunded
                                  ? null
                                  : () async {
                                      try {
                                        await service.refundBooking(booking.id);
                                      } catch (error) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to refund booking: $error',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_rounded),
                              tooltip: 'View QR',
                              onPressed: () => _showQr(context, booking.qrData),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );

    if (service.bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookings')),
        body: Center(
          child: Text(
            'No bookings yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    if (isTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: content,
    );
  }

  Future<void> _showQr(BuildContext context, String qrData) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ticket QR'),
        content: QrImageView(data: qrData, size: 180),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
