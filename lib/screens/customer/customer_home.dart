import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'create_order_screen.dart';
import 'rate_order_screen.dart';
import '../privacy_policy_screen.dart';
import '../help_support_screen.dart';
import '../notifications_screen.dart';
import '../profile_edit_screen.dart';
import '../payment/flutterwave_screen.dart';
import '../../services/api_service.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final token = context.read<AuthProvider>().token;
      context.read<OrderProvider>().loadMyOrders(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    final pages = [
      _HomeTab(auth: auth, orders: orders),
      _OrdersTab(auth: auth, orders: orders),
      _TrackTab(orders: orders, auth: auth),
      _WalletTab(auth: auth),
      _ProfileTab(auth: auth),
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
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ── HOME TAB ──
class _HomeTab extends StatelessWidget {
  final dynamic auth;
  final dynamic orders;

  const _HomeTab({required this.auth, required this.orders});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    final services = [
      {'icon': Icons.inventory_2_outlined, 'label': 'Send\nPackage', 'color': blue, 'type': 'Package'},
      {'icon': Icons.fastfood_outlined, 'label': 'Food\nDelivery', 'color': orange, 'type': 'Food'},
      {'icon': Icons.description_outlined, 'label': 'Documents', 'color': Colors.purple, 'type': 'Documents'},
      {'icon': Icons.more_horiz, 'label': 'Other\nServices', 'color': Colors.teal, 'type': 'Other'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/logo.png', height: 32),
                            const SizedBox(width: 10),
                            const Text('Ryaniva',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Hello, ${auth.user?.name?.split(' ')[0] ?? 'there'} 👋',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('What are you sending today?',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Services
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Our Services',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 16),
                    Row(
                      children: services.map((s) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateOrderScreen(preselectedType: s['type'] as String),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: (s['color'] as Color).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 22),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(s['label'] as String,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Orders
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Orders',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See all', style: TextStyle(color: Color(0xFF1A3A8F))),
                    ),
                  ],
                ),
              ),

              if (orders.loading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A8F)))
              else if (orders.orders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No deliveries yet', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: orders.orders.length > 3 ? 3 : orders.orders.length,
                  itemBuilder: (context, index) {
                    final order = orders.orders[index];
                    return _OrderCard(order: order, auth: auth, compact: true);
                  },
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ORDERS TAB ──
class _OrdersTab extends StatelessWidget {
  final dynamic auth;
  final dynamic orders;

  const _OrdersTab({required this.auth, required this.orders});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orders.loadMyOrders(auth.token),
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
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No orders yet', style: TextStyle(color: Colors.grey[500], fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.orders.length,
                  itemBuilder: (context, index) {
                    final order = orders.orders[index];
                    return _OrderCard(order: order, auth: auth, compact: false);
                  },
                ),
    );
  }
}

// ── ORDER CARD ──
class _OrderCard extends StatelessWidget {
  final dynamic order;
  final dynamic auth;
  final bool compact;

  const _OrderCard({required this.order, required this.auth, required this.compact});

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

  content: const Text('Are you sure you want to cancel this delivery?'),

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);
    final isDelivered = order.status == 'DELIVERED';
    final isCancellable = order.status == 'REQUESTED' || order.status == 'ACCEPTED' || order.status == 'PICKED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: isDelivered ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.1),
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
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.radio_button_checked, color: blue, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(order.pickupAddress,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on, color: orange, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(order.dropoffAddress,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.distanceKm} km',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                Text('₦${order.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: orange, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            if (!compact) ...[
              if (isCancellable) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancel(context, order.id),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
              if (isDelivered) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            RateOrderScreen(orderId: order.id, token: auth.token))),
                    icon: const Icon(Icons.star_outline, size: 14),
                    label: const Text('Rate & Tip Rider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── TRACK TAB ──
class _TrackTab extends StatefulWidget {
  final dynamic orders;
  final dynamic auth;
  const _TrackTab({required this.orders, required this.auth});

  @override
  State<_TrackTab> createState() => _TrackTabState();
}

class _TrackTabState extends State<_TrackTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      widget.orders.loadMyOrders(widget.auth.token);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    final activeOrders = widget.orders.orders.where(
      (o) => o.status == 'ACCEPTED' || o.status == 'PICKED' || o.status == 'REQUESTED'
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('Track Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.orders.loadMyOrders(widget.auth.token),
          ),
        ],
      ),
      body: activeOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_searching, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No active deliveries',
                      style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Text('Active orders will appear here and update automatically',
                      style: TextStyle(color: Colors.grey[400]),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.green[50],
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, color: Colors.green, size: 14),
                      const SizedBox(width: 6),
                      Text('Auto-updating every 10 seconds',
                          style: TextStyle(color: Colors.green[700], fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeOrders.length,
                    itemBuilder: (context, index) {
                      final order = activeOrders[index];
                      final steps = ['REQUESTED', 'ACCEPTED', 'PICKED', 'DELIVERED'];
                      final currentStep = steps.indexOf(order.status);
                      final stepLabels = ['Requested', 'Rider Accepted', 'Picked Up', 'Delivered'];
                      final stepIcons = [
                        Icons.receipt_long,
                        Icons.person,
                        Icons.inventory_2,
                        Icons.check_circle,
                      ];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.itemType.toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('₦${order.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.radio_button_checked, color: blue, size: 13),
                              const SizedBox(width: 6),
                              Expanded(child: Text(order.pickupAddress,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ]),
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.location_on, color: orange, size: 13),
                              const SizedBox(width: 6),
                              Expanded(child: Text(order.dropoffAddress,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ]),
                            const SizedBox(height: 20),
                            Row(
                              children: List.generate(4, (i) {
                                final isActive = i <= currentStep;
                                final isLast = i == 3;
                                return Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 32, height: 32,
                                              decoration: BoxDecoration(
                                                color: isActive ? blue : Colors.grey[200],
                                                shape: BoxShape.circle,
                                                border: i == currentStep
                                                    ? Border.all(color: orange, width: 2)
                                                    : null,
                                              ),
                                              child: Icon(stepIcons[i],
                                                  color: isActive ? Colors.white : Colors.grey[400],
                                                  size: 15),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(stepLabels[i],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: isActive ? blue : Colors.grey[400],
                                                  fontWeight: i == currentStep
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                )),
                                          ],
                                        ),
                                      ),
                                      if (!isLast)
                                        Container(
                                          height: 2, width: 20,
                                          margin: const EdgeInsets.only(bottom: 20),
                                          color: i < currentStep ? blue : Colors.grey[200],
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            if (order.status == 'ACCEPTED' || order.status == 'PICKED') ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.motorcycle, color: blue, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            order.status == 'ACCEPTED'
                                                ? 'Rider is heading to pickup location'
                                                : 'Rider has picked up your item and is on the way',
                                            style: const TextStyle(fontSize: 12, color: blue),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (order.riderName != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, color: blue, size: 16),
                                          const SizedBox(width: 8),
                                          Text('Rider: ${order.riderName}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          if (order.riderPhone != null)
                                            GestureDetector(
                                              onTap: () async {
                                                final uri = Uri.parse('tel:${order.riderPhone}');
                                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.call, color: Colors.white, size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(order.riderPhone!,
                                                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

// ── WALLET TAB ──
class _WalletTab extends StatefulWidget {
  final dynamic auth;
  const _WalletTab({required this.auth});

  @override
  State<_WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<_WalletTab> {
  double _balance = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final res = await ApiService.get('/wallet', token: widget.auth.token);
      setState(() {
        _balance = (res['balance'] as num).toDouble();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBalance,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A8F), Color(0xFF0D2260)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wallet Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('₦${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              isScrollControlled: true,
                              builder: (_) => _TopUpSheet(
                                auth: widget.auth,
                                onSuccess: _loadBalance,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Top Up'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadBalance,
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Transactions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('No transactions yet',
                            style: TextStyle(color: Colors.grey[400])),
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
}

// ── PROFILE TAB ──
class _ProfileTab extends StatelessWidget {
  final dynamic auth;
  const _ProfileTab({required this.auth});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

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
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                        color: blue.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        auth.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold, color: blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(auth.user?.name ?? 'Customer',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(auth.user?.phone ?? '',
                      style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Customer',
                        style: TextStyle(
                            color: blue, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _profileItem(Icons.person_outline, 'Edit Profile', blue, () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ProfileEditScreen()));
                  }),
                  _divider(),
                  _profileItem(Icons.notifications_outlined, 'Notifications', blue, () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()));
                  }),
                  _divider(),
                  _profileItem(Icons.help_outline, 'Help & Support', blue, () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen()));
                  }),
                  _divider(),
                  _profileItem(Icons.privacy_tip_outlined, 'Privacy Policy', blue, () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen()));
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

  Widget _profileItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              color: color == Colors.red ? Colors.red : Colors.black87)),
      trailing: color != Colors.red
          ? const Icon(Icons.chevron_right, color: Colors.grey, size: 18)
          : null,
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);
}
// ── TOP UP SHEET ──
class _TopUpSheet extends StatefulWidget {
  final dynamic auth;
  final VoidCallback onSuccess;
  const _TopUpSheet({required this.auth, required this.onSuccess});

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amountController = TextEditingController();
  final List<int> _quickAmounts = [500, 1000, 2000, 5000];
  bool _loading = false;

  Future<void> _processTopUp() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _loading = true);
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlutterwaveScreen(
          email: 'payments@ryaniva.com.ng',
          phone: widget.auth.user?.phone ?? '',
          name: widget.auth.user?.name ?? 'Ryaniva Customer',
          amount: amount,
          orderId: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
          paymentOption: 'card',
          onPaymentComplete: (success) async {
            if (success) {
              try {
                await ApiService.post('/wallet/topup', {
                  'amount': amount,
                  'reference': 'wallet_${DateTime.now().millisecondsSinceEpoch}',
                }, token: widget.auth.token);
                widget.onSuccess();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('₦${amount.toStringAsFixed(0)} added to wallet!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment received but wallet update failed. Contact support.')),
                  );
                }
              }
            }
          },
        ),
      ),
    );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Up Wallet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Select or enter amount to add to your wallet',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: _quickAmounts.map((amount) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() =>
                      _amountController.text = amount.toString()),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _amountController.text == amount.toString()
                          ? blue.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _amountController.text == amount.toString()
                            ? blue
                            : Colors.transparent,
                      ),
                    ),
                    child: Text('₦$amount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _amountController.text == amount.toString()
                              ? blue
                              : Colors.grey[700],
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Or enter custom amount',
              prefixText: '₦ ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.w600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: blue, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _amountController.text.isEmpty || _loading
                  ? null
                  : _processTopUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _amountController.text.isEmpty
                          ? 'Enter Amount'
                          : 'Top Up ₦${_amountController.text} via Flutterwave',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('Secured by Flutterwave',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}