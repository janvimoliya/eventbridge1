import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/wallet_balance.dart';
import '../services/payment_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.isTab = false});

  static const String routeName = '/wallet';
  final bool isTab;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _topUpController = TextEditingController();
  Razorpay? _razorpay;
  double? _pendingTopUpAmount;

  Razorpay get _razorpayInstance {
    return _razorpay ??= Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void initState() {
    super.initState();
    _razorpayInstance;
  }

  @override
  void dispose() {
    _topUpController.dispose();
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _topUp() async {
    final amount = double.tryParse(_topUpController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid top-up amount.')),
      );
      return;
    }

    final user = context.read<UserProvider>().currentUser;
    _pendingTopUpAmount = amount;

    final options = {
      'key': PaymentService.razorpayKeyId,
      'amount': (amount * 100).toInt(),
      'name': 'EventBridge',
      'description': 'Wallet Top-up',
      'prefill': {
        'email': user?.email ?? '',
        'contact': user?.phone ?? '',
        'name': user?.name ?? '',
      },
      'theme': {'color': '#7B5E57'},
    };

    try {
      _razorpayInstance.open(options);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open Razorpay: $error')),
        );
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final amount = _pendingTopUpAmount;
    if (amount == null) {
      return;
    }

    try {
      await context.read<UserProvider>().topUpWallet(amount);
      _topUpController.clear();
      _pendingTopUpAmount = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet topped up successfully!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment received, but wallet update failed: $error'),
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _pendingTopUpAmount = null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${response.message ?? 'unknown error'}',
          ),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WalletBalance(balance: userProvider.walletBalance),
        const SizedBox(height: 14),
        TextField(
          controller: _topUpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Top-up Amount (₹)'),
        ),
        const SizedBox(height: 10),
        CustomButton(label: 'Top-up Wallet', onPressed: _topUp),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.card_giftcard_rounded),
            title: const Text('Cashback & Loyalty Points'),
            subtitle: const Text(
              'Earn 2% cashback and loyalty points on every booking.',
            ),
            trailing: Chip(
              label: Text(
                '${(userProvider.totalSpent ~/ 100).clamp(0, 999)} pts',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Split Payments'),
          subtitle: Text('Split event costs with friends via UPI links.'),
          trailing: Icon(Icons.group_add_rounded),
        ),
        const SizedBox(height: 10),
        Text(
          'Transaction History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...userProvider.transactions.map(
          (transaction) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(transaction.amount >= 0 ? Icons.add : Icons.remove),
            ),
            title: Text(transaction.title),
            subtitle: Text(
              DateFormat('d MMM y, hh:mm a').format(transaction.timestamp),
            ),
            trailing: Text(
              '${transaction.amount >= 0 ? '+' : ''}₹${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: transaction.amount >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: content,
    );
  }
}
