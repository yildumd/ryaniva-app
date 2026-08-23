import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../payment/flutterwave_screen.dart';
import '../payment/bank_transfer_screen.dart';
import '../../services/location_storage.dart';

class CreateOrderScreen extends StatefulWidget {
  final String? preselectedType;
  const CreateOrderScreen({super.key, this.preselectedType});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _itemTypeController = TextEditingController();
  final _noteController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
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
  List<Map<String, dynamic>> _savedLocations = [];

  Map<String, double> _getJosCoordinates(String address) {
    final a = address.toLowerCase();
    if (a.contains('rayfield')) return {'lat': 9.8734, 'lng': 8.9012};
    if (a.contains('terminus')) return {'lat': 9.8965, 'lng': 8.8583};
    if (a.contains('bukuru')) return {'lat': 9.7934, 'lng': 8.8521};
    if (a.contains('juth') || a.contains('teaching hospital')) return {'lat': 9.9012, 'lng': 8.8734};
    if (a.contains('unijos') || a.contains('university of jos')) return {'lat': 9.9285, 'lng': 8.8921};
    if (a.contains('angwan rogo')) return {'lat': 9.9123, 'lng': 8.8456};
    if (a.contains('tudun wada')) return {'lat': 9.9234, 'lng': 8.8678};
    if (a.contains('nassarawa')) return {'lat': 9.8823, 'lng': 8.8934};
    if (a.contains('vom')) return {'lat': 9.7234, 'lng': 8.8123};
    if (a.contains('barkin ladi')) return {'lat': 9.5234, 'lng': 8.9012};
    if (a.contains('farin gada')) return {'lat': 9.9345, 'lng': 8.8234};
    if (a.contains('apata')) return {'lat': 9.8456, 'lng': 8.8345};
    if (a.contains('gwong')) return {'lat': 9.9012, 'lng': 8.8567};
    if (a.contains('kabong')) return {'lat': 9.8678, 'lng': 8.8789};
    if (a.contains('dadin kowa')) return {'lat': 9.8234, 'lng': 8.8456};
    if (a.contains('anglo')) return {'lat': 9.8567, 'lng': 8.8678};
    if (a.contains('zaria road')) return {'lat': 9.9456, 'lng': 8.8345};
    if (a.contains('bauchi road')) return {'lat': 9.9567, 'lng': 8.8901};
    if (a.contains('rukuba')) return {'lat': 9.9123, 'lng': 8.8234};
    if (a.contains('lamingo')) return {'lat': 9.9234, 'lng': 8.9123};
    if (a.contains('rikkos')) return {'lat': 9.8901, 'lng': 8.8456};
    if (a.contains('kwararafa')) return {'lat': 9.8789, 'lng': 8.8567};
    if (a.contains('tafawa balewa')) return {'lat': 9.8678, 'lng': 8.8456};
    if (a.contains('plateau hospital')) return {'lat': 9.8901, 'lng': 8.8678};
    if (a.contains('airport')) return {'lat': 9.8678, 'lng': 8.9234};
    return {'lat': 9.8965, 'lng': 8.8583};
  }

  Future<void> _getCurrentLocation(bool isPickup) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Getting your exact location...')),
        );
      }

      Position? lastPosition;
try {
  lastPosition = await Geolocator.getLastKnownPosition();
} catch (e) {
  lastPosition = null;
}

final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.bestForNavigation,
  timeLimit: const Duration(seconds: 15),
);

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&format=json'
        '&addressdetails=1',
      );

      final res = await http.get(url, headers: {
        'User-Agent': 'RyanivaApp/1.0 (contact@ryaniva.com)',
      });

      String address =
          'My Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['display_name'] != null) {
          address = data['display_name'];
        }
      }

      if (isPickup) {
        setState(() {
          _pickupController.text = address;
          _pickupLat = position.latitude;
          _pickupLng = position.longitude;
          _showPickupSuggestions = false;
        });
      } else {
        setState(() {
          _dropoffController.text = address;
          _dropoffLat = position.latitude;
          _dropoffLng = position.longitude;
          _showDropoffSuggestions = false;
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Location set with ${position.accuracy.toStringAsFixed(0)}m accuracy'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not get location. Please try again.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _itemTypeController.text = widget.preselectedType!;
    }
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    final locations = await LocationStorage.getSavedLocations();
    setState(() {
      _savedLocations = locations
          .map((l) => {
                'display_name': l.address,
                'lat': l.lat,
                'lon': l.lng,
                'name': l.name,
              })
          .toList();
    });
  }

  Future<List<Map<String, dynamic>>> _searchAddress(String query) async {
    if (query.trim().length < 3) return [];
    try {
      const apiKey = 'AIzaSyCI8Y_XNplWLmrhYcmyZTj3hQy0dKIYgSM';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&components=country:ng'
        '&location=9.8965,8.8583'
        '&radius=50000'
        '&key=$apiKey',
      );
      final res = await http.get(url);
      print('Places API status: ${res.statusCode}');
      print('Places API body: ${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('Places status: ${data['status']}');
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          final results = <Map<String, dynamic>>[];
          for (final p in predictions) {
            final placeId = p['place_id'];
            final detailUrl = Uri.parse(
              'https://maps.googleapis.com/maps/api/place/details/json'
              '?place_id=$placeId'
              '&fields=geometry,formatted_address'
              '&key=$apiKey',
            );
            final detailRes = await http.get(detailUrl);
            if (detailRes.statusCode == 200) {
              final detail = jsonDecode(detailRes.body);
              if (detail['status'] == 'OK') {
                final loc = detail['result']['geometry']['location'];
                results.add({
                  'display_name': p['description'],
                  'lat': loc['lat'],
                  'lon': loc['lng'],
                });
              }
            }
          }
          return results;
        }
      }
    } catch (e) {
      // silent fail
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

  void _selectPickup(Map<String, dynamic> suggestion) async {
    setState(() {
      _pickupController.text = suggestion['display_name'];
      _pickupLat = suggestion['lat'];
      _pickupLng = suggestion['lon'];
      _showPickupSuggestions = false;
    });
    await LocationStorage.saveLocation(SavedLocation(
      name: suggestion['display_name'].toString().split(',')[0],
      address: suggestion['display_name'],
      lat: suggestion['lat'],
      lng: suggestion['lon'],
    ));
    _loadSavedLocations();
  }

  void _selectDropoff(Map<String, dynamic> suggestion) async {
    setState(() {
      _dropoffController.text = suggestion['display_name'];
      _dropoffLat = suggestion['lat'];
      _dropoffLng = suggestion['lon'];
      _showDropoffSuggestions = false;
    });
    await LocationStorage.saveLocation(SavedLocation(
      name: suggestion['display_name'].toString().split(',')[0],
      address: suggestion['display_name'],
      lat: suggestion['lat'],
      lng: suggestion['lon'],
    ));
    _loadSavedLocations();
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
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return ListTile(
            dense: true,
            leading:
                Icon(Icons.location_on_outlined, color: iconColor, size: 20),
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
    const green = Color(0xFF10B981);

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
              // PICKUP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pickup Location',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  TextButton.icon(
                    onPressed: () => _getCurrentLocation(true),
                    icon: const Icon(Icons.my_location,
                        size: 14, color: blue),
                    label: const Text('Use my location',
                        style: TextStyle(fontSize: 12, color: blue)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pickupController,
                onChanged: _onPickupChanged,
                decoration: InputDecoration(
                  hintText: 'Type or tap "Use my location"',
                  prefixIcon:
                      const Icon(Icons.radio_button_checked, color: blue),
                  suffixIcon: _pickupLat != null
                      ? const Icon(Icons.check_circle,
                          color: Colors.green, size: 18)
                      : const Icon(Icons.edit_location_outlined,
                          color: Colors.grey, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                ),
              ),
              if (_showPickupSuggestions)
                _buildSuggestionsList(
                    _pickupSuggestions, _selectPickup, blue),

              const SizedBox(height: 20),

              // DROPOFF
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Drop-off Location',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  TextButton.icon(
                    onPressed: () => _getCurrentLocation(false),
                    icon: const Icon(Icons.my_location,
                        size: 14, color: orange),
                    label: const Text('Use my location',
                        style: TextStyle(fontSize: 12, color: orange)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dropoffController,
                onChanged: _onDropoffChanged,
                decoration: InputDecoration(
                  hintText: 'Type or tap "Use my location"',
                  prefixIcon:
                      const Icon(Icons.location_on, color: orange),
                  suffixIcon: _dropoffLat != null
                      ? const Icon(Icons.check_circle,
                          color: Colors.green, size: 18)
                      : const Icon(Icons.edit_location_outlined,
                          color: Colors.grey, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                ),
              ),
              if (_showDropoffSuggestions)
                _buildSuggestionsList(
                    _dropoffSuggestions, _selectDropoff, orange),

              const SizedBox(height: 20),

              // ITEM TYPE
              const Text('Item Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _itemTypeController,
                decoration: InputDecoration(
                  hintText: 'e.g. parcel, food, documents',
                  prefixIcon:
                      const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // NOTE
              const Text('Note (optional)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Any special instructions?',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // RECIPIENT CONTACT
const Text('Recipient Name',
    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
const SizedBox(height: 8),
TextField(
  controller: _recipientNameController,
  decoration: InputDecoration(
    hintText: 'Name of person receiving the item',
    prefixIcon: const Icon(Icons.person_outline),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: blue, width: 2),
    ),
  ),
),
const SizedBox(height: 16),
const Text('Recipient Phone',
    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
const SizedBox(height: 8),
TextField(
  controller: _recipientPhoneController,
  keyboardType: TextInputType.phone,
  decoration: InputDecoration(
    hintText: 'Phone number of recipient',
    prefixIcon: const Icon(Icons.phone_outlined),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: blue, width: 2),
    ),
  ),
),
              // PAYMENT METHOD
              const Text('Payment Method',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  // CASH
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _paymentMethod = 'CASH'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                                    : Colors.grey,
                                size: 24),
                            const SizedBox(height: 4),
                            Text('Cash',
                                style: TextStyle(
                                    color: _paymentMethod == 'CASH'
                                        ? blue
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('On delivery',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // CARD
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _paymentMethod = 'CARD'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                                    : Colors.grey,
                                size: 24),
                            const SizedBox(height: 4),
                            Text('Card',
                                style: TextStyle(
                                    color: _paymentMethod == 'CARD'
                                        ? orange
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('Via Flutterwave',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // TRANSFER
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _paymentMethod = 'TRANSFER'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _paymentMethod == 'TRANSFER'
                              ? green.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _paymentMethod == 'TRANSFER'
                                ? green
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.account_balance,
                                color: _paymentMethod == 'TRANSFER'
                                    ? green
                                    : Colors.grey,
                                size: 24),
                            const SizedBox(height: 4),
                            Text('Transfer',
                                style: TextStyle(
                                    color: _paymentMethod == 'TRANSFER'
                                        ? green
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('Bank transfer',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // CONFIRM BUTTON
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
        content: Text(
            'Please fill all required fields')),
  );
  return;
}
if (_recipientNameController.text.trim().isEmpty ||
    _recipientPhoneController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
        content: Text(
            'Please enter recipient name and phone number')),
  );
  return;
}

                          // Use landmark coords if no GPS selected
                          if (_pickupLat == null) {
                            final coords = _getJosCoordinates(
                                _pickupController.text);
                            _pickupLat = coords['lat'];
                            _pickupLng = coords['lng'];
                          }
                          if (_dropoffLat == null) {
                            final coords = _getJosCoordinates(
                                _dropoffController.text);
                            _dropoffLat = coords['lat'];
                            _dropoffLng = coords['lng'];
                          }

                          final result = await orders.createOrder(
                            token: auth.token,
                            pickupLat: _pickupLat!,
                            pickupLng: _pickupLng!,
                            pickupAddress: _pickupController.text.trim(),
                            dropoffLat: _dropoffLat!,
                            dropoffLng: _dropoffLng!,
                            dropoffAddress:
                                _dropoffController.text.trim(),
                            itemType: _itemTypeController.text.trim(),
                            paymentMethod: _paymentMethod == 'TRANSFER'
                                ? 'CARD'
                                : _paymentMethod,
                            itemNote: _noteController.text.trim(),
                            senderPhone: auth.user?.phone ?? '',
recipientName: _recipientNameController.text.trim(),
recipientPhone: _recipientPhoneController.text.trim(),
                          );

                          if (result != null &&
                              result['order'] != null &&
                              context.mounted) {
                            final breakdown = result['breakdown'];
                            final order = result['order'];
                            final totalAmount =
                                (breakdown['total'] as num).toDouble();

                            if (_paymentMethod == 'TRANSFER') {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FlutterwaveScreen(
        email: 'payments@ryaniva.com.ng',
        phone: auth.user?.phone ?? '',
        name: auth.user?.name ?? 'Ryaniva Customer',
        amount: totalAmount,
        orderId: order['id'],
        paymentOption: 'banktransfer',
        onPaymentComplete: (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? '✅ Payment successful!'
                    : '❌ Payment cancelled'),
                backgroundColor: success ? Colors.green : Colors.red,
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
                                    paymentOption: 'card',
                                    onPaymentComplete: (success) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
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

                            // CASH
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  title:
                                      const Text('Order Confirmed! 🎉'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Distance: ${breakdown['distanceKm']} km'),
                                      Text(
                                          'Base fare: ₦${breakdown['baseFare']}'),
                                      Text(
                                          'Distance fare: ₦${breakdown['distanceFare']}'),
                                      const Divider(),
                                      Text(
                                          'Total: ₦${breakdown['total']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE85C1A),
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
                                                color: Colors.orange,
                                                size: 16),
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
                                          style:
                                              TextStyle(color: Color(0xFF1A3A8F))),
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
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Confirm Delivery',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            if (_paymentMethod == 'CARD' ||
                                _paymentMethod == 'TRANSFER') ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.lock_outline, size: 16),
                            ]
                          ],
                        ),
                ),
              ),
              if (_paymentMethod == 'CARD' ||
                  _paymentMethod == 'TRANSFER') ...[
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text('Secured by Flutterwave',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 12)),
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