import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/event_provider.dart';
import '../providers/user_provider.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_button.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _paymentService = PaymentService();

  String? _ticketType;
  int _quantity = 1;
  String _paymentMethod = 'UPI';
  bool _paymentConfirmed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _payAndGenerateTicket() async {
    final event = context.read<EventProvider>().findById(widget.eventId);

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_ticketType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a ticket type.')));
      return;
    }

    setState(() => _isLoading = true);

    final ticketPrice = event.ticketTypes[_ticketType!]! * _quantity;
    final result = await _paymentService.processPayment(
      amount: ticketPrice,
      method: _paymentMethod,
      isConfirmed: _paymentConfirmed,
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      setState(() => _isLoading = false);
      return;
    }

    final userProvider = context.read<UserProvider>();
    final spent = userProvider.spendFromWallet(
      amount: ticketPrice,
      title: 'Ticket Purchase - ${event.title}',
    );

    if (!spent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient wallet balance. Please top up wallet.'),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final ticket = UserTicket(
      id: result.transactionId,
      eventId: event.id,
      eventTitle: event.title,
      holderName: _nameController.text.trim(),
      ticketType: _ticketType!,
      quantity: _quantity,
      amount: ticketPrice,
      eventDate: event.date,
    );

    userProvider.addTicket(ticket, event.category);
    userProvider.addNotification(
      AppNotificationModel(
        title: 'Booking Confirmation',
        message: 'Your ticket for ${event.title} is ready. QR code generated.',
        timestamp: DateTime.now(),
        type: 'confirmation',
      ),
    );

    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ticket Generated'),
        content: Text('Payment successful. Ticket ID: ${result.transactionId}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final event = context.read<EventProvider>().findById(widget.eventId);

    return Scaffold(
      appBar: AppBar(title: const Text('Book Tickets')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(event.location),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty ||
                        !RegExp(r'^[A-Za-z\s]+$').hasMatch(name)) {
                      return 'Name must be alphabetic and non-empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                      return 'Phone must be 10 numeric digits.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _ticketType,
                  items: event.ticketTypes.keys
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _ticketType = value),
                  decoration: const InputDecoration(labelText: 'Ticket Type'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '1',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) {
                    final qty = int.tryParse(value ?? '');
                    if (qty == null || qty <= 0) {
                      return 'Ticket quantity must be a positive integer.';
                    }
                    return null;
                  },
                  onChanged: (value) => _quantity = int.tryParse(value) ?? 1,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  items: const [
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(
                      value: 'Debit/Credit Card',
                      child: Text('Debit/Credit Card'),
                    ),
                    DropdownMenuItem(
                      value: 'Net Banking',
                      child: Text('Net Banking'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _paymentMethod = value ?? 'UPI'),
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _paymentConfirmed,
                  title: const Text(
                    'I confirm payment details to generate ticket.',
                  ),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) =>
                      setState(() => _paymentConfirmed = value ?? false),
                ),
                const SizedBox(height: 8),
                if (_ticketType != null)
                  Text(
                    'Payable Amount: ₹${(event.ticketTypes[_ticketType!]! * _quantity).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Pay Now',
                  icon: Icons.payment_rounded,
                  isLoading: _isLoading,
                  onPressed: _payAndGenerateTicket,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Split payment with friends and cashback offers are supported in wallet.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
