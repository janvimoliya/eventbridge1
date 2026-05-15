import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/user_provider.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket});

  final UserTicket ticket;

  Widget _buildQrCodeWidget(BuildContext context) {
    // Simplified QR code display: show a placeholder since QrImageView
    // can crash with certain payloads. Use a simple icon instead.
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code, size: 32),
          const SizedBox(height: 4),
          Text('QR', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.eventTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Holder: ${ticket.holderName}'),
                  Text('Type: ${ticket.ticketType} x${ticket.quantity}'),
                  Text(
                    DateFormat(
                      'EEE, d MMM y • hh:mm a',
                    ).format(ticket.eventDate),
                  ),
                ],
              ),
            ),
            _buildQrCodeWidget(context),
          ],
        ),
      ),
    );
  }
}
