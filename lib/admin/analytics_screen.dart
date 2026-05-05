import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/event_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, this.isTab = false});

  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EventService>();
    final currency = NumberFormat.compactCurrency(
      symbol: '₹',
      decimalDigits: 0,
    );
    final revenueValues = service.monthlyRevenue.values.toList();
    final bookingValues = service.monthlyBookings.values.toList();
    final maxRevenue = revenueValues.isEmpty
        ? 1.0
        : revenueValues.reduce((a, b) => a > b ? a : b).toDouble();
    final maxBookings = bookingValues.isEmpty
        ? 1
        : bookingValues.reduce((a, b) => a > b ? a : b);

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Analytics', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Revenue Graph',
          children: service.monthlyRevenue.entries
              .map(
                (entry) => _BarTile(
                  label: entry.key,
                  value: currency.format(entry.value),
                  factor: maxRevenue <= 0
                      ? 0.1
                      : (entry.value / maxRevenue).clamp(0.1, 1.0),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Monthly Bookings',
          children: service.monthlyBookings.entries
              .map(
                (entry) => _BarTile(
                  label: entry.key,
                  value: '${entry.value}',
                  factor: maxBookings <= 0
                      ? 0.1
                      : (entry.value / maxBookings).clamp(0.1, 1.0),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Popular Events',
          children: service.events
              .take(3)
              .map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.category.label} • ₹${event.price.toStringAsFixed(0)}',
                  ),
                  trailing: const Icon(Icons.trending_up_rounded),
                ),
              )
              .toList(),
        ),
      ],
    );

    if (isTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: content,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BarTile extends StatelessWidget {
  const _BarTile({
    required this.label,
    required this.value,
    required this.factor,
  });

  final String label;
  final String value;
  final double factor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: factor, minHeight: 10),
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}
