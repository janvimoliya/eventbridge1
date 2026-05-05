import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final String userEmail = FirebaseAuth.instance.currentUser!.email!;
  final double deliveryFee = 30.0;

  final TextEditingController _addressController = TextEditingController();
  double pickedLat = 0.0;
  double pickedLng = 0.0;

  late Razorpay _razorpay;
  String selectedPaymentMethod = "COD";

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // ==================== RAZORPAY EVENT HANDLERS ====================

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    FirebaseFirestore.instance
        .collection('Carts')
        .doc(userEmail)
        .collection('Items')
        .get()
        .then((snap) {
          double total = 0;
          for (var d in snap.docs) {
            final Map<String, dynamic> data = d.data();
            total += (data['price'] * data['qty']);
          }
          placeOrder(snap.docs, total, paymentId: response.paymentId);
        })
        .catchError((e) {
          _showError("Failed to retrieve cart: $e");
        });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showError("Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showMessage("External Wallet Selected: ${response.walletName}");
  }

  // ==================== HELPER FUNCTIONS ====================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ==================== RAZORPAY PAYMENT FUNCTION ====================

  void openRazorpay(double amount) {
    String finalAddress = _addressController.text.trim();
    if (finalAddress.isEmpty ||
        finalAddress == "Select your delivery address") {
      _showError("Please provide an address first");
      return;
    }

    int amountInPaise = ((amount + deliveryFee) * 100).toInt();

    const String razorpayKeyId = 'rzp_test_SlAQVuX0BPaIyY';

    var options = {
      'key': razorpayKeyId,
      'amount': amountInPaise,
      'name': 'Your Coffee Shop',
      'description': 'Payment for Coffee Order',
      'prefill': {
        'contact': '', // Will be fetched from Firestore ideally
        'email': userEmail,
      },
      'theme': {
        'color': '#7B5E57', // Brown theme
      },
      'retry': {'enabled': true, 'max_count': 1},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showError("Error opening Razorpay: $e");
    }
  }

  // ==================== PLACE ORDER FUNCTION ====================

  void placeOrder(
    List<DocumentSnapshot> cartItems,
    double total, {
    String? paymentId,
  }) async {
    String finalAddress = _addressController.text.trim();

    if (finalAddress.isEmpty ||
        finalAddress == "Select your delivery address") {
      _showError("Please provide a delivery address");
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) =>
            const Center(child: CircularProgressIndicator(color: Colors.brown)),
      );

      // 1. Create Order in Firestore
      await FirebaseFirestore.instance.collection('Orders').add({
        'customerEmail': userEmail,
        'items': cartItems.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['name'],
            'price': data['price'],
            'qty': data['qty'],
            'size': data['size'] ?? "Small",
            'sugar': data['sugar'] ?? "Normal",
          };
        }).toList(),
        'totalAmount': total + deliveryFee,
        'status': 'Processing',
        'orderDate': FieldValue.serverTimestamp(),
        'address_text': finalAddress,
        'latitude': pickedLat,
        'longitude': pickedLng,
        'paymentMethod': selectedPaymentMethod,
        'paymentId': paymentId ?? "COD_ORDER",
      });

      // 2. Reduce Stock
      for (var cartItemDoc in cartItems) {
        var cartData = cartItemDoc.data() as Map<String, dynamic>;
        var productQuery = await FirebaseFirestore.instance
            .collection('Products')
            .where('name', isEqualTo: cartData['name'])
            .get();

        if (productQuery.docs.isNotEmpty) {
          var pDoc = productQuery.docs.first;
          await pDoc.reference.update({
            'quantity': (pDoc['quantity'] ?? 0) - cartData['qty'],
          });
        }
      }

      // 3. Clear Cart
      var cartItemsRef = FirebaseFirestore.instance
          .collection('Carts')
          .doc(userEmail)
          .collection('Items');
      var snapshots = await cartItemsRef.get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            content: const Text(
              "Order Placed Successfully! ☕",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showError("Error placing order: $e");
      }
    }
  }

  // ==================== BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.brown),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Carts')
            .doc(userEmail)
            .collection('Items')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text("Your cart is empty"));
          }

          double subtotal = 0;
          for (var d in items) {
            var data = d.data() as Map<String, dynamic>;
            subtotal += (data['price'] * data['qty']);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Address Section
              _buildAddressSection(),
              const SizedBox(height: 30),

              // Payment Method Section
              _buildPaymentMethodSection(),
              const SizedBox(height: 30),

              // Order Summary
              _buildOrderSummary(items),
              const SizedBox(height: 30),

              // Price Summary
              _buildPriceSummary(subtotal),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _handleCheckoutButtonPress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              selectedPaymentMethod == "ONLINE" ? "Pay Now" : "Confirm Order",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCheckoutButtonPress() {
    if (_addressController.text.trim().isEmpty) {
      _showError("Please select a delivery address");
      return;
    }

    FirebaseFirestore.instance
        .collection('Carts')
        .doc(userEmail)
        .collection('Items')
        .get()
        .then((snap) {
          if (snap.docs.isEmpty) {
            _showError("Your cart is empty");
            return;
          }

          double total = 0;
          for (var d in snap.docs) {
            final Map<String, dynamic> data = d.data();
            total += (data['price'] * data['qty']);
          }

          if (selectedPaymentMethod == "ONLINE") {
            openRazorpay(total);
          } else {
            placeOrder(snap.docs, total);
          }
        })
        .catchError((e) {
          _showError("Error: $e");
        });
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Delivery Address",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.brown,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Address picker coming soon"),
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded, color: Colors.brown),
              label: const Text(
                "Use Map",
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Click 'Use Map' to select address...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
              prefixIcon: Icon(Icons.location_on_rounded, color: Colors.brown),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Payment Method",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPaymentOptionTile(
                title: 'Cash on Delivery (COD)',
                value: 'COD',
              ),
              _buildPaymentOptionTile(
                title: 'Online Payment (Razorpay)',
                value: 'ONLINE',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionTile({
    required String title,
    required String value,
  }) {
    final isSelected = selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => selectedPaymentMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: Colors.brown,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(List<DocumentSnapshot> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Order Summary",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: items.map((doc) {
              var item = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item["name"]} x${item["qty"]}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${item['size'] ?? 'Small'} • ${item['sugar'] ?? 'Normal'}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${(item["price"] * item["qty"]).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(double subtotal) {
    double total = subtotal + deliveryFee;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
              BoxShadow(
                color: Colors.brown.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal"),
              Text(
                "₹${subtotal.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Delivery Fee"), Text("₹30.00")],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grand Total",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.brown,
                ),
              ),
              Text(
                "₹${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
