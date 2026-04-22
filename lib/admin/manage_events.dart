import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import 'create_event.dart';

class ManageEventsScreen extends StatelessWidget {
  const ManageEventsScreen({super.key, this.isTab = false});

  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EventService>();
    final format = DateFormat('dd MMM yyyy');

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              'Manage Events',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Event'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (service.eventsError != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Could not load events from Firestore: ${service.eventsError}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        if (service.eventsError != null) const SizedBox(height: 10),
        if (service.events.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('No events found in collection "events".'),
            ),
          ),
        ...service.events.map(
          (event) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(event.category.emoji)),
              title: Text(event.title),
              subtitle: Text(
                '${event.category.label} • ${format.format(event.date)}\n${event.location} • ₹${event.price.toStringAsFixed(0)}',
              ),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateEventScreen(existingEvent: event),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => service.deleteEvent(event.id),
                    icon: const Icon(Icons.delete_outline_rounded),
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
      appBar: AppBar(title: const Text('Manage Events')),
      body: content,
    );
  }
}
