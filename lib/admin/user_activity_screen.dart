import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/user_activity.dart';
import '../services/event_service.dart';

class UserActivityScreen extends StatefulWidget {
  const UserActivityScreen({super.key, required this.user});

  final AppUserModel user;

  @override
  State<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends State<UserActivityScreen> {
  late Future<List<UserActivity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = context.read<EventService>().getUserActivities(
      widget.user.id,
    );
  }

  String _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'booking_created':
        return '🎫';
      case 'event_viewed':
        return '👁️';
      case 'wishlist_added':
        return '❤️';
      case 'wishlist_removed':
        return '💔';
      case 'login':
        return '🔐';
      case 'user_created':
        return '👤';
      case 'user_updated':
        return '✏️';
      default:
        return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.name} - Activity'),
        elevation: 0,
      ),
      body: FutureBuilder<List<UserActivity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading activities: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _activitiesFuture = context
                            .read<EventService>()
                            .getUserActivities(widget.user.id);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activities yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User activities will appear here',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final format = DateFormat('MMM d, y • h:mm a');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getActivityIcon(activity.activityType),
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.description,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  format.format(activity.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getChipColor(activity.activityType),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activity.activityType
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (activity.details != null &&
                          activity.details!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Details',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              for (final entry in activity.details!.entries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${entry.key}:',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      Text(
                                        entry.value.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getChipColor(String activityType) {
    switch (activityType) {
      case 'booking_created':
        return Colors.green;
      case 'event_viewed':
        return Colors.blue;
      case 'wishlist_added':
        return Colors.pink;
      case 'wishlist_removed':
        return Colors.orange;
      case 'login':
        return Colors.purple;
      case 'user_created':
      case 'user_updated':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
