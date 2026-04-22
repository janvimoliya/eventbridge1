class PaymentResult {
  const PaymentResult({
    required this.success,
    required this.transactionId,
    required this.message,
  });

  final bool success;
  final String transactionId;
  final String message;
}

class PaymentService {
  Future<PaymentResult> processPayment({
    required double amount,
    required String method,
    required bool isConfirmed,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!isConfirmed) {
      return const PaymentResult(
        success: false,
        transactionId: '',
        message: 'Payment confirmation is required before ticket generation.',
      );
    }

    final txn = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(
      success: true,
      transactionId: txn,
      message:
          'Payment of ₹${amount.toStringAsFixed(2)} via $method completed.',
    );
  }
}
