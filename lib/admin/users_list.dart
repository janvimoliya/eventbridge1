import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/event_service.dart';
import 'user_activity_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key, this.isTab = false});

  final bool isTab;

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // all, blocked, organizer, verified

  static const String _adminEmail = 'admin@eventbridge.app';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUserModel> _getFilteredUsers(List<AppUserModel> users) {
    var filtered = users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.phone.contains(query);
      }).toList();
    }

    // Apply status filter
    switch (_filterType) {
      case 'blocked':
        filtered = filtered.where((user) => user.isBlocked).toList();
        break;
      case 'organizer':
        filtered = filtered.where((user) => user.isOrganizer).toList();
        break;
      case 'verified':
        filtered = filtered
            .where((user) => user.isOrganizer && user.isVerifiedOrganizer)
            .toList();
        break;
      default:
        break;
    }

    return filtered;
  }

  void _showCreateUserDialog(EventService service) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdminEmail =
        currentUser?.email?.toLowerCase() == _adminEmail.toLowerCase();

    if (!isAdminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admin access required to create users. Please sign in with admin@eventbridge.app.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CreateEditUserDialog(service: service, user: null),
    );
  }

  void _showEditUserDialog(EventService service, AppUserModel user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdminEmail =
        currentUser?.email?.toLowerCase() == _adminEmail.toLowerCase();

    if (!isAdminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admin access required to edit users. Please sign in with admin@eventbridge.app.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CreateEditUserDialog(service: service, user: user),
    );
  }

  void _showDeleteConfirmation(EventService service, AppUserModel user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdminEmail =
        currentUser?.email?.toLowerCase() == _adminEmail.toLowerCase();

    if (!isAdminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admin access required to delete users. Please sign in with admin@eventbridge.app.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await service.deleteUser(user.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.name} deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;
                Navigator.pop(context);

                String errorMessage = error.toString();

                if (errorMessage.contains('permission-denied')) {
                  errorMessage =
                      'Permission Denied: You don\'t have permission to delete users.';
                } else if (errorMessage.contains('not-found')) {
                  errorMessage = 'User not found.';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete user: $errorMessage'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EventService>();
    final filteredUsers = _getFilteredUsers(service.users);

    final content = Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Users Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateUserDialog(service),
                    icon: const Icon(Icons.add),
                    label: const Text('Add User'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats
              SizedBox(
                height: 120,
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Total Users',
                      value: service.totalUsers.toString(),
                      color: Colors.blue,
                      icon: Icons.people,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Blocked',
                      value: service.users
                          .where((u) => u.isBlocked)
                          .length
                          .toString(),
                      color: Colors.red,
                      icon: Icons.block,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Organizers',
                      value: service.users
                          .where((u) => u.isOrganizer)
                          .length
                          .toString(),
                      color: Colors.orange,
                      icon: Icons.event,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Search and Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterType == 'all',
                      onSelected: () {
                        setState(() => _filterType = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Blocked',
                      isSelected: _filterType == 'blocked',
                      onSelected: () {
                        setState(() => _filterType = 'blocked');
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Organizers',
                      isSelected: _filterType == 'organizer',
                      onSelected: () {
                        setState(() => _filterType = 'organizer');
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Verified',
                      isSelected: _filterType == 'verified',
                      onSelected: () {
                        setState(() => _filterType = 'verified');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Error message
        if (service.usersError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Could not load users: ${service.usersError}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Users list
        Expanded(
          child: filteredUsers.isEmpty
              ? _EmptyState(
                  message: _searchQuery.isEmpty
                      ? 'No users found'
                      : 'No users match your search',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _UserCard(
                      user: user,
                      service: service,
                      onEdit: () => _showEditUserDialog(service, user),
                      onDelete: () => _showDeleteConfirmation(service, user),
                      onViewActivity: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserActivityScreen(user: user),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.isTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: content,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.transparent,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[400]!,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onViewActivity,
  });

  final AppUserModel user;
  final EventService service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewActivity;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and avatar
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status badges
            Wrap(
              spacing: 8,
              children: [
                if (user.isBlocked)
                  _StatusBadge(
                    label: 'Blocked',
                    color: Colors.red,
                    icon: Icons.block,
                  ),
                if (user.isOrganizer)
                  _StatusBadge(
                    label: user.isVerifiedOrganizer
                        ? 'Verified Organizer'
                        : 'Organizer',
                    color: Colors.orange,
                    icon: Icons.event,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Bookings',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        user.totalBookings.toString(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Spent',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '₹${user.totalSpent.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onViewActivity,
                    icon: const Icon(Icons.history),
                    label: const Text('Activity'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => service.toggleUserBlocked(user.id),
                    icon: Icon(user.isBlocked ? Icons.lock_open : Icons.lock),
                    label: Text(user.isBlocked ? 'Unblock' : 'Block'),
                  ),
                  if (user.isOrganizer) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () =>
                          service.toggleOrganizerVerification(user.id),
                      child: Text(
                        user.isVerifiedOrganizer ? 'Remove Badge' : 'Verify',
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CreateEditUserDialog extends StatefulWidget {
  const _CreateEditUserDialog({required this.service, required this.user});

  final EventService service;
  final AppUserModel? user;

  @override
  State<_CreateEditUserDialog> createState() => _CreateEditUserDialogState();
}

class _CreateEditUserDialogState extends State<_CreateEditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late bool _isOrganizer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _isOrganizer = widget.user?.isOrganizer ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdminEmail =
        currentUser?.email?.toLowerCase() ==
        _UsersListScreenState._adminEmail.toLowerCase();

    if (!isAdminEmail) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Admin access required. Please sign in with admin@eventbridge.app.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (widget.user == null) {
        // Create new user
        await widget.service
            .createUser(
              name: name,
              email: email,
              phone: phone,
              isOrganizer: _isOrganizer,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'Operation timed out. Please check your internet connection and try again.',
                );
              },
            );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name created successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Update existing user
        await widget.service
            .updateUser(
              userId: widget.user!.id,
              name: name,
              email: email,
              phone: phone,
              isOrganizer: _isOrganizer,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'Operation timed out. Please check your internet connection and try again.',
                );
              },
            );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      String errorMessage = error.toString();

      // Provide user-friendly error messages
      if (errorMessage.contains('permission-denied')) {
        errorMessage =
            'Permission Denied: Your account doesn\'t have admin access. Please contact the system administrator to enable admin permissions.';
      } else if (errorMessage.contains('INVALID_ARGUMENT')) {
        errorMessage =
            'Invalid data provided. Please check all fields and try again.';
      } else if (errorMessage.contains('ALREADY_EXISTS')) {
        errorMessage = 'User with this email already exists.';
      } else if (errorMessage.contains('TimeoutException') ||
          errorMessage.contains('timed out')) {
        errorMessage =
            'Operation took too long. Please check your internet connection and try again.';
      } else if (errorMessage.contains('Network')) {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      // Ensure loading state is cleared
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.user != null;

    return AlertDialog(
      title: Text(isEditMode ? 'Edit User' : 'Create New User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              enabled: !_isLoading,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              enabled: !_isLoading,
              title: const Text('Mark as Organizer'),
              value: _isOrganizer,
              onChanged: (value) {
                setState(() => _isOrganizer = value ?? false);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditMode ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
