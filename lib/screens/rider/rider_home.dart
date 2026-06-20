import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  bool _profileLoaded = false;
  bool _hasProfile = false;
  Map<String, dynamic>? _riderProfile;
  String _selectedBike = 'Motorcycle';
  late TabController _tabController;
  List<Order> _activeOrders = [];

  final List<String> _bikeTypes = ['Motorcycle', 'Scooter', 'Bicycle'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.delayed(Duration.zero, () => _loadProfile());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final token = context.read<AuthProvider>().token;
    try {
      final data = await ApiService.get('/riders/profile', token: token);
      if (data['id'] != null) {
        setState(() {
          _riderProfile = data;
          _hasProfile = true;
          _isOnline = data['isOnline'] ?? false;
          _profileLoaded = true;
        });
        _loadOrders();
        _loadActiveOrders();
      } else {
        setState(() {
          _hasProfile = false;
          _profileLoaded = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasProfile = false;
        _profileLoaded = true;
      });
    }
  }

  Future<void> _loadOrders() async {
    final token = context.read<AuthProvider>().token;
    await context.read<OrderProvider>().loadNearbyOrders(token);
  }

  Future<void> _loadActiveOrders() async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await ApiService.get('/orders/my-rider-orders', token: token);
      if (res is List) {
        setState(() {
          _activeOrders = res.map((o) => Order.fromJson(o)).toList();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _registerRider() async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await ApiService.post(
        '/riders/register',
        {'vehicle': _selectedBike},
        token: token,
      );
      if (res['rider'] != null) {
        setState(() {
          _riderProfile = res['rider'];
          _hasProfile = true;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile created! Awaiting admin approval.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create profile')),
        );
      }
    }
  }

  Future<void> _toggleOnline() async {
    final token = context.read<AuthProvider>().token;
    final endpoint = _isOnline ? '/riders/offline' : '/riders/online';
    try {
      await ApiService.patch(endpoint, {}, token: token);
      setState(() => _isOnline = !_isOnline);
      if (_isOnline) _loadOrders();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await ApiService.patch(
        '/orders/$orderId/status',
        {'status': status},
        token: token,
      );
      if (res['message'] != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'])),
          );
        }
        _loadActiveOrders();
        _loadOrders();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    if (!_profileLoaded) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ryaniva Rider',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Hello, ${auth.user?.name ?? ''}',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            _loadOrders();
            _loadActiveOrders();
          }),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout()),
        ],
        bottom: _hasProfile && _riderProfile?['status'] == 'APPROVED'
            ? TabBar(
                controller: _tabController,
                indicatorColor: orange,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Available (${orders.orders.length})'),
                  Tab(text: 'My Orders (${_activeOrders.length})'),
                ],
              )
            : null,
      ),
      body: !_hasProfile
          ? _buildSetupScreen(blue, orange)
          : _riderProfile?['status'] == 'PENDING'
              ? _buildPendingScreen(blue)
              : _riderProfile?['status'] == 'SUSPENDED'
                  ? _buildSuspendedScreen()
                  : Column(
                      children: [
                        _buildOnlineToggle(blue, orange),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAvailableOrders(orders, blue, orange),
                              _buildActiveOrders(blue, orange),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildOnlineToggle(Color blue, Color orange) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (_isOnline ? Colors.green : Colors.grey).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.motorcycle,
                    color: _isOnline ? Colors.green : Colors.grey, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isOnline ? 'You are Online' : 'You are Offline',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_isOnline ? 'Receiving delivery requests' : 'Go online to start earning',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ],
          ),
          Switch(
            value: _isOnline,
            onChanged: (_) => _toggleOnline(),
            activeColor: orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrders(OrderProvider orders, Color blue, Color orange) {
    if (!_isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_settings_new, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('You are offline', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Toggle online to see delivery requests',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    if (orders.loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F)));
    }

    if (orders.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No available orders', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.orders.length,
      itemBuilder: (context, index) {
        final order = orders.orders[index];
        return _orderCard(
          order: order,
          blue: blue,
          orange: orange,
          action: ElevatedButton(
            onPressed: () async {
              final success = await orders.acceptOrder(
                  order.id, context.read<AuthProvider>().token);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Order accepted!' : 'Could not accept order')),
                );
                if (success) {
                  _loadOrders();
                  _loadActiveOrders();
                  _tabController.animateTo(1);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Accept'),
          ),
        );
      },
    );
  }

  Widget _buildActiveOrders(Color blue, Color orange) {
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No active orders', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        final isPicked = order.status == 'PICKED';

        return _orderCard(
          order: order,
          blue: blue,
          orange: orange,
          showStatus: true,
          action: ElevatedButton(
            onPressed: () => _updateOrderStatus(
              order.id,
              isPicked ? 'DELIVERED' : 'PICKED',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPicked ? orange : blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(isPicked ? 'Mark Delivered' : 'Mark Picked Up'),
          ),
        );
      },
    );
  }

  Widget _orderCard({
    required Order order,
    required Color blue,
    required Color orange,
    required Widget action,
    bool showStatus = false,
  }) {
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
                Text(order.itemType.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('₦${order.price.toStringAsFixed(0)}',
                    style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            if (showStatus) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.status == 'PICKED'
                      ? orange.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(order.status,
                    style: TextStyle(
                      color: order.status == 'PICKED' ? orange : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.radio_button_checked, color: blue, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(order.pickupAddress, style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, color: orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(order.dropoffAddress, style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.distanceKm} km • ${order.paymentMethod}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                action,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupScreen(Color blue, Color orange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: blue.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.motorcycle, size: 40, color: blue),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('Set Up Your Rider Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Select your bike type to start delivering',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 40),
          const Text('Bike Type',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Column(
            children: _bikeTypes.map((bike) {
              final isSelected = _selectedBike == bike;
              return GestureDetector(
                onTap: () => setState(() => _selectedBike = bike),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? blue.withOpacity(0.08) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.motorcycle,
                          color: isSelected ? blue : Colors.grey[400]),
                      const SizedBox(width: 12),
                      Text(bike,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? blue : Colors.black87,
                            fontSize: 15,
                          )),
                      const Spacer(),
                      if (isSelected)
                        Icon(Icons.check_circle, color: orange, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _registerRider,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingScreen(Color blue) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_empty,
                  size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text('Profile Under Review',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your rider profile has been submitted and is awaiting admin approval. You will be able to accept deliveries once approved.',
              style: TextStyle(color: Colors.grey[600], height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: blue,
                side: BorderSide(color: blue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuspendedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.block, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text('Account Suspended',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your rider account has been suspended. Please contact Ryaniva support for more information.',
              style: TextStyle(color: Colors.grey[600], height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}