import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';
import '../profile_edit_screen.dart';
import '../notifications_screen.dart';
import '../help_support_screen.dart';
import '../privacy_policy_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  bool _isOnline = false;
  bool _profileLoaded = false;
  bool _hasProfile = false;
  Map<String, dynamic>? _riderProfile;
  String _selectedBike = 'Motorcycle';
  List<Order> _activeOrders = [];
  int _currentIndex = 0;
  final List<String> _bikeTypes = ['Motorcycle', 'Scooter', 'Bicycle'];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _loadProfile());
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
    } catch (e) {}
  }

  Future<void> _registerRider() async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await ApiService.post('/riders/register', {'vehicle': _selectedBike}, token: token);
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
    } catch (e) {}
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await ApiService.patch('/orders/$orderId/status', {'status': status}, token: token);
      if (res['message'] != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
        await _loadActiveOrders();
        await _loadOrders();
        await _loadProfile();
      }
    } catch (e) {}
  }

  Future<void> _openGoogleMaps(double lat, double lng, String label) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
      await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    const blue = Color(0xFF1A3A8F);

    if (!_profileLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F))));
    }

    if (!_hasProfile) return _buildSetupScreen(blue);
    if (_riderProfile?['status'] == 'PENDING') return _buildPendingScreen(blue);
    if (_riderProfile?['status'] == 'SUSPENDED') return _buildSuspendedScreen();

    final pages = [
      _buildHomeTab(context, auth),
      _buildOrdersTab(context),
      _buildEarningsTab(),
      _buildWalletTab(),
      _buildProfileTab(context, auth),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: blue,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, dynamic auth) {
    final orders = context.watch<OrderProvider>();
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/logo.png', height: 30),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ryaniva Rider',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              Text('Hello, ${auth.user?.name?.split(' ')[0] ?? ''}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () { _loadOrders(); _loadActiveOrders(); },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () => auth.logout(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: (_isOnline ? Colors.green : Colors.grey).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.motorcycle,
                                  color: _isOnline ? Colors.green : Colors.grey[300], size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isOnline ? 'You are Online' : 'You are Offline',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(_isOnline ? 'Receiving requests' : 'Go online to earn',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Switch(value: _isOnline, onChanged: (_) => _toggleOnline(), activeColor: orange),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _statCard('${_riderProfile?['totalTrips'] ?? 0}', 'Trips', Icons.check_circle_outline, Colors.green),
                  const SizedBox(width: 8),
                  _statCard('${_riderProfile?['rating'] ?? 5.0}', 'Rating', Icons.star_outline, Colors.amber),
                  const SizedBox(width: 8),
                  _statCard('${_activeOrders.length}', 'Active', Icons.local_shipping_outlined, blue),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Available Orders (${orders.orders.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (_activeOrders.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _currentIndex = 1),
                      child: Text('My Orders (${_activeOrders.length})',
                          style: const TextStyle(color: orange, fontSize: 12)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: !_isOnline
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.power_settings_new, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Go online to see requests', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : orders.loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F)))
                      : orders.orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('No orders available', style: TextStyle(color: Colors.grey[500])),
                                ],
                              ),
                            )
                          : ListView.builder(
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
                                          SnackBar(content: Text(success ? 'Order accepted!' : 'Could not accept')),
                                        );
                                        if (success) {
                                          _loadOrders();
                                          _loadActiveOrders();
                                          setState(() => _currentIndex = 1);
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
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadActiveOrders),
        ],
      ),
      body: _activeOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No active orders', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.builder(
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
                    onPressed: () => _updateOrderStatus(order.id, isPicked ? 'DELIVERED' : 'PICKED'),
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
            ),
    );
  }

  Widget _buildEarningsTab() {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);
    final totalTrips = _riderProfile?['totalTrips'] ?? 0;
    final rating = _riderProfile?['rating'] ?? 5.0;
    final totalTips = _riderProfile?['totalTips'] ?? 0.0;
    final bonusEligible = _riderProfile?['bonusEligible'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('My Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Salary', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Paid by Ryaniva',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Contact admin for salary details',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _earningsCard('$totalTrips', 'Completed Trips', Icons.check_circle, Colors.green),
                _earningsCard('$rating ⭐', 'My Rating', Icons.star, Colors.amber),
                _earningsCard('₦${totalTips.toStringAsFixed(0)}', 'Total Tips', Icons.volunteer_activism, orange),
                _earningsCard(bonusEligible ? 'Eligible ✅' : 'Not Yet',
                    'Bonus Status', Icons.emoji_events, bonusEligible ? Colors.green : Colors.grey),
              ],
            ),
            if (bonusEligible) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.green, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🏆 You are Bonus Eligible!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 4),
                          Text('You have a 4.5+ rating and 20+ trips. Contact your admin to claim your bonus.',
                              style: TextStyle(color: Colors.green[700], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How Bonuses Work',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _bonusRule('⭐', 'Maintain a 4.5+ star rating'),
                  _bonusRule('🏍️', 'Complete 20+ deliveries'),
                  _bonusRule('💰', 'Tips go directly to you'),
                  _bonusRule('🏆', 'Eligible riders get monthly bonus from Ryaniva'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTab() {
    const blue = Color(0xFF1A3A8F);
    final totalTips = _riderProfile?['totalTips'] ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tips Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('₦${totalTips.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Total tips received from customers',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tip History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('No tip transactions yet', style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, dynamic auth) {
    const blue = Color(0xFF1A3A8F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: blue.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        auth.user?.name?.substring(0, 1).toUpperCase() ?? 'R',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(auth.user?.name ?? 'Rider',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(auth.user?.phone ?? '', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Ryaniva Rider',
                        style: TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _profileStat('${_riderProfile?['totalTrips'] ?? 0}', 'Trips'),
                      _profileStat('${_riderProfile?['rating'] ?? 5.0}', 'Rating'),
                      _profileStat(_riderProfile?['vehicle'] ?? 'N/A', 'Vehicle'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _profileItem(Icons.person_outline, 'Edit Profile', blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
                  }),
                  _divider(),
                  _profileItem(Icons.notifications_outlined, 'Notifications', blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  }),
                  _divider(),
                  _profileItem(Icons.help_outline, 'Help & Support', blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                  }),
                  _divider(),
                  _profileItem(Icons.privacy_tip_outlined, 'Privacy Policy', blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                  }),
                  _divider(),
                  _profileItem(Icons.logout, 'Logout', Colors.red, () => auth.logout()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningsCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bonusRule(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _profileStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3A8F))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _profileItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(fontSize: 14, color: color == Colors.red ? Colors.red : Colors.black87)),
      trailing: color != Colors.red ? const Icon(Icons.chevron_right, color: Colors.grey, size: 18) : null,
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);

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
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.radio_button_checked, color: blue, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(order.pickupAddress,
                  style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.location_on, color: orange, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(order.dropoffAddress,
                  style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            if (order.senderPhone != null && order.senderPhone!.isNotEmpty) ...[
  const SizedBox(height: 8),
  Row(children: [
    Icon(Icons.person_outline, color: blue, size: 14),
    const SizedBox(width: 6),
    Text('Sender: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    Text(order.senderPhone!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const Spacer(),
    GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:${order.senderPhone}');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Icon(Icons.call, color: Colors.green, size: 18),
    ),
  ]),
],
if (order.recipientName != null && order.recipientName!.isNotEmpty) ...[
  const SizedBox(height: 4),
  Row(children: [
    Icon(Icons.person, color: orange, size: 14),
    const SizedBox(width: 6),
    Text('Recipient: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    Text(order.recipientName!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    if (order.recipientPhone != null && order.recipientPhone!.isNotEmpty) ...[
      const Spacer(),
      GestureDetector(
        onTap: () async {
          final uri = Uri.parse('tel:${order.recipientPhone}');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        child: Icon(Icons.call, color: Colors.green, size: 18),
      ),
    ],
  ]),
],
if (order.recipientPhone != null && order.recipientPhone!.isNotEmpty) ...[
  const SizedBox(height: 4),
  Row(children: [
    Icon(Icons.phone_outlined, color: orange, size: 14),
    const SizedBox(width: 6),
    Text('Recipient Phone: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    Text(order.recipientPhone!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  ]),
],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.distanceKm} km • ${order.paymentMethod}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                action,
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openGoogleMaps(
                      order.pickupLat,
                      order.pickupLng,
                      'Pickup: ${order.pickupAddress}',
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 14),
                    label: const Text('Navigate to Pickup', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blue,
                      side: BorderSide(color: blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openGoogleMaps(
                      order.dropoffLat,
                      order.dropoffLng,
                      'Dropoff: ${order.dropoffAddress}',
                    ),
                    icon: const Icon(Icons.location_on_outlined, size: 14),
                    label: const Text('Navigate to Dropoff', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      side: BorderSide(color: orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupScreen(Color blue) {
    const orange = Color(0xFFE85C1A);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: blue.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.motorcycle, size: 40, color: blue),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Set Up Your Rider Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Select your bike type to start delivering',
                  style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Bike Type', style: TextStyle(fontWeight: FontWeight.w600))),
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
                            width: isSelected ? 2 : 1),
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
                                  fontSize: 15)),
                          const Spacer(),
                          if (isSelected) Icon(Icons.check_circle, color: orange, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _registerRider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Profile',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingScreen(Color blue) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_empty, size: 40, color: Colors.orange),
              ),
              const SizedBox(height: 24),
              const Text('Profile Under Review',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Your profile is awaiting admin approval.',
                  style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: blue, side: BorderSide(color: blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuspendedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.block, size: 40, color: Colors.red),
              ),
              const SizedBox(height: 24),
              const Text('Account Suspended',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Please contact Ryaniva support.',
                  style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}