import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../payment/paystack_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _itemTypeController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMethod = 'CASH';

  double _pickupLat = 9.8965;
  double _pickupLng = 8.8583;
  double _dropoffLat = 9.9285;
  double _dropoffLng = 8.8921;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Request Delivery'),
        backgroundColor: blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pickup Location',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _pickupController,
              decoration: InputDecoration(
                hintText: 'e.g. Terminus Market, Jos',
                prefixIcon: const Icon(Icons.radio_button_checked, color: blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Drop-off Location',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _dropoffController,
              decoration: InputDecoration(
                hintText: 'e.g. University of Jos',
                prefixIcon: const Icon(Icons.location_on, color: orange),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Item Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _itemTypeController,
              decoration: InputDecoration(
                hintText: 'e.g. parcel, food, documents',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Note (optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Any special instructions?',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'CASH'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'CASH'
                            ? blue.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentMethod == 'CASH'
                              ? blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.money,
                              color: _paymentMethod == 'CASH'
                                  ? blue
                                  : Colors.grey),
                          const SizedBox(height: 4),
                          Text('Cash',
                              style: TextStyle(
                                color: _paymentMethod == 'CASH'
                                    ? blue
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 2),
                          Text('Pay on delivery',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'CARD'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'CARD'
                            ? orange.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentMethod == 'CARD'
                              ? orange
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.credit_card,
                              color: _paymentMethod == 'CARD'
                                  ? orange
                                  : Colors.grey),
                          const SizedBox(height: 4),
                          Text('Card',
                              style: TextStyle(
                                color: _paymentMethod == 'CARD'
                                    ? orange
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 2),
                          Text('Pay via Paystack',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: orders.loading
                    ? null
                    : () async {
                        if (_pickupController.text.isEmpty ||
                            _dropoffController.text.isEmpty ||
                            _itemTypeController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please fill all required fields')),
                          );
                          return;
                        }

                        final result = await orders.createOrder(
                          token: auth.token,
                          pickupLat: _pickupLat,
                          pickupLng: _pickupLng,
                          pickupAddress: _pickupController.text.trim(),
                          dropoffLat: _dropoffLat,
                          dropoffLng: _dropoffLng,
                          dropoffAddress: _dropoffController.text.trim(),
                          itemType: _itemTypeController.text.trim(),
                          paymentMethod: _paymentMethod,
                          itemNote: _noteController.text.trim(),
                        );

                        if (result != null &&
                            result['order'] != null &&
                            context.mounted) {
                          final breakdown = result['breakdown'];
                          final order = result['order'];
                          final totalAmount =
                              (breakdown['total'] as num).toDouble();

                          // If CARD payment selected, launch Paystack
                          if (_paymentMethod == 'CARD') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaystackScreen(
                                  email: auth.user?.phone != null
                                      ? '${auth.user!.phone}@ryaniva.com'
                                      : 'customer@ryaniva.com',
                                  amount: totalAmount,
                                  orderId: order['id'],
                                  onPaymentComplete: (success) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(success
                                              ? '✅ Payment successful!'
                                              : '❌ Payment cancelled'),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                            if (context.mounted) Navigator.pop(context);
                            return;
                          }

                          // CASH — show breakdown dialog
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: const Text('Order Confirmed! 🎉'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Distance: ${breakdown['distanceKm']} km'),
                                    Text(
                                        'Base fare: ₦${breakdown['baseFare']}'),
                                    Text(
                                        'Distance fare: ₦${breakdown['distanceFare']}'),
                                    Text(
                                        'Platform fee: ₦${breakdown['platformFee']}'),
                                    const Divider(),
                                    Text('Total: ₦${breakdown['total']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: orange,
                                            fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.info_outline,
                                              color: Colors.orange, size: 16),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Please have exact cash ready for the rider',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Done',
                                        style: TextStyle(color: blue)),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: orders.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Confirm Delivery',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          if (_paymentMethod == 'CARD') ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_outline, size: 16),
                          ]
                        ],
                      ),
              ),
            ),
            if (_paymentMethod == 'CARD') ...[
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('Secured by Paystack',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}