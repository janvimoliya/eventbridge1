import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';

class SplitPaymentsScreen extends StatefulWidget {
  const SplitPaymentsScreen({super.key});

  @override
  State<SplitPaymentsScreen> createState() => _SplitPaymentsScreenState();
}

class _SplitPaymentsScreenState extends State<SplitPaymentsScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  bool _includeSelf = true;
  final Set<String> _selectedUserIds = {};
  List<Map<String, dynamic>> _friends = []; // app users
  List<Map<String, dynamic>> _deviceContacts = []; // phone contacts
  bool _loading = true;
  bool _useDeviceContacts = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _loading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final current = userProvider.currentUser;
    if (current == null) {
      setState(() {
        _friends = [];
        _loading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: current.uid)
          .limit(50)
          .get();

      _friends = snapshot.docs.map((d) {
        final data = d.data();
        return {
          'id': data['id'] ?? d.id,
          'name': (data['name'] ?? '').toString(),
          'upiVpa': (data['upiVpa'] ?? '').toString(),
        };
      }).toList();
    } catch (_) {
      _friends = [];
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadDeviceContacts() async {
    setState(() => _loading = true);

    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      setState(() {
        _deviceContacts = [];
        _loading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied')),
      );
      return;
    }

    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      _deviceContacts = contacts.map((c) {
        final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
        final name = c.displayName.isNotEmpty ? c.displayName : 'Unknown';
        return {
          'id': c.id,
          'name': name,
          'phone': phone,
          'upiVpa': '', // user can enter manually
        };
      }).toList();
    } catch (e) {
      _deviceContacts = [];
    }

    setState(() => _loading = false);
  }

  String _buildUpiLink(String pa, String pn, double amount, String note) {
    return 'upi://pay?pa=${Uri.encodeComponent(pa)}&pn=${Uri.encodeComponent(pn)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}';
  }

  Future<void> _shareUpiLinks() async {
    FocusScope.of(context).unfocus();

    final total = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (total <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    final list = _useDeviceContacts ? _deviceContacts : _friends;
    final recipients = list
        .where((f) => _selectedUserIds.contains(f['id']))
        .toList();
    final participantCount = recipients.length + (_includeSelf ? 1 : 0);
    if (participantCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one recipient')),
      );
      return;
    }

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one recipient to pay')),
      );
      return;
    }

    final share = (total / participantCount);
    final note = _noteCtrl.text.trim().isEmpty
        ? 'Split payment'
        : _noteCtrl.text.trim();

    final buffer = StringBuffer();
    buffer.writeln('Split Payment Request');
    buffer.writeln('Total: ₹${total.toStringAsFixed(2)}');
    buffer.writeln('Your share: ₹${share.toStringAsFixed(2)}');
    buffer.writeln('Note: $note');
    buffer.writeln('');

    final recipientLinks = <String, String>{};
    for (final r in recipients) {
      final name = (r['name'] ?? 'Friend').toString();
      final pa = (r['upiVpa'] ?? '').toString();
      if (pa.isNotEmpty) {
        final upi = _buildUpiLink(pa, name, share, note);
        recipientLinks[name] = upi;
        buffer.writeln('- $name: ₹${share.toStringAsFixed(2)}');
        buffer.writeln('  UPI: $pa');
      } else {
        buffer.writeln('- $name: Provide UPI ID manually');
      }
    }

    if (recipientLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid UPI IDs found. Add UPI IDs, then try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split Payment Links'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(buffer.toString(), style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                if (recipientLinks.isNotEmpty)
                  ...recipientLinks.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        label: Text('Pay ${e.key}'),
                        onPressed: () async {
                          final uri = Uri.parse(e.value);
                          if (await canLaunchUrl(uri)) {
                            final launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!launched && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open UPI app'),
                                ),
                              );
                            }
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No UPI app found on this device for this link',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askManualVpa(String name) async {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter UPI VPA for $name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'example@upi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _useDeviceContacts ? _deviceContacts : _friends;

    return Scaffold(
      appBar: AppBar(title: const Text('Split Payments')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total amount (₹)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _includeSelf,
                  onChanged: (v) => setState(() => _includeSelf = v ?? true),
                ),
                const SizedBox(width: 8),
                const Text('Include myself in split'),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _useDeviceContacts = false;
                        _selectedUserIds.clear();
                      });
                      _loadFriends();
                    },
                    child: const Text('App users'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _useDeviceContacts = true;
                        _selectedUserIds.clear();
                      });
                      _loadDeviceContacts();
                    },
                    child: const Text('Device contacts'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select recipients',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check the contacts you want to split with. Tap the edit icon to add missing UPI IDs.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text('No recipients found'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final f = list[index];
                        final id = f['id'] as String;
                        final name = (f['name'] ?? 'Friend').toString();
                        final upi = (f['upiVpa'] ?? '').toString();
                        final phone = (f['phone'] ?? '').toString();
                        return CheckboxListTile(
                          title: Text(name),
                          subtitle: Text(
                            upi.isNotEmpty
                                ? 'UPI: $upi'
                                : (phone.isNotEmpty
                                      ? 'Phone: $phone'
                                      : 'No UPI/phone'),
                          ),
                          value: _selectedUserIds.contains(id),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedUserIds.add(id);
                              } else {
                                _selectedUserIds.remove(id);
                              }
                            });
                          },
                          secondary: upi.isEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () async {
                                    final manual = await _askManualVpa(name);
                                    if (manual != null &&
                                        manual.trim().isNotEmpty) {
                                      setState(() {
                                        f['upiVpa'] = manual.trim();
                                        _selectedUserIds.add(id);
                                      });
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'UPI saved for $name and selected',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                )
                              : null,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _shareUpiLinks,
              child: const Text('Generate Payment Links'),
            ),
          ],
        ),
      ),
    );
  }
}
