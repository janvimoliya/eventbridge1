import 'package:flutter/material.dart';

enum EventCategory { conference, wedding, concert, festival, workshop }

extension EventCategoryX on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.conference:
        return 'Conference';
      case EventCategory.wedding:
        return 'Wedding';
      case EventCategory.concert:
        return 'Concert';
      case EventCategory.festival:
        return 'Festival';
      case EventCategory.workshop:
        return 'Workshop';
    }
  }

  String get emoji {
    switch (this) {
      case EventCategory.conference:
        return '💼';
      case EventCategory.wedding:
        return '💍';
      case EventCategory.concert:
        return '🎶';
      case EventCategory.festival:
        return '🎉';
      case EventCategory.workshop:
        return '📚';
    }
  }

  IconData get icon {
    switch (this) {
      case EventCategory.conference:
        return Icons.business_center_rounded;
      case EventCategory.wedding:
        return Icons.favorite_rounded;
      case EventCategory.concert:
        return Icons.music_note_rounded;
      case EventCategory.festival:
        return Icons.celebration_rounded;
      case EventCategory.workshop:
        return Icons.menu_book_rounded;
    }
  }
}

class EventReview {
  const EventReview({
    required this.userName,
    required this.rating,
    required this.comment,
  });

  final String userName;
  final double rating;
  final String comment;
}

class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.schedule,
    required this.attendees,
    required this.ticketTypes,
    required this.isTrending,
    required this.reviews,
    required this.hasArVrPreview,
    required this.organizerName,
    required this.organizerVerified,
  });

  final String id;
  final String title;
  final EventCategory category;
  final DateTime date;
  final String location;
  final double price;
  final String imageUrl;
  final String description;
  final List<String> schedule;
  final List<String> attendees;
  final Map<String, double> ticketTypes;
  final bool isTrending;
  final List<EventReview> reviews;
  final bool hasArVrPreview;
  final String organizerName;
  final bool organizerVerified;

  double get averageRating {
    if (reviews.isEmpty) {
      return 0;
    }
    final total = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }
}
