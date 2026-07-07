import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _notifItem(
            icon: Icons.local_shipping_outlined,
            color: blue,
            title: 'Order Delivered',
            message: 'Your delivery has been completed successfully.',
            time: 'Just now',
            isRead: false,
          ),
          _notifItem(
            icon: Icons.motorcycle_outlined,
            color: Colors.orange,
            title: 'Rider On The Way',
            message: 'Your rider has accepted the order and is heading to pickup.',
            time: '2 hours ago',
            isRead: false,
          ),
          _notifItem(
            icon: Icons.check_circle_outline,
            color: Colors.green,
            title: 'Order Confirmed',
            message: 'Your delivery request was confirmed.',
            time: 'Yesterday',
            isRead: true,
          ),
          _notifItem(
            icon: Icons.star_outline,
            color: Colors.amber,
            title: 'Rate Your Rider',
            message: 'How was your last delivery? Tap to rate your rider.',
            time: '2 days ago',
            isRead: true,
          ),
        ],
      ),
    );
  }

  Widget _notifItem({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFF1A3A8F).withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? Colors.transparent : const Color(0xFF1A3A8F).withOpacity(0.15),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A))),
                    if (!isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A3A8F),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
                const SizedBox(height: 6),
                Text(time,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}