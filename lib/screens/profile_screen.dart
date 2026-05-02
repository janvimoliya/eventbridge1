import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../widgets/ticket_card.dart';
import 'about_screen.dart';
import 'accessibility_settings_screen.dart';
import 'contact_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isTab = false});

  final bool isTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSavingProfile = false;
  bool _isLoggingOut = false;

  void _openLogin() {
    Navigator.of(context).pushNamed(LoginScreen.routeName);
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    final strings = AppLocalizations.of(context);
    setState(() => _isLoggingOut = true);
    try {
      await context.read<UserProvider>().logout();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.loggedOutSuccessfully)));
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _openEditProfileDialog() async {
    final strings = AppLocalizations.of(context);
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user == null) {
      return;
    }

    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final photoController = TextEditingController(text: user.photoUrl);
    final formKey = GlobalKey<FormState>();
    final imagePicker = ImagePicker();
    Uint8List? pickedPhotoBytes;
    String? pickedPhotoExtension;
    bool removePhoto = false;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final canShowNetworkPhoto =
                !removePhoto &&
                pickedPhotoBytes == null &&
                photoController.text.trim().isNotEmpty;

            return AlertDialog(
              title: Text(strings.editProfile),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage: pickedPhotoBytes != null
                            ? MemoryImage(pickedPhotoBytes!)
                            : canShowNetworkPhoto
                            ? NetworkImage(photoController.text.trim())
                            : null,
                        child:
                            (pickedPhotoBytes == null && !canShowNetworkPhoto)
                            ? const Icon(Icons.person_outline, size: 32)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final picked = await imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                  maxWidth: 1280,
                                );
                                if (picked == null) {
                                  return;
                                }

                                final bytes = await picked.readAsBytes();
                                if (!dialogContext.mounted) {
                                  return;
                                }

                                setDialogState(() {
                                  pickedPhotoBytes = bytes;
                                  pickedPhotoExtension = _extractFileExtension(
                                    picked.name,
                                  );
                                  removePhoto = false;
                                });
                              } on PlatformException catch (error) {
                                if (!dialogContext.mounted) {
                                  return;
                                }

                                final message = (error.message ?? '')
                                    .toLowerCase();
                                final code = error.code.toLowerCase();
                                final isChannelError =
                                    code.contains('channel-error') ||
                                    message.contains(
                                      'unable to establish connection on channel',
                                    ) ||
                                    message.contains(
                                      'image_picker_android.imagepickerapi.pickimages',
                                    );

                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isChannelError
                                          ? strings.galleryNeedsFullRestart
                                          : strings.galleryAccessFailed,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(strings.chooseFromGallery),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                pickedPhotoBytes = null;
                                pickedPhotoExtension = null;
                                photoController.clear();
                                removePhoto = true;
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: Text(strings.removePhoto),
                          ),
                        ],
                      ),
                      if (pickedPhotoBytes != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          strings.selectedPhotoReady,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ] else if (removePhoto) ...[
                        const SizedBox(height: 4),
                        Text(
                          strings.noPhotoSelected,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: strings.name),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return strings.nameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: strings.phone),
                        validator: (value) {
                          final phone = (value ?? '').trim();
                          if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                            return strings.phoneRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: photoController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: strings.photoUrl,
                        ),
                        onChanged: (_) {
                          if (!removePhoto && pickedPhotoBytes == null) {
                            setDialogState(() {});
                          }
                        },
                        validator: (value) {
                          final input = (value ?? '').trim();
                          if (input.isEmpty) {
                            return null;
                          }
                          final uri = Uri.tryParse(input);
                          if (uri == null || !uri.hasAbsolutePath) {
                            return strings.validUrl;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: Text(strings.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      nameController.dispose();
      phoneController.dispose();
      photoController.dispose();
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      await userProvider.updateProfile(
        name: nameController.text,
        phone: phoneController.text,
        photoUrl: photoController.text,
        photoBytes: pickedPhotoBytes,
        photoFileExtension: pickedPhotoExtension,
        removePhoto: removePhoto,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.profileUpdatedSuccessfully)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      photoController.dispose();
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  String? _extractFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return null;
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: (user?.photoUrl.isNotEmpty ?? false)
                      ? NetworkImage(user!.photoUrl)
                      : null,
                  child: (user?.photoUrl.isNotEmpty ?? false)
                      ? null
                      : Text(
                          (user?.name.isNotEmpty ?? false)
                              ? user!.name.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? strings.guestUser,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(user?.email ?? 'guest@eventbridge.app'),
                      Text(user?.phone ?? '9999999999'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: (user == null || _isSavingProfile)
                      ? null
                      : _openEditProfileDialog,
                  icon: _isSavingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined),
                  tooltip: strings.editProfile,
                ),
              ],
            ),
          ),
        ),
        if (user == null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.signInToManageProfile,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openLogin,
                      icon: const Icon(Icons.login_rounded),
                      label: Text(strings.login),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(strings.editName),
                subtitle: Text(user?.name ?? strings.setYourDisplayName),
                onTap: (user == null || _isSavingProfile)
                    ? null
                    : _openEditProfileDialog,
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(strings.editPhone),
                subtitle: Text(
                  user?.phone.isNotEmpty == true
                      ? user!.phone
                      : strings.addMobileNumber,
                ),
                onTap: (user == null || _isSavingProfile)
                    ? null
                    : _openEditProfileDialog,
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(strings.editPhotoUrl),
                subtitle: Text(
                  user?.photoUrl.isNotEmpty == true
                      ? strings.profileImageIsSet
                      : strings.addProfilePhotoLink,
                ),
                onTap: (user == null || _isSavingProfile)
                    ? null
                    : _openEditProfileDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(strings.userStats, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _StatChip(
                  label: strings.eventsAttended,
                  value: '${userProvider.eventsAttended}',
                ),
                _StatChip(
                  label: '₹ ${strings.spent}',
                  value: userProvider.totalSpent.toStringAsFixed(0),
                ),
                _StatChip(
                  label: strings.favorite,
                  value: strings.categoryLabel(userProvider.favoriteCategory),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(strings.myTickets, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (userProvider.tickets.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(strings.noTicketsYet),
            ),
          )
        else
          ...userProvider.tickets.map((ticket) => TicketCard(ticket: ticket)),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_active_outlined),
          title: Text(strings.notifications),
          subtitle: Text(strings.notificationsSubtitle),
          onTap: () =>
              Navigator.of(context).pushNamed(NotificationsScreen.routeName),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(strings.aboutUs),
          onTap: () => Navigator.of(context).pushNamed(AboutScreen.routeName),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.support_agent_rounded),
          title: Text(strings.contactUs),
          onTap: () => Navigator.of(context).pushNamed(ContactScreen.routeName),
        ),
        const Divider(height: 26),
        Text(strings.settings, style: Theme.of(context).textTheme.titleLarge),
        if (user == null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.login_rounded),
            title: Text(strings.login),
            subtitle: Text(strings.signInToManageProfile),
            onTap: _openLogin,
          ),
        SwitchListTile(
          value: userProvider.themeMode == ThemeMode.dark,
          onChanged: userProvider.setThemeMode,
          title: Text(strings.darkMode),
        ),
        DropdownButtonFormField<String>(
          initialValue: userProvider.languageCode,
          decoration: InputDecoration(labelText: strings.language),
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'hi', child: Text('Hindi')),
            DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
          ],
          onChanged: (value) async {
            if (value != null) {
              await userProvider.setLanguage(value);
            }
          },
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.record_voice_over_outlined),
          title: Text(strings.accessibility),
          subtitle: Text(strings.openAccessibilitySettings),
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AccessibilitySettingsScreen.routeName),
        ),
        if (user?.isOrganizer == true)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.dashboard_customize_outlined),
            title: Text(strings.organizerDashboard),
            subtitle: Text(strings.organizerTools),
          ),
        if (user != null) ...[
          const Divider(height: 26),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            title: Text(strings.logout),
            subtitle: Text(strings.logoutFromYourAccount),
            onTap: _isLoggingOut ? null : _logout,
          ),
        ],
      ],
    );

    if (widget.isTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.profile)),
      body: content,
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
