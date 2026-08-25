import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A3A8F);
    const darkBlue = Color(0xFF0D2260);
    const orange = Color(0xFFE85C1A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: darkBlue,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          // ── LOGO ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/logo.png', height: 36,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                        color: orange, shape: BoxShape.circle),
                                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
                                  )),
                              const SizedBox(width: 10),
                              const Text('RYANIVA',
                                  style: TextStyle(color: Colors.white, fontSize: 26,
                                      fontWeight: FontWeight.w800, letterSpacing: 3)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: orange.withOpacity(0.4)),
                            ),
                            child: const Text('Now live in Jos, Nigeria',
                                style: TextStyle(color: orange, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),

                          const SizedBox(height: 48),

                          // ── HEADLINE ──
                          const Text('Fast delivery,\nanywhere in Jos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 32,
                                  fontWeight: FontWeight.w800, height: 1.2)),
                          const SizedBox(height: 14),
                          Text(
                            'Request a rider in seconds. Track every move in real time. Pay cash or card.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.55),
                                fontSize: 15, height: 1.6),
                          ),

                          const SizedBox(height: 40),

                          // ── STATS ROW ──
                          Row(
                            children: [
                              _stat('60s', 'Rider match', orange),
                              const SizedBox(width: 8),
                              _stat('24/7', 'Available', orange),
                              const SizedBox(width: 8),
                              _stat('Live', 'GPS tracking', orange),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // ── FEATURES ──
                          _feature(Icons.location_on_outlined, blue,
                              'Real-time tracking',
                              'Watch your rider on a live map from pickup to your door.'),
                          const SizedBox(height: 10),
                          _feature(Icons.payments_outlined, orange,
                              'Pay your way',
                              'Cash on delivery, card, or bank transfer — your choice.'),
                          const SizedBox(height: 10),
                          _feature(Icons.calculate_outlined, blue,
                              'Clear pricing',
                              '₦800 base fare + ₦150/km. See the exact price before confirming.'),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // ── BOTTOM BUTTONS ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                      color: darkBlue,
                      border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.08))),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity, height: 54,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Get Started',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity, height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const LoginScreen())),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.25)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('I already have an account',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _feature(IconData icon, Color color, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white,
                fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5),
                fontSize: 12, height: 1.4)),
          ],
        )),
      ]),
    );
  }
}