import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/event_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key, this.isTab = false});

  static const String routeName = '/wishlist';

  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final userProvider = context.watch<UserProvider>();
    final wishlistEvents = eventProvider.events
        .where((event) => userProvider.wishlistEventIds.contains(event.id))
        .toList();

    final content = wishlistEvents.isEmpty
        ? const Center(child: Text('No saved events yet.'))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: wishlistEvents
                .map(
                  (event) => EventCard(
                    event: event,
                    isWishlisted: true,
                    onWishlist: () {
                      userProvider.toggleWishlist(event).catchError((error) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_readableError(error))),
                        );
                      });
                    },
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: event.id),
                      ),
                    ),
                    onBookNow: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: event.id),
                      ),
                    ),
                  ),
                )
                .toList(),
          );

    if (isTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: content,
    );
  }

  String _readableError(Object error) {
    final raw = error.toString();
    return raw.replaceFirst('Exception: ', '');
  }
}
