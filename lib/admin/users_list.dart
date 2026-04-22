import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/event_service.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key, this.isTab = false});

  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EventService>();

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Users Management', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (service.usersError != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Could not load users from Firestore: ${service.usersError}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        if (service.usersError != null) const SizedBox(height: 10),
        if (service.users.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('No users found in collection "users".'),
            ),
          ),
        ...service.users.map(
          (user) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text(user.name.substring(0, 1))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('${user.email} • ${user.phone}'),
                          ],
                        ),
                      ),
                      if (user.isOrganizer)
                        Chip(
                          label: Text(
                            user.isVerifiedOrganizer
                                ? 'Verified Organizer'
                                : 'Organizer',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Bookings: ${user.totalBookings}   |   Total Spent: ₹${user.totalSpent.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => service.toggleUserBlocked(user.id),
                        child: Text(
                          user.isBlocked ? 'Unblock User' : 'Block User',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Viewing activity for ${user.name}',
                              ),
                            ),
                          );
                        },
                        child: const Text('View Activity'),
                      ),
                      if (user.isOrganizer)
                        FilledButton.tonal(
                          onPressed: () =>
                              service.toggleOrganizerVerification(user.id),
                          child: Text(
                            user.isVerifiedOrganizer
                                ? 'Remove Verified Badge'
                                : 'Mark Verified',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (isTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: content,
    );
  }
}
