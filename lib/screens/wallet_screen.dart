import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'split_payments_screen.dart';
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
  final _redeemPointsController = TextEditingController();
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
    _redeemPointsController.dispose();
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

  Future<void> _redeemPoints() async {
    final points = int.tryParse(_redeemPointsController.text);
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid points amount.')),
      );
      return;
    }

    try {
      await context.read<UserProvider>().redeemLoyaltyPoints(points: points);
      _redeemPointsController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$points points redeemed into wallet credit.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
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
            subtitle: Text(
              'Cashback is credited to your wallet automatically after each booking. Redeem loyalty points here to add wallet credit for your next booking.',
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${userProvider.cashbackEarned.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('${userProvider.loyaltyPoints} pts'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeem Loyalty Points',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Use 10 points for ₹1 wallet credit. Available: ${userProvider.loyaltyPoints} points.',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _redeemPointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points to redeem',
                  ),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  label: 'Redeem into Wallet',
                  onPressed: _redeemPoints,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Split Payments'),
          subtitle: Text('Split event costs with friends via UPI links.'),
          trailing: Icon(Icons.group_add_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SplitPaymentsScreen()),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Transaction History (Last 30 Days)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (userProvider.transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No transactions in the last 30 days. Top up wallet or book an event to see your history here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          Column(
            children: [
              ...userProvider.transactions.map(
                (transaction) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(
                      transaction.amount >= 0 ? Icons.add : Icons.remove,
                    ),
                  ),
                  title: Text(transaction.title),
                  subtitle: Text(
                    DateFormat(
                      'd MMM y, hh:mm a',
                    ).format(transaction.timestamp),
                  ),
                  trailing: Text(
                    '${transaction.amount >= 0 ? '+' : ''}₹${transaction.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: transaction.amount >= 0
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (userProvider.hasMoreTransactions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        userProvider.loadMoreTransactions();
                      },
                      child: Text(
                        'Load More (Page ${userProvider.currentTransactionPage + 1})',
                      ),
                    ),
                  ),
                ),
            ],
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
