import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/user_provider.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket});

  final UserTicket ticket;

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
            QrImageView(
              data: ticket.qrPayload,
              size: 84,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
