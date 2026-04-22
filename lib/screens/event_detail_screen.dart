import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/event_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import 'booking_screen.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final event = context.read<EventProvider>().findById(eventId);
    final isWishlisted = context.watch<UserProvider>().isWishlisted(event.id);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.title),
          actions: [
            IconButton(
              icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border),
              onPressed: () =>
                  context.read<UserProvider>().toggleWishlist(event.id),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Schedule'),
              Tab(text: 'Attendees'),
              Tab(text: 'Tickets'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          event.imageUrl,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(event.description),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(DateFormat('EEE, d MMM y').format(event.date)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 6),
                          Expanded(child: Text(event.location)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${event.averageRating.toStringAsFixed(1)} (${event.reviews.length} reviews)',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text('Organizer: ${event.organizerName}'),
                          ),
                          if (event.organizerVerified)
                            const Chip(
                              avatar: Icon(
                                Icons.verified_rounded,
                                color: Colors.blue,
                              ),
                              label: Text('Verified Organizer'),
                            ),
                          Chip(
                            label: Text(
                              event.hasArVrPreview
                                  ? 'AR/VR Venue Preview Available'
                                  : 'No AR/VR Preview',
                            ),
                          ),
                          const Chip(
                            label: Text('Calendar Sync: Google / Outlook'),
                          ),
                          const Chip(label: Text('Conflict Detection Enabled')),
                          const Chip(label: Text('Dynamic Pricing Supported')),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Ratings & Reviews',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...event.reviews.map(
                        (review) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(review.userName),
                          subtitle: Text(review.comment),
                          trailing: Text(
                            '⭐ ${review.rating.toStringAsFixed(1)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: event.schedule
                        .map(
                          (item) => ListTile(
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(item),
                          ),
                        )
                        .toList(),
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Attendee Networking & Communities'),
                      const SizedBox(height: 12),
                      ...event.attendees
                          .map(
                            (person) => ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(person),
                              subtitle: const Text(
                                'Tap to connect in in-app chat',
                              ),
                              trailing: const Icon(
                                Icons.chat_bubble_outline_rounded,
                              ),
                            ),
                          ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...event.ticketTypes.entries.map(
                        (entry) => Card(
                          child: ListTile(
                            title: Text(entry.key),
                            subtitle: const Text(
                              'Includes event entry + reminders',
                            ),
                            trailing: Text(
                              '₹${entry.value.toStringAsFixed(0)}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ListTile(
                        title: Text('Premium Plans'),
                        subtitle: Text(
                          'VIP membership and monthly/yearly unlimited booking packs.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                label: 'Book Now',
                icon: Icons.confirmation_num_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(eventId: event.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
