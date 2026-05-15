import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/ticket_card.dart';
import '../widgets/language_selector.dart';
import '../widgets/translatable_text.dart';
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
  bool _isLinkingPhone = false;
  bool _linkOtpSent = false;

  late final TextEditingController _linkPhoneController;
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _linkPhoneController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _linkPhoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatableText(strings.loggedOutSuccessfully)),
      );
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
              title: TranslatableText(strings.editProfile),
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
                                    content: TranslatableText(
                                      isChannelError
                                          ? strings.galleryNeedsFullRestart
                                          : strings.galleryAccessFailed,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: TranslatableText(strings.chooseFromGallery),
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
                            label: TranslatableText(strings.removePhoto),
                          ),
                        ],
                      ),
                      if (pickedPhotoBytes != null) ...[
                        const SizedBox(height: 4),
                        TranslatableText(
                          strings.selectedPhotoReady,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ] else if (removePhoto) ...[
                        const SizedBox(height: 4),
                        TranslatableText(
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
                  child: TranslatableText(strings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: TranslatableText(strings.save),
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
        SnackBar(content: TranslatableText(strings.profileUpdatedSuccessfully)),
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

  String _normalizePhoneNumber(String input) {
    var phone = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.isEmpty) {
      return '';
    }

    if (phone.startsWith('+')) {
      return phone;
    }

    phone = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.length == 10) {
      return '+91$phone';
    }

    return phone.isEmpty ? '' : '+$phone';
  }

  Future<void> _sendLinkPhoneOtp() async {
    final strings = AppLocalizations.of(context);
    final phone = _linkPhoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatableText(strings.phoneRequired)),
      );
      return;
    }

    final normalizedPhone = _normalizePhoneNumber(phone);
    if (!RegExp(r'^\+91\d{10}$').hasMatch(normalizedPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatableText(strings.phoneRequired)),
      );
      return;
    }

    setState(() => _isLinkingPhone = true);
    try {
      final authService = AuthService();
      await authService.requestOtp(phoneNumber: normalizedPhone);

      if (!mounted) return;
      setState(() {
        _linkOtpSent = true;
        _isLinkingPhone = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.otpSentTo(normalizedPhone))),
      );
      _otpController.clear();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLinkingPhone = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _verifyAndLinkPhone() async {
    final strings = AppLocalizations.of(context);
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatableText(strings.enterValidOtp)),
      );
      return;
    }

    setState(() => _isLinkingPhone = true);
    try {
      final authService = AuthService();
      await authService.verifyAndLinkOtp(otp: otp);

      if (!mounted) return;

      // Refresh user profile after linking
      await context.read<UserProvider>().refreshProfile();

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatableText(strings.phoneLinkSuccessful)),
      );

      setState(() {
        _linkOtpSent = false;
        _isLinkingPhone = false;
        _linkPhoneController.clear();
        _otpController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLinkingPhone = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _openLinkPhoneDialog() async {
    final strings = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: TranslatableText(strings.linkPhoneNumber),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_linkOtpSent) ...[
                      Text(
                        strings.enterPhoneToLink,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _linkPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: strings.phone,
                          hintText: strings.phonePlaceholder,
                          prefixText: '+91 ',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                    ] else ...[
                      Text(
                        strings.enterOtpSent,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: strings.otp,
                          hintText: '000000',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    setState(() {
                      _linkOtpSent = false;
                      _linkPhoneController.clear();
                      _otpController.clear();
                      _isLinkingPhone = false;
                    });
                  },
                  child: TranslatableText(strings.cancel),
                ),
                FilledButton(
                  onPressed: _isLinkingPhone
                      ? null
                      : (_linkOtpSent
                            ? _verifyAndLinkPhone
                            : _sendLinkPhoneOtp),
                  child: _isLinkingPhone
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : TranslatableText(
                          _linkOtpSent ? strings.verify : strings.sendOtp,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
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

    final content = RefreshIndicator(
      onRefresh: () async {
        await userProvider.refreshTickets();
      },
      child: ListView(
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
                        (user?.name != null && (user?.name.isNotEmpty ?? false))
                            ? Text(
                                user!.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              )
                            : TranslatableText(
                                strings.guestUser,
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
                        label: TranslatableText(strings.login),
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
                  title: TranslatableText(strings.editName),
                  subtitle: (user?.name.isNotEmpty ?? false)
                      ? Text(user!.name)
                      : TranslatableText(strings.setYourDisplayName),
                  onTap: (user == null || _isSavingProfile)
                      ? null
                      : _openEditProfileDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: TranslatableText(strings.editPhone),
                  subtitle: (user?.phone.isNotEmpty == true)
                      ? Text(user!.phone)
                      : TranslatableText(strings.addMobileNumber),
                  onTap: (user == null || _isSavingProfile)
                      ? null
                      : _openEditProfileDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: TranslatableText(strings.linkPhoneNumberForOtp),
                  subtitle: TranslatableText(
                    strings.linkPhoneNumberForOtpSubtitle,
                  ),
                  onTap: (user == null || _isLinkingPhone)
                      ? null
                      : _openLinkPhoneDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: TranslatableText(strings.editPhotoUrl),
                  subtitle: (user?.photoUrl.isNotEmpty == true)
                      ? TranslatableText(strings.profileImageIsSet)
                      : TranslatableText(strings.addProfilePhotoLink),
                  onTap: (user == null || _isSavingProfile)
                      ? null
                      : _openEditProfileDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.userStats,
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
          Text(
            strings.myTickets,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (userProvider.tickets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: TranslatableText(strings.noTicketsYet),
              ),
            )
          else
            ...userProvider.tickets.map((ticket) => TicketCard(ticket: ticket)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_active_outlined),
            title: TranslatableText(strings.notifications),
            subtitle: TranslatableText(strings.notificationsSubtitle),
            onTap: () =>
                Navigator.of(context).pushNamed(NotificationsScreen.routeName),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline_rounded),
            title: TranslatableText(strings.aboutUs),
            onTap: () => Navigator.of(context).pushNamed(AboutScreen.routeName),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.support_agent_rounded),
            title: TranslatableText(strings.contactUs),
            onTap: () =>
                Navigator.of(context).pushNamed(ContactScreen.routeName),
          ),
          const Divider(height: 26),
          TranslatableText(
            strings.settings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (user == null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.login_rounded),
              title: TranslatableText(strings.login),
              subtitle: TranslatableText(strings.signInToManageProfile),
              onTap: _openLogin,
            ),
          SwitchListTile(
            value: userProvider.themeMode == ThemeMode.dark,
            onChanged: userProvider.setThemeMode,
            title: TranslatableText(strings.darkMode),
          ),
          const SizedBox(height: 16),
          const LanguageSelector(),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.record_voice_over_outlined),
            title: TranslatableText(strings.accessibility),
            subtitle: TranslatableText(strings.openAccessibilitySettings),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AccessibilitySettingsScreen.routeName),
          ),
          if (user?.isOrganizer == true)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: TranslatableText(strings.organizerDashboard),
              subtitle: TranslatableText(strings.organizerTools),
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
              title: TranslatableText(strings.logout),
              subtitle: TranslatableText(strings.logoutFromYourAccount),
              onTap: _isLoggingOut ? null : _logout,
            ),
          ],
        ],
      ),
    );

    if (widget.isTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: TranslatableText(strings.profile)),
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
          TranslatableText(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
