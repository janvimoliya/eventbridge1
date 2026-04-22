import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import 'custom_button.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onBookNow,
    required this.onTap,
    required this.isWishlisted,
    required this.onWishlist,
  });

  final EventModel event;
  final VoidCallback onBookNow;
  final VoidCallback onTap;
  final bool isWishlisted;
  final VoidCallback onWishlist;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  Image.network(
                    event.imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        onPressed: onWishlist,
                        icon: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted
                              ? const Color(0xFFFF6F61)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.category.emoji} ${event.title}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat('EEE, d MMM y').format(event.date)} • ${event.location}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 18),
                      Text(
                        event.price.toStringAsFixed(0),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(event.averageRating.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomButton(label: 'Book Now', onPressed: onBookNow),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
