import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SavedLocation {
  final String name;
  final String address;
  final double lat;
  final double lng;

  SavedLocation({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    name: json['name'],
    address: json['address'],
    lat: json['lat'],
    lng: json['lng'],
  );
}

class LocationStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'saved_locations';

  static Future<List<SavedLocation>> getSavedLocations() async {
    try {
      final data = await _storage.read(key: _key);
      if (data == null) return [];
      final List list = jsonDecode(data);
      return list.map((e) => SavedLocation.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveLocation(SavedLocation location) async {
    try {
      final locations = await getSavedLocations();
      // Remove duplicate if exists
      locations.removeWhere((l) => l.address == location.address);
      // Add to front
      locations.insert(0, location);
      // Keep only last 5
      final trimmed = locations.take(5).toList();
      await _storage.write(key: _key, value: jsonEncode(trimmed.map((e) => e.toJson()).toList()));
    } catch (e) {
      // silent fail
    }
  }

  static Future<void> clearLocations() async {
    await _storage.delete(key: _key);
  }
}