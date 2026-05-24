import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  Map<String, dynamic>? _analytics;
  List<dynamic> _riders = [];
  List<dynamic> _orders = [];
  bool _loading = true;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    try {
      final analytics = await ApiService.get('/admin/analytics', token: token);
      final riders = await ApiService.get('/admin/riders', token: token);
      final orders = await ApiService.get('/admin/orders', token: token);
      setState(() {
        _analytics = analytics;
        _riders = riders is List ? riders : [];
        _orders = orders is List ? orders : [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _approveRider(String riderId) async {
    final token = context.read<AuthProvider>().token;
    try {
      await ApiService.patch('/admin/riders/$riderId/approve', {}, token: token);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider approved successfully!')),
        );
      }
      _loadAll();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve rider')),
        );
      }
    }
  }

  Future<void> _suspendRider(String riderId) async {
    final token = context.read<AuthProvider>().token;
    try {
      await ApiService.patch('/admin/riders/$riderId/suspend', {}, token: token);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider suspended')),
        );
      }
      _loadAll();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to suspend rider')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            const SizedBox(width: 10),
            const Text('Ryaniva Admin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout()),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _tabBtn('Overview', 0, blue),
              _tabBtn('Riders', 1, blue),
              _tabBtn('Orders', 2, blue),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F)))
          : _currentTab == 0
              ? _buildOverview(blue, orange)
              : _currentTab == 1
                  ? _buildRiders(blue, orange)
                  : _buildOrders(blue, orange),
    );
  }

  Widget _tabBtn(String label, int index, Color blue) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFFE85C1A) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(Color blue, Color orange) {
    if (_analytics == null) return const Center(child: Text('Failed to load'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _statCard('Total Orders', '${_analytics!['orders']['total']}',
                  Icons.receipt_long, blue),
              _statCard('Active', '${_analytics!['orders']['active']}',
                  Icons.local_shipping, Colors.orange),
              _statCard('Completed', '${_analytics!['orders']['completed']}',
                  Icons.check_circle, Colors.green),
              _statCard('Customers', '${_analytics!['users']['customers']}',
                  Icons.people, Colors.purple),
              _statCard('Riders', '${_analytics!['users']['approvedRiders']}',
                  Icons.delivery_dining, blue),
              _statCard('Pending Riders',
                  '${_analytics!['users']['pendingRiders']}',
                  Icons.hourglass_empty, Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Platform Earnings',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      '₦${_analytics!['revenue']['platformEarnings']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total delivery value: ₦${_analytics!['revenue']['totalDeliveryValue']}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiders(Color blue, Color orange) {
    if (_riders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No riders yet', style: TextStyle(color: Colors.grey[500], fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _riders.length,
      itemBuilder: (context, index) {
        final rider = _riders[index];
        final status = rider['status'] ?? 'PENDING';
        final user = rider['user'] ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF1A3A8F)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['name'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(user['phone'] ?? '',
                                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'APPROVED'
                            ? Colors.green.withOpacity(0.1)
                            : status == 'SUSPENDED'
                                ? Colors.red.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: TextStyle(
                            color: status == 'APPROVED'
                                ? Colors.green
                                : status == 'SUSPENDED'
                                    ? Colors.red
                                    : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.delivery_dining, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text('Vehicle: ${rider['vehicle'] ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.amber[400]),
                    const SizedBox(width: 4),
                    Text('${rider['rating'] ?? 5.0}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (status != 'APPROVED')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveRider(rider['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    if (status != 'APPROVED') const SizedBox(width: 8),
                    if (status != 'SUSPENDED')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _suspendRider(rider['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Suspend'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrders(Color blue, Color orange) {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No orders yet', style: TextStyle(color: Colors.grey[500], fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final status = order['status'] ?? '';
        final customer = order['customer'] ?? {};

        Color statusColor;
        switch (status) {
          case 'REQUESTED': statusColor = Colors.orange; break;
          case 'ACCEPTED': statusColor = blue; break;
          case 'PICKED': statusColor = orange; break;
          case 'DELIVERED': statusColor = Colors.green; break;
          default: statusColor = Colors.red;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text((order['itemType'] ?? '').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: TextStyle(color: statusColor, fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Customer: ${customer['name'] ?? 'Unknown'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.radio_button_checked, color: blue, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(order['pickupAddress'] ?? '',
                        style: const TextStyle(fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, color: orange, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(order['dropoffAddress'] ?? '',
                        style: const TextStyle(fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${order['distanceKm']} km • ${order['paymentMethod']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    Text('₦${order['price']}',
                        style: TextStyle(color: orange,
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}