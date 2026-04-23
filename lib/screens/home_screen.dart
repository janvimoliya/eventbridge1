import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/event_card.dart';
import '../widgets/wallet_balance.dart';
import 'event_detail_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final pages = [
      const HomeTab(),
      const SearchTab(),
      const WishlistScreen(isTab: true),
      const ProfileScreen(isTab: true),
      const WalletScreen(isTab: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () =>
                Navigator.of(context).pushNamed(NotificationsScreen.routeName),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: strings.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            label: strings.search,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border_rounded),
            label: strings.wishlist,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            label: strings.profile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: strings.wallet,
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final eventProvider = context.watch<EventProvider>();
    final userProvider = context.watch<UserProvider>();

    return RefreshIndicator(
      onRefresh: eventProvider.loadEvents,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (eventProvider.lastError != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${strings.couldNotLoadEventsFromFirestore} ${eventProvider.lastError}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          if (eventProvider.lastError != null) const SizedBox(height: 12),
          WalletBalance(balance: userProvider.walletBalance),
          const SizedBox(height: 16),
          Text(
            strings.categories,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(strings.all),
                    selected: eventProvider.activeCategory == null,
                    onSelected: (_) => eventProvider.setCategory(null),
                  ),
                ),
                ...eventProvider.categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${category.emoji} ${strings.categoryLabel(category)}',
                      ),
                      selected: eventProvider.activeCategory == category,
                      onSelected: (_) => eventProvider.setCategory(category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.trendingEvents,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 184,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: eventProvider.trendingEvents.length,
              itemBuilder: (context, index) {
                final event = eventProvider.trendingEvents[index];
                return Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(event.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          '₹${event.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.recommendedForYou,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...userProvider
              .personalizedRecommendations(eventProvider.events)
              .take(2)
              .map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(event.imageUrl),
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    '${strings.categoryLabel(event.category)} • ₹${event.price.toStringAsFixed(0)}',
                  ),
                ),
              ),
          const SizedBox(height: 8),
          Text(
            strings.allEvents,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (eventProvider.isLoading)
            const _EventShimmerList()
          else if (eventProvider.events.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(strings.noEventsFoundInFirestore),
              ),
            )
          else
            ...eventProvider.events.map(
              (event) => EventCard(
                event: event,
                isWishlisted: userProvider.isWishlisted(event.id),
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
                onTap: () => _openDetail(context, event),
                onBookNow: () => _openDetail(context, event),
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
    );
  }

  String _readableError(Object error) {
    final raw = error.toString();
    return raw.replaceFirst('Exception: ', '');
  }
}

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search events, locations, categories...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: eventProvider.setSearchQuery,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: eventProvider.events
                  .map(
                    (event) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(event.imageUrl),
                      ),
                      title: Text(event.title),
                      subtitle: Text(
                        '${event.location} • ₹${event.price.toStringAsFixed(0)}',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(eventId: event.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventShimmerList extends StatelessWidget {
  const _EventShimmerList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
