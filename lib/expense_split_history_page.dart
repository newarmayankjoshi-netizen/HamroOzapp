import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:hamro_oz/expense_split_models.dart';

class ExpenseSplitHistoryPerson {
  final String name;
  final int shareCents;
  final int paidCents;

  const ExpenseSplitHistoryPerson({
    required this.name,
    required this.shareCents,
    required this.paidCents,
  });

  factory ExpenseSplitHistoryPerson.fromMap(Map<String, Object?> map) {
    return ExpenseSplitHistoryPerson(
      name: (map['name'] as String?) ?? 'Person',
      shareCents: (map['shareCents'] as num?)?.toInt() ?? 0,
      paidCents: (map['paidCents'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExpenseSplitHistoryRecord {
  final String id;
  final ExpenseCategory category;
  final ExpenseSplitMode mode;
  final int totalCents;
  final int whoPaidIndex;
  final List<ExpenseSplitHistoryPerson> people;
  final bool isRecurring;
  final RecurringFrequency recurringFrequency;
  final DateTime? nextDueDate;
  final DateTime? createdAt;

  const ExpenseSplitHistoryRecord({
    required this.id,
    required this.category,
    required this.mode,
    required this.totalCents,
    required this.whoPaidIndex,
    required this.people,
    required this.isRecurring,
    required this.recurringFrequency,
    required this.nextDueDate,
    required this.createdAt,
  });

  static ExpenseCategory _parseCategory(String? raw) {
    for (final c in ExpenseCategory.values) {
      if (c.name == raw) return c;
    }
    return ExpenseCategory.groceries;
  }

  static ExpenseSplitMode _parseMode(String? raw) {
    for (final m in ExpenseSplitMode.values) {
      if (m.name == raw) return m;
    }
    return ExpenseSplitMode.equal;
  }

  static RecurringFrequency _parseRecurringFrequency(String? raw) {
    for (final f in RecurringFrequency.values) {
      if (f.name == raw) return f;
    }
    return RecurringFrequency.monthly;
  }

  factory ExpenseSplitHistoryRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, Object?>> doc,
  ) {
    final data = doc.data();

    final peopleRaw = (data['people'] as List?) ?? const [];
    final people = <ExpenseSplitHistoryPerson>[];
    for (final p in peopleRaw) {
      if (p is Map<String, Object?>) {
        people.add(ExpenseSplitHistoryPerson.fromMap(p));
      } else if (p is Map) {
        people.add(
          ExpenseSplitHistoryPerson.fromMap(
            p.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      }
    }

    final nextDue = data['nextDueDate'];
    DateTime? nextDueDate;
    if (nextDue is Timestamp) {
      nextDueDate = nextDue.toDate();
    }

    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    }

    return ExpenseSplitHistoryRecord(
      id: doc.id,
      category: _parseCategory(data['category'] as String?),
      mode: _parseMode(data['mode'] as String?),
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      whoPaidIndex: (data['whoPaidIndex'] as num?)?.toInt() ?? 0,
      people: people,
      isRecurring: (data['isRecurring'] as bool?) ?? false,
      recurringFrequency:
          _parseRecurringFrequency(data['recurringFrequency'] as String?),
      nextDueDate: nextDueDate,
      createdAt: createdAt,
    );
  }
}

class ExpenseSplitHistoryPage extends StatelessWidget {
  const ExpenseSplitHistoryPage({super.key});

  String _moneyFromCents(int cents) {
    final v = cents / 100.0;
    return '\$${v.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const Center(child: Text('Sign in to view history.')),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expense_splits')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, Object?>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final err = snapshot.error;
            if (err is FirebaseException && err.code == 'permission-denied') {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Permission denied.\n\nMake sure you are signed in and your Firestore rules allow access to:\nusers/{uid}/expense_splits\n\nIf you recently changed firestore.rules locally, deploy them to Firebase.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Center(
              child: Text('Failed to load history: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No saved splits yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final record = ExpenseSplitHistoryRecord.fromDoc(docs[index]);

              final subtitle = <String>[];
              subtitle.add('${record.mode.label} • ${record.people.length} people');
              if (record.createdAt != null) {
                subtitle.add('Saved: ${_formatDate(record.createdAt!)}');
              }
              if (record.isRecurring) {
                final due = record.nextDueDate != null
                    ? _formatDate(record.nextDueDate!)
                    : 'not set';
                subtitle.add('Recurring: ${record.recurringFrequency.label} (next: $due)');
              }

              return Dismissible(
                key: ValueKey(record.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete this split?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('expense_splits')
                      .doc(record.id)
                      .delete();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deleted.')),
                    );
                  }
                },
                child: Card(
                  child: ListTile(
                    title: Text(
                      '${record.category.label} • ${_moneyFromCents(record.totalCents)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(subtitle.join('\n')),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(record),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
