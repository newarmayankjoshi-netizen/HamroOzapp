
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisaTrackerScreen extends StatefulWidget {
  const VisaTrackerScreen({super.key});

  @override
  State<VisaTrackerScreen> createState() => _VisaTrackerScreenState();
}

// Place this class outside of any widget tree or method
class _VisaExpiryProgressBar extends StatelessWidget {
  final int? daysRemaining;
  const _VisaExpiryProgressBar({required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    double percent;
    Color color;
    String label;
    if (daysRemaining == null) {
      percent = 0.0;
      color = Colors.grey;
      label = 'Unknown';
    } else if (daysRemaining! < 0) {
      percent = 1.0;
      color = Colors.red;
      label = 'Expired';
    } else if (daysRemaining! <= 7) {
      percent = (daysRemaining! / 90).clamp(0.0, 1.0);
      color = Colors.red;
      label = 'Expiring soon';
    } else if (daysRemaining! <= 30) {
      percent = (daysRemaining! / 90).clamp(0.0, 1.0);
      color = Colors.orange;
      label = 'Expiring in $daysRemaining days';
    } else if (daysRemaining! <= 90) {
      percent = (daysRemaining! / 90).clamp(0.0, 1.0);
      color = Colors.orange;
      label = 'Expiring in $daysRemaining days';
    } else {
      percent = 1.0;
      color = Colors.green;
      label = 'Safe ($daysRemaining days left)';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: percent,
          minHeight: 10,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]
    );
  }
}

class _VisaTrackerScreenState extends State<VisaTrackerScreen> {

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _saving = false;

    @override
    void initState() {
      super.initState();
      _initNotifications();
      tz.initializeTimeZones();
      // Load existing saved visa data for the current user
      _loadVisaData();
    }

    Future<void> _initNotifications() async {
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
      final InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: iosInit,
      );
      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {},
      );
    }

    Future<void> _scheduleExpiryNotifications() async {
      if (_expiryDate == null) return;
      final now = DateTime.now();
      final expiry = DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day, 9, 0);
      final List<({bool enabled, int daysBefore, String label})> reminders = [
        (enabled: _remind90, daysBefore: 90, label: '90 days before'),
        (enabled: _remind30, daysBefore: 30, label: '30 days before'),
        (enabled: _remind7, daysBefore: 7, label: '7 days before'),
        (enabled: _remindOnExpiry, daysBefore: 0, label: 'On expiry'),
      ];
      int id = 100;
      for (final r in reminders) {
        await _notifications.cancel(id: id);
        if (r.enabled) {
          final scheduled = expiry.subtract(Duration(days: r.daysBefore));
          if (scheduled.isAfter(now)) {
            final tzScheduled = tz.TZDateTime.from(scheduled, tz.local);
            await _notifications.zonedSchedule(
              id: id,
              title: 'Visa Expiry Reminder',
              body: r.daysBefore == 0
                  ? 'Your visa expires today!'
                  : 'Your visa will expire in ${r.daysBefore} days.',
              scheduledDate: tzScheduled,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails('visa_expiry', 'Visa Expiry', importance: Importance.max, priority: Priority.high),
                iOS: const DarwinNotificationDetails(),
                macOS: const DarwinNotificationDetails(),
              ),
              matchDateTimeComponents: DateTimeComponents.dateAndTime,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          }
        }
        id++;
      }
    }
  bool _remind90 = true;
  bool _remind30 = true;
  bool _remind7 = true;
  bool _remindOnExpiry = true;
  DateTime? _payPeriodStart;
  double _hoursWorked = 0;
  static const double _workLimit = 48;

  double get _remainingHours => _workLimit - _hoursWorked;
  final _formKey = GlobalKey<FormState>();
  String _visaType = 'Student';
  String _subclass = '500';
  DateTime? _expiryDate;
  bool _bridgingVisa = false;
  DateTime? _passportExpiry;

  int? get _daysRemaining {
    if (_expiryDate == null) return null;
    final now = DateTime.now();
    final expiry = DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day);
    return expiry.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  String get _expiryStatus {
    final days = _daysRemaining;
    if (days == null) return '';
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today!';
    if (days <= 7) return 'Expiring in $days day${days == 1 ? '' : 's'}!';
    if (days <= 30) return 'Expiring in $days days';
    if (days <= 90) return 'Expiring in $days days';
    return 'Valid ($days days left)';
  }

  void _onReminderChanged() {
    _scheduleExpiryNotifications();
  }



  Future<void> _loadVisaData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('visa_tracker').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _visaType = (data['visaType'] as String?) ?? 'Student';
        _subclass = (data['subclass'] as String?) ?? '500';
        // expiryDate may be stored as a Firestore Timestamp or an ISO string
        final expiryRaw = data['expiryDate'];
        if (expiryRaw is Timestamp) {
          _expiryDate = expiryRaw.toDate();
        } else if (expiryRaw is String) {
          _expiryDate = DateTime.tryParse(expiryRaw);
        } else {
          _expiryDate = null;
        }
        _bridgingVisa = (data['bridgingVisa'] as bool?) ?? false;
        final passportRaw = data['passportExpiry'];
        if (passportRaw is Timestamp) {
          _passportExpiry = passportRaw.toDate();
        } else if (passportRaw is String) {
          _passportExpiry = DateTime.tryParse(passportRaw);
        } else {
          _passportExpiry = null;
        }
        final payRaw = data['payPeriodStart'];
        if (payRaw is Timestamp) {
          _payPeriodStart = payRaw.toDate();
        } else if (payRaw is String) {
          _payPeriodStart = DateTime.tryParse(payRaw);
        } else {
          _payPeriodStart = null;
        }
        final hoursRaw = data['hoursWorked'];
        if (hoursRaw is num) {
          _hoursWorked = hoursRaw.toDouble();
        } else if (hoursRaw is String) {
          _hoursWorked = double.tryParse(hoursRaw) ?? 0.0;
        } else {
          _hoursWorked = 0.0;
        }
        _remind90 = (data['remind90'] as bool?) ?? true;
        _remind30 = (data['remind30'] as bool?) ?? true;
        _remind7 = (data['remind7'] as bool?) ?? true;
        _remindOnExpiry = (data['remindOnExpiry'] as bool?) ?? true;
      });
      // Ensure notifications are scheduled for loaded data
      _scheduleExpiryNotifications();
    }
  }

  Future<void> _saveVisaData() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save visa information.')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      // Use merge to avoid clobbering other fields unintentionally
      await _firestore.collection('visa_tracker').doc(user.uid).set({
        'visaType': _visaType,
        'subclass': _subclass,
        'expiryDate': _expiryDate?.toIso8601String(),
        'bridgingVisa': _bridgingVisa,
        'passportExpiry': _passportExpiry?.toIso8601String(),
        'payPeriodStart': _payPeriodStart?.toIso8601String(),
        'hoursWorked': _hoursWorked,
        'remind90': _remind90,
        'remind30': _remind30,
        'remind7': _remind7,
        'remindOnExpiry': _remindOnExpiry,
      }, SetOptions(merge: true));
      // Schedule notifications for the saved expiry date
      await _scheduleExpiryNotifications();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Visa info saved!')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visa Expiration Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadVisaData,
          ),
        ],
      ),
      resizeToAvoidBottomInset: true, // Ensure keyboard doesn't cause overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card 1: Visa Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Visa Info', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (_expiryDate != null)
                        Row(
                          children: [
                            Icon(
                              _daysRemaining == null
                                  ? Icons.info_outline
                                  : _daysRemaining! < 0
                                      ? Icons.error
                                      : _daysRemaining! <= 7
                                          ? Icons.warning
                                          : Icons.check_circle,
                              color: _daysRemaining == null
                                  ? Colors.grey
                                  : _daysRemaining! < 0
                                      ? Colors.red
                                      : _daysRemaining! <= 7
                                          ? Colors.orange
                                          : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_expiryStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _daysRemaining == null
                                        ? Colors.grey
                                        : _daysRemaining! < 0
                                            ? Colors.red
                                            : _daysRemaining! <= 7
                                                ? Colors.orange
                                                : Colors.green,
                                    fontSize: 16,
                                  )),
                            ),
                          ],
                        ),
                      if (_expiryDate != null) ...[
                        const SizedBox(height: 12),
                        _VisaExpiryProgressBar(daysRemaining: _daysRemaining),
                        const SizedBox(height: 8),
                      ],
                      DropdownButtonFormField<String>(
                        initialValue: _visaType,
                        decoration: const InputDecoration(labelText: 'Visa Type'),
                        items: const [
                          DropdownMenuItem(value: 'Student', child: Text('Student (Subclass 500)')),
                          DropdownMenuItem(value: 'Temporary Graduate', child: Text('Temporary Graduate (485)')),
                          DropdownMenuItem(value: 'Visitor', child: Text('Visitor')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _visaType = v ?? 'Student'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _subclass,
                        decoration: const InputDecoration(labelText: 'Subclass'),
                        onChanged: (v) => _subclass = v,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Expiry Date'),
                        subtitle: Text(_formatDate(_expiryDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _expiryDate = picked);
                            _scheduleExpiryNotifications();
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bridging Visa?'),
                        value: _bridgingVisa,
                        onChanged: (v) => setState(() => _bridgingVisa = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Card 2: Work Hours Tracking
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Work Hours Tracking', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pay Period Start Date'),
                        subtitle: Text(_formatDate(_payPeriodStart)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _payPeriodStart ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _payPeriodStart = picked);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _hoursWorked.toString(),
                        decoration: const InputDecoration(labelText: 'Hours Worked This Fortnight'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final val = double.tryParse(v) ?? 0;
                          setState(() => _hoursWorked = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Work Limit: 48 hrs / fortnight'),
                          ),
                          const SizedBox(width: 16),
                          Text('Remaining: ${_remainingHours < 0 ? 0 : _remainingHours.toStringAsFixed(1)} hrs',
                            style: TextStyle(
                              color: _remainingHours > 12 ? Colors.green : _remainingHours > 0 ? Colors.orange : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Card 3: Reminder Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reminder Settings', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Notify 90 days before'),
                        value: _remind90,
                        onChanged: (v) => setState(() {
                          _remind90 = v;
                          _onReminderChanged();
                        }),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Notify 30 days before'),
                        value: _remind30,
                        onChanged: (v) => setState(() {
                          _remind30 = v;
                          _onReminderChanged();
                        }),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Notify 7 days before'),
                        value: _remind7,
                        onChanged: (v) => setState(() {
                          _remind7 = v;
                          _onReminderChanged();
                        }),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Notify on expiry day'),
                        value: _remindOnExpiry,
                        onChanged: (v) => setState(() {
                          _remindOnExpiry = v;
                          _onReminderChanged();
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 80), // space for bottom save bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
            label: const Text('Save Visa Info'),
            onPressed: _saving ? null : _saveVisaData,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    try {
      return DateFormat.yMMMMd().format(d.toLocal());
    } catch (_) {
      return d.toLocal().toString().split(' ')[0];
    }
  }
}
