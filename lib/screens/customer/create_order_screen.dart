import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../payment/flutterwave_screen.dart';

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

  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;

  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _dropoffSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropoffSuggestions = false;
  Timer? _pickupDebounce;
  Timer? _dropoffDebounce;

  // Bounding box around Jos, Plateau State to bias results
  static const String _josViewbox = '8.6,9.7,9.1,10.1';

  Future<List<Map<String, dynamic>>> _searchAddress(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=5'
        '&countrycodes=ng'
        '&viewbox=$_josViewbox'
        '&bounded=0',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'RyanivaApp/1.0 (contact@ryaniva.com)',
      });
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map<Map<String, dynamic>>((item) => {
              'display_name': item['display_name'],
              'lat': double.parse(item['lat']),
              'lon': double.parse(item['lon']),
            }).toList();
      }
    } catch (e) {
      // silent fail, suggestions just won't show
    }
    return [];
  }

void _onPickupChanged(String value) {
    _pickupDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _showPickupSuggestions = false);
      return;
    }
    _pickupDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await _searchAddress(value);
      if (mounted) {
        setState(() {
          _pickupSuggestions = results;
          _showPickupSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  void _onDropoffChanged(String value) {
    _dropoffDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _showDropoffSuggestions = false);
      return;
    }
    _dropoffDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await _searchAddress(value);
      if (mounted) {
        setState(() {
          _dropoffSuggestions = results;
          _showDropoffSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  void _selectPickup(Map<String, dynamic> suggestion) {
    setState(() {
      _pickupController.text = suggestion['display_name'];
      _pickupLat = suggestion['lat'];
      _pickupLng = suggestion['lon'];
      _showPickupSuggestions = false;
    });
  }

  void _selectDropoff(Map<String, dynamic> suggestion) {
    setState(() {
      _dropoffController.text = suggestion['display_name'];
      _dropoffLat = suggestion['lat'];
      _dropoffLng = suggestion['lon'];
      _showDropoffSuggestions = false;
    });
  }

  @override
  void dispose() {
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
    super.dispose();
  }

  Widget _buildSuggestionsList(List<Map<String, dynamic>> suggestions,
      Function(Map<String, dynamic>) onSelect, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return ListTile(
            dense: true,
            leading: Icon(Icons.location_on_outlined, color: iconColor, size: 20),
            title: Text(
              s['display_name'],
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSelect(s),
          );
        },
      ),
    );
  }

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
      body: GestureDetector(
        onTap: () => setState(() {
          _showPickupSuggestions = false;
          _showDropoffSuggestions = false;
        }),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pickup Location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _pickupController,
                onChanged: _onPickupChanged,
                decoration: InputDecoration(
                  hintText: 'Start typing e.g. Terminus, Bukuru, Rayfield...',
                  prefixIcon: const Icon(Icons.radio_button_checked, color: blue),
                  suffixIcon: _pickupLat != null
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                ),
              ),
              if (_showPickupSuggestions)
                _buildSuggestionsList(_pickupSuggestions, _selectPickup, blue),

              const SizedBox(height: 20),
              const Text('Drop-off Location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _dropoffController,
                onChanged: _onDropoffChanged,
                decoration: InputDecoration(
                  hintText: 'Start typing e.g. University of Jos...',
                  prefixIcon: const Icon(Icons.location_on, color: orange),
                  suffixIcon: _dropoffLat != null
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                ),
              ),
              if (_showDropoffSuggestions)
                _buildSuggestionsList(_dropoffSuggestions, _selectDropoff, orange),

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
                            color: _paymentMethod == 'CASH' ? blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.money,
                                color: _paymentMethod == 'CASH' ? blue : Colors.grey),
                            const SizedBox(height: 4),
                            Text('Cash',
                                style: TextStyle(
                                  color: _paymentMethod == 'CASH' ? blue : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 2),
                            Text('Pay on delivery',
                                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
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
                            color: _paymentMethod == 'CARD' ? orange : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.credit_card,
                                color: _paymentMethod == 'CARD' ? orange : Colors.grey),
                            const SizedBox(height: 4),
                            Text('Card / Transfer',
                                style: TextStyle(
                                  color: _paymentMethod == 'CARD' ? orange : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                )),
                            const SizedBox(height: 2),
                            Text('Via Flutterwave',
                                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
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
                                  content: Text('Please fill all required fields')),
                            );
                            return;
                          }

                          if (_pickupLat == null || _dropoffLat == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please select a location from the suggestions list')),
                            );
                            return;
                          }

                          final result = await orders.createOrder(
                            token: auth.token,
                            pickupLat: _pickupLat!,
                            pickupLng: _pickupLng!,
                            pickupAddress: _pickupController.text.trim(),
                            dropoffLat: _dropoffLat!,
                            dropoffLng: _dropoffLng!,
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

                            if (_paymentMethod == 'CARD') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FlutterwaveScreen(
                                    email: auth.user?.phone != null
                                        ? '${auth.user!.phone}@ryaniva.com'
                                        : 'customer@ryaniva.com',
                                    phone: auth.user?.phone ?? '',
                                    name: auth.user?.name ?? 'Ryaniva Customer',
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
                                      Text('Distance: ${breakdown['distanceKm']} km'),
                                      Text('Base fare: ₦${breakdown['baseFare']}'),
                                      Text('Distance fare: ₦${breakdown['distanceFare']}'),
                                      Text('Service charge: ₦${breakdown['platformFee']}'),
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
                                          borderRadius: BorderRadius.circular(8),
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
                                                    fontSize: 12, color: Colors.orange),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: orders.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Confirm Delivery',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                      Text('Secured by Flutterwave',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}