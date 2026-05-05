import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
  late Razorpay _razorpay;

  static const String razorpayKeyId = 'rzp_test_SlGLA7NNNqCrpd';

  PaymentService() {
    _razorpay = Razorpay();
  }

  /// Initialize Razorpay with event listeners
  void initializeRazorpay({
    required Function(PaymentSuccessResponse) onPaymentSuccess,
    required Function(PaymentFailureResponse) onPaymentError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) {
      onPaymentSuccess(response);
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      onPaymentError(response);
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
      ExternalWalletResponse response,
    ) {
      onExternalWallet(response);
    });
  }

  /// Open Razorpay payment dialog
  void openRazorpayPayment({
    required double amount,
    required String userEmail,
    required double deliveryFee,
    String? userPhone,
    String? userName,
  }) {
    int amountInPaise = ((amount + deliveryFee) * 100).toInt();

    var options = {
      'key': razorpayKeyId,
      'amount': amountInPaise,
      'name': 'EventBridge',
      'description': 'Payment for Event Booking',
      'prefill': {
        'contact': userPhone ?? '',
        'email': userEmail,
        'name': userName ?? '',
      },
      'theme': {'color': '#7B5E57'},
      'retry': {'enabled': true, 'max_count': 1},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      throw Exception("Error opening Razorpay: $e");
    }
  }

  /// Create order in Firestore
  Future<void> createOrder({
    required String userEmail,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentId,
    required String deliveryAddress,
    required double latitude,
    required double longitude,
    required String paymentMethod,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('Orders').add({
        'customerEmail': userEmail,
        'items': items,
        'totalAmount': totalAmount,
        'status': 'Processing',
        'orderDate': FieldValue.serverTimestamp(),
        'address_text': deliveryAddress,
        'latitude': latitude,
        'longitude': longitude,
        'paymentMethod': paymentMethod,
        'paymentId': paymentId,
      });
    } catch (e) {
      throw Exception("Failed to create order: $e");
    }
  }

  /// Reduce product stock
  Future<void> reduceProductStock({
    required String productName,
    required int quantity,
  }) async {
    try {
      var productQuery = await FirebaseFirestore.instance
          .collection('Products')
          .where('name', isEqualTo: productName)
          .get();

      if (productQuery.docs.isNotEmpty) {
        var pDoc = productQuery.docs.first;
        int currentStock = pDoc['quantity'] ?? 0;
        await pDoc.reference.update({'quantity': currentStock - quantity});
      }
    } catch (e) {
      throw Exception("Failed to reduce stock: $e");
    }
  }

  /// Clear user's cart
  Future<void> clearUserCart(String userEmail) async {
    try {
      var cartItemsRef = FirebaseFirestore.instance
          .collection('Carts')
          .doc(userEmail)
          .collection('Items');

      var snapshots = await cartItemsRef.get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception("Failed to clear cart: $e");
    }
  }

  /// Get cart items
  Future<List<DocumentSnapshot>> getCartItems(String userEmail) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Carts')
          .doc(userEmail)
          .collection('Items')
          .get();
      return snapshot.docs;
    } catch (e) {
      throw Exception("Failed to fetch cart: $e");
    }
  }

  /// Calculate total amount
  double calculateTotal(List<DocumentSnapshot> items) {
    double total = 0;
    for (var doc in items) {
      var data = doc.data() as Map<String, dynamic>;
      total += (data['price'] * data['qty']);
    }
    return total;
  }

  /// Legacy method for backward compatibility
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

  /// Dispose Razorpay
  void dispose() {
    _razorpay.clear();
  }
}
