class Order {
  final String id;
  final String customerId;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String itemType;
  final String? itemNote;
  final String? senderPhone;
  final String? recipientName;
  final String? recipientPhone;
  final String? cancelReason;
  final double distanceKm;
  final double price;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String createdAt;

  Order({
    required this.id,
    required this.customerId,
    this.riderId,
    this.riderName,
    this.riderPhone,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.itemType,
    this.itemNote,
    this.senderPhone,
    this.recipientName,
    this.recipientPhone,
    this.cancelReason,
    required this.distanceKm,
    required this.price,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rider = json['rider'];
    return Order(
      id: json['id'],
      customerId: json['customerId'],
      riderId: json['riderId'],
      riderName: rider?['user']?['name'],
      riderPhone: rider?['user']?['phone'],
      pickupAddress: json['pickupAddress'],
      dropoffAddress: json['dropoffAddress'],
      pickupLat: json['pickupLat'].toDouble(),
      pickupLng: json['pickupLng'].toDouble(),
      dropoffLat: json['dropoffLat'].toDouble(),
      dropoffLng: json['dropoffLng'].toDouble(),
      itemType: json['itemType'],
      itemNote: json['itemNote'],
      senderPhone: json['senderPhone'],
      recipientName: json['recipientName'],
      recipientPhone: json['recipientPhone'],
      cancelReason: json['cancelReason'],
      distanceKm: json['distanceKm'].toDouble(),
      price: json['price'].toDouble(),
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      createdAt: json['createdAt'],
    );
  }
}