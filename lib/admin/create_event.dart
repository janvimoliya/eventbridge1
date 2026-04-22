import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, this.existingEvent});

  final EventModel? existingEvent;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _seatsController = TextEditingController();

  EventCategory _category = EventCategory.conference;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 5));

  @override
  void initState() {
    super.initState();
    final event = widget.existingEvent;
    if (event != null) {
      _titleController.text = event.title;
      _locationController.text = event.location;
      _priceController.text = event.price.toStringAsFixed(0);
      _descriptionController.text = event.description;
      _imageController.text = event.imageUrl;
      _seatsController.text = '100';
      _category = event.category;
      _selectedDate = event.date;
    } else {
      _imageController.text = 'https://images.unsplash.com/photo-1511578314322-379afb476865';
      _seatsController.text = '100';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<EventService>().upsertEvent(
          eventId: widget.existingEvent?.id,
          title: _titleController.text.trim(),
          category: _category,
          date: _selectedDate,
          location: _locationController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          description: _descriptionController.text.trim(),
          imageUrl: _imageController.text.trim(),
          seatCapacity: int.parse(_seatsController.text.trim()),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existingEvent == null
              ? 'Event published successfully.'
              : 'Event updated successfully.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent == null ? 'Create Event' : 'Edit Event'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Title is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EventCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: EventCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: const Text('Date'),
                  subtitle: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_month_rounded),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Location is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ticket Price ₹'),
                  validator: (value) {
                    final price = double.tryParse((value ?? '').trim());
                    if (price == null || price <= 0) {
                      return 'Enter a valid numeric price.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _seatsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Seat Capacity'),
                  validator: (value) {
                    final seats = int.tryParse((value ?? '').trim());
                    if (seats == null || seats <= 0) {
                      return 'Seats must be a positive number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Image URL is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Description is required.'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _publish,
                    child: const Text('Publish Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
