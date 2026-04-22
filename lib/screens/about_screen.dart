import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String routeName = '/about';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'EventBridge',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'EventBridge is a modern event booking platform for seamless discovery, booking, and ticket management.',
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.flag_rounded),
            title: Text('Mission'),
            subtitle: Text(
              'To simplify event booking with secure payments, smart recommendations, and delightful UX.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.visibility_rounded),
            title: Text('Vision'),
            subtitle: Text(
              'To become the most trusted digital bridge between attendees and organizers.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.workspace_premium_rounded),
            title: Text('Premium'),
            subtitle: Text(
              'VIP memberships, subscriptions, dynamic pricing, and priority booking.',
            ),
          ),
        ],
      ),
    );
  }
}
