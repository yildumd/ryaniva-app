import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    final sections = [
      {
        'title': 'Introduction',
        'content':
            'Ryaniva ("we," "our," or "us") is committed to protecting your privacy and handling your personal information responsibly. This Privacy Policy explains how we collect, use, disclose, and safeguard your personal information when you use our website, mobile application, or logistics services.\n\nThis Privacy Policy is prepared in accordance with the Nigeria Data Protection Act (NDPA) 2023 and other applicable laws.',
      },
      {
        'title': 'Information We Collect',
        'content':
            '• Full name, phone number, and email address\n• Pickup and delivery addresses\n• Payment information (processed securely through our payment service providers)\n• Real-time location data (where permission is granted)\n• Device and usage information\n• Communications with our customer support team',
      },
      {
        'title': 'How We Use Your Information',
        'content':
            '• Provide and manage our delivery services\n• Process payments and transactions\n• Track deliveries and improve customer experience\n• Communicate important updates regarding your orders\n• Prevent fraud and enhance security\n• Meet legal and regulatory obligations',
      },
      {
        'title': 'Sharing Your Information',
        'content':
            'We do not sell your personal information. We may share your information only with:\n• Delivery riders and logistics partners to complete your orders\n• Trusted third-party service providers supporting our operations\n• Payment service providers\n• Government agencies or regulators where required by law',
      },
      {
        'title': 'Data Security',
        'content':
            'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
      },
      {
        'title': 'Your Rights',
        'content':
            '• Access your personal information\n• Request correction of inaccurate information\n• Request deletion of your personal information where applicable\n• Withdraw consent where processing is based on consent\n• Lodge a complaint with the relevant data protection authority',
      },
      {
        'title': 'Data Retention',
        'content':
            'We retain your personal information only for as long as necessary to provide our services, comply with legal obligations, resolve disputes, and enforce our agreements.',
      },
      {
        'title': 'Cookies',
        'content':
            'Our website and mobile application may use cookies and similar technologies to improve functionality, remember your preferences, and enhance your user experience.',
      },
      {
        'title': 'Changes to This Privacy Policy',
        'content':
            'We may update this Privacy Policy from time to time. Any changes will be posted on our website or mobile application with the updated effective date.',
      },
      {
        'title': 'Contact Us',
        'content':
            'Ryaniva Business Services\nEmail: info@ryaniva.com.ng\nWebsite: ryaniva.com.ng\nLocation: Jos, Plateau State, Nigeria',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('Privacy Policy',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: blue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Effective Date: July 2026\nPrepared under the Nigeria Data Protection Act (NDPA) 2023',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...sections.map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: orange.withOpacity(0.3), width: 2),
                      ),
                    ),
                    child: Text(
                      section['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2260),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    section['content']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2026 Ryaniva Business Services. All rights reserved.',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}