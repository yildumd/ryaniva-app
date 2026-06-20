import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'create_order_screen.dart';
import 'rate_order_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final token = context.read<AuthProvider>().token;
      context.read<OrderProvider>().loadMyOrders(token);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'REQUESTED': return Colors.orange;
      case 'ACCEPTED': return const Color(0xFF1A3A8F);
      case 'PICKED': return const Color(0xFFE85C1A);
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.grey;
      default: return Colors.red;
    }
  }

  Future<void> _confirmCancel(BuildContext context, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: const Text(
            'Are you sure you want to cancel this delivery request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final orderProvider = context.read<OrderProvider>();
      final token = context.read<AuthProvider>().token;
      final result = await orderProvider.cancelOrder(orderId, token);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        if (result['success']) {
          orderProvider.loadMyOrders(token);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ryaniva',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Hello, ${auth.user?.name ?? ''}',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orders.loadMyOrders(auth.token),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: orders.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F)))
          : orders.orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No deliveries yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      Text('Tap the button below to request your first delivery',
                          style: TextStyle(color: Colors.grey[400]),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.orders.length,
                  itemBuilder: (context, index) {
                    final order = orders.orders[index];
                    final isDelivered = order.status == 'DELIVERED';
                    final isCancellable = order.status == 'REQUESTED' ||
                        order.status == 'ACCEPTED';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10)
                        ],
                        border: isDelivered
                            ? Border.all(color: Colors.green.withOpacity(0.3), width: 1)
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.itemType.toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(order.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(order.status,
                                      style: TextStyle(
                                          color: _statusColor(order.status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.radio_button_checked,
                                    color: blue, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(order.pickupAddress,
                                        style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(order.dropoffAddress,
                                        style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${order.distanceKm} km',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 13)),
                                Text('₦${order.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ],
                            ),
                            if (isCancellable) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmCancel(context, order.id),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Cancel Order'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                            if (isDelivered) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RateOrderScreen(
                                        orderId: order.id,
                                        token: auth.token,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.star_outline, size: 16),
                                  label: const Text('Rate & Tip Rider'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A3A8F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
        ),
        backgroundColor: orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Request Delivery'),
      ),
    );
  }
}