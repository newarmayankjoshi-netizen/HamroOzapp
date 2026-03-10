import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hamro_oz/expense_split_history_page.dart';
import 'package:hamro_oz/expense_split_models.dart';

class ExpenseSplitCalculatorPage extends StatefulWidget {
  const ExpenseSplitCalculatorPage({super.key});

  @override
  State<ExpenseSplitCalculatorPage> createState() =>
      _ExpenseSplitCalculatorPageState();
}

class _ExpenseSplitCalculatorPageState
    extends State<ExpenseSplitCalculatorPage> {
  final TextEditingController _totalController = TextEditingController();
  ExpenseSplitMode _mode = ExpenseSplitMode.equal;

  ExpenseCategory _category = ExpenseCategory.groceries;
  bool _isRecurring = false;
  RecurringFrequency _recurringFrequency = RecurringFrequency.monthly;
  DateTime? _nextDueDate;

  final List<_PersonEntry> _people = [];
  int _whoPaidIndex = 0;

  @override
  void initState() {
    super.initState();
    _addPerson(name: 'Person 1');
    _addPerson(name: 'Person 2');
  }

  @override
  void dispose() {
    _totalController.dispose();
    for (final p in _people) {
      p.dispose();
    }
    super.dispose();
  }

  void _addPerson({String? name}) {
    final next = _people.length + 1;
    _people.add(_PersonEntry(name: name ?? 'Person $next'));
  }

  void _removePerson(int index) {
    if (_people.length <= 2) return;
    final removed = _people.removeAt(index);
    removed.dispose();

    if (_whoPaidIndex >= _people.length) {
      _whoPaidIndex = 0;
    }
  }

  double _parseMoney(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  int _toCents(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return (value * 100).round();
  }

  String _moneyFromCents(int cents) {
    final v = cents / 100.0;
    return '\$${v.toStringAsFixed(2)}';
  }

  int _totalCents() => _toCents(_parseMoney(_totalController.text));

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _buildSummaryText({required int totalCents}) {
    final settlement = _settle(totalCents: totalCents);
    final lines = <String>[];
    lines.add('Expense split');
    lines.add('Category: ${_category.label}');
    lines.add('Total: ${_moneyFromCents(totalCents)}');
    lines.add('Mode: ${_mode.label}');
    if (_isRecurring) {
      final due = _nextDueDate != null ? _formatDate(_nextDueDate!) : 'Not set';
      lines.add('Recurring: ${_recurringFrequency.label} (next due: $due)');
    }
    lines.add('');

    for (final p in settlement.people) {
      lines.add(
        '${p.name}: share ${_moneyFromCents(p.shareCents)}, paid ${_moneyFromCents(p.paidCents)}',
      );
    }

    lines.add('');
    if (settlement.transfers.isEmpty) {
      lines.add('All settled.');
    } else {
      lines.add('Settlement:');
      for (final t in settlement.transfers) {
        lines.add('${t.from} → ${t.to}: ${_moneyFromCents(t.cents)}');
      }
    }

    return lines.join('\n');
  }

  Future<void> _shareSummary() async {
    final totalCents = _totalCents();
    final text = _buildSummaryText(totalCents: totalCents);
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _shareViaSms() async {
    final totalCents = _totalCents();
    final text = _buildSummaryText(totalCents: totalCents);

    final smsUri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');
    final ok = await launchUrl(smsUri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open SMS app.')),
      );
    }
  }

  Future<void> _saveToHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save history to Firebase.')),
      );
      return;
    }

    final totalCents = _totalCents();
    final settlement = _settle(totalCents: totalCents);
    final shares = _computeSharesCents(totalCents: totalCents);
    final paid = _computePaidCents(totalCents: totalCents);

    final people = <Map<String, Object?>>[];
    for (var i = 0; i < _people.length; i++) {
      final name = _people[i].nameController.text.trim().isEmpty
          ? 'Person ${i + 1}'
          : _people[i].nameController.text.trim();
      people.add({
        'name': name,
        'shareCents': i < shares.length ? shares[i] : 0,
        'paidCents': i < paid.length ? paid[i] : 0,
      });
    }

    final transfers = settlement.transfers
        .map(
          (t) => {
            'from': t.from,
            'to': t.to,
            'cents': t.cents,
          },
        )
        .toList(growable: false);

    final doc = <String, Object?>{
      'category': _category.name,
      'mode': _mode.name,
      'totalCents': totalCents,
      'whoPaidIndex': _whoPaidIndex,
      'people': people,
      'transfers': transfers,
      'isRecurring': _isRecurring,
      'recurringFrequency': _recurringFrequency.name,
      'nextDueDate': _nextDueDate != null
          ? Timestamp.fromDate(_nextDueDate!)
          : null,
      'summaryText': _buildSummaryText(totalCents: totalCents),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expense_splits')
          .add(doc);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission denied saving history. Deploy Firestore rules or ensure you are signed in.',
            ),
          ),
        );
        return;
      }
      rethrow;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to history.')),
    );
  }

  Future<void> _openHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to view history.')),
      );
      return;
    }

    final record = await Navigator.of(context).push<ExpenseSplitHistoryRecord>(
      MaterialPageRoute(builder: (_) => const ExpenseSplitHistoryPage()),
    );
    if (record == null || !mounted) return;

    setState(() {
      _category = record.category;
      _mode = record.mode;
      _isRecurring = record.isRecurring;
      _recurringFrequency = record.recurringFrequency;
      _nextDueDate = record.nextDueDate;
      _whoPaidIndex = record.whoPaidIndex;

      _totalController.text = (record.totalCents / 100).toStringAsFixed(2);

      for (final p in _people) {
        p.dispose();
      }
      _people
        ..clear()
        ..addAll(
          record.people.map(
            (p) => _PersonEntry(name: p.name)
              ..shareController.text = (p.shareCents / 100).toStringAsFixed(2)
              ..paidController.text = (p.paidCents / 100).toStringAsFixed(2),
          ),
        );

      if (_people.length < 2) {
        _addPerson(name: 'Person 1');
        _addPerson(name: 'Person 2');
      }

      if (_whoPaidIndex >= _people.length) {
        _whoPaidIndex = 0;
      }

      _applyModeDefaults();

      if (_mode != ExpenseSplitMode.unequal) {
        for (final p in _people) {
          p.shareController.text = '';
        }
      }

      if (_mode == ExpenseSplitMode.whoPaid) {
        for (var i = 0; i < _people.length; i++) {
          _people[i].paidController.text = i == _whoPaidIndex
              ? (record.totalCents / 100).toStringAsFixed(2)
              : '0';
        }
      }
    });
  }

  List<int> _computeSharesCents({required int totalCents}) {
    final n = _people.isEmpty ? 1 : _people.length;

    switch (_mode) {
      case ExpenseSplitMode.equal:
      case ExpenseSplitMode.whoPaid:
        final base = totalCents ~/ n;
        final remainder = totalCents - (base * n);
        return List<int>.generate(n, (i) => base + (i < remainder ? 1 : 0));
      case ExpenseSplitMode.unequal:
        final shares = <int>[];
        for (final p in _people) {
          shares.add(_toCents(_parseMoney(p.shareController.text)));
        }
        return shares;
    }
  }

  List<int> _computePaidCents({required int totalCents}) {
    final paid = <int>[];

    if (_mode == ExpenseSplitMode.whoPaid) {
      for (var i = 0; i < _people.length; i++) {
        paid.add(i == _whoPaidIndex ? totalCents : 0);
      }
      return paid;
    }

    for (final p in _people) {
      paid.add(_toCents(_parseMoney(p.paidController.text)));
    }
    return paid;
  }

  _SettlementResult _settle({required int totalCents}) {
    final shares = _computeSharesCents(totalCents: totalCents);
    final paid = _computePaidCents(totalCents: totalCents);

    final nets = <_NetBalance>[];
    for (var i = 0; i < _people.length; i++) {
      final name = _people[i].nameController.text.trim().isEmpty
          ? 'Person ${i + 1}'
          : _people[i].nameController.text.trim();
      final share = i < shares.length ? shares[i] : 0;
      final paidAmount = i < paid.length ? paid[i] : 0;
      nets.add(
        _NetBalance(
          name: name,
          shareCents: share,
          paidCents: paidAmount,
          netCents: paidAmount - share,
        ),
      );
    }

    final creditors = <_BalanceAmount>[];
    final debtors = <_BalanceAmount>[];

    for (final n in nets) {
      if (n.netCents > 0) {
        creditors.add(_BalanceAmount(name: n.name, cents: n.netCents));
      } else if (n.netCents < 0) {
        debtors.add(_BalanceAmount(name: n.name, cents: -n.netCents));
      }
    }

    final transfers = <_Transfer>[];
    var i = 0;
    var j = 0;
    while (i < debtors.length && j < creditors.length) {
      final d = debtors[i];
      final c = creditors[j];

      final amount = d.cents < c.cents ? d.cents : c.cents;
      if (amount > 0) {
        transfers.add(_Transfer(from: d.name, to: c.name, cents: amount));
      }

      debtors[i] = _BalanceAmount(name: d.name, cents: d.cents - amount);
      creditors[j] = _BalanceAmount(name: c.name, cents: c.cents - amount);

      if (debtors[i].cents <= 0) i++;
      if (creditors[j].cents <= 0) j++;
    }

    return _SettlementResult(people: nets, transfers: transfers);
  }

  void _applyModeDefaults() {
    final total = _totalCents();

    if (_mode == ExpenseSplitMode.whoPaid) {
      for (var i = 0; i < _people.length; i++) {
        _people[i].paidController.text = i == _whoPaidIndex
            ? (total / 100).toStringAsFixed(2)
            : '0';
      }
    }

    if (_mode == ExpenseSplitMode.equal || _mode == ExpenseSplitMode.whoPaid) {
      for (final p in _people) {
        p.shareController.text = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalCents = _totalCents();
    final sharesCents = _computeSharesCents(totalCents: totalCents);

    final unequalSharesTotal = _mode == ExpenseSplitMode.unequal
        ? sharesCents.fold(0, (a, b) => a + b)
        : null;
    final totalMismatch =
        _mode == ExpenseSplitMode.unequal &&
        unequalSharesTotal != null &&
        totalCents > 0 &&
        unequalSharesTotal != totalCents;

    final settlement = _settle(totalCents: totalCents);

    Future<void> copySummary() async {
      await Clipboard.setData(
        ClipboardData(text: _buildSummaryText(totalCents: totalCents)),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Summary copied')));
    }

    Widget sectionTitle(String text, {IconData? icon}) {
      return Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Split Calculator'),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Save to history',
            onPressed: _saveToHistory,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: _shareSummary,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Share via SMS',
            onPressed: _shareViaSms,
            icon: const Icon(Icons.sms_outlined),
          ),
          IconButton(
            tooltip: 'Copy summary',
            onPressed: copySummary,
            icon: const Icon(Icons.content_copy_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Split shared expenses and see who owes whom.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            color: const Color(0xFFF9FAFB),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle('Mode', icon: Icons.tune_outlined),
                  const SizedBox(height: 10),
                  SegmentedButton<ExpenseSplitMode>(
                    segments: ExpenseSplitMode.values
                        .map(
                          (m) => ButtonSegment<ExpenseSplitMode>(
                            value: m,
                            label: Text(m.label),
                          ),
                        )
                        .toList(growable: false),
                    selected: <ExpenseSplitMode>{_mode},
                    onSelectionChanged: (s) {
                      setState(() {
                        _mode = s.first;
                        _applyModeDefaults();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ExpenseCategory.values
                        .map(
                          (c) => DropdownMenuItem<ExpenseCategory>(
                            value: c,
                            child: Text(c.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _category = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _totalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Total amount (AUD)',
                      prefixText: '\$ ',
                      helperText:
                          'Example: groceries, utilities, restaurant bill',
                    ),
                    onChanged: (_) {
                      setState(() {
                        if (_mode == ExpenseSplitMode.whoPaid) {
                          _applyModeDefaults();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isRecurring,
                    title: const Text('Recurring expense'),
                    subtitle: const Text('Save as a recurring split for later'),
                    onChanged: (v) {
                      setState(() {
                        _isRecurring = v;
                        if (!_isRecurring) {
                          _nextDueDate = null;
                        }
                      });
                    },
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<RecurringFrequency>(
                      initialValue: _recurringFrequency,
                      decoration:
                          const InputDecoration(labelText: 'Frequency'),
                      items: RecurringFrequency.values
                          .map(
                            (f) => DropdownMenuItem<RecurringFrequency>(
                              value: f,
                              child: Text(f.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _recurringFrequency = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _nextDueDate ?? now,
                          firstDate: DateTime(now.year - 1, 1, 1),
                          lastDate: DateTime(now.year + 5, 12, 31),
                        );
                        if (picked == null || !mounted) return;
                        setState(() => _nextDueDate = picked);
                      },
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        _nextDueDate == null
                            ? 'Pick next due date'
                            : 'Next due: ${_formatDate(_nextDueDate!)}',
                      ),
                    ),
                  ],
                  if (_mode == ExpenseSplitMode.whoPaid) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _whoPaidIndex,
                      decoration: const InputDecoration(labelText: 'Who paid?'),
                      items: List<DropdownMenuItem<int>>.generate(
                        _people.length,
                        (i) => DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            _people[i].nameController.text.trim().isEmpty
                                ? 'Person ${i + 1}'
                                : _people[i].nameController.text.trim(),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _whoPaidIndex = v;
                          _applyModeDefaults();
                        });
                      },
                    ),
                  ],
                  if (totalMismatch) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Unequal shares total ${_moneyFromCents(unequalSharesTotal)} which does not match the total ${_moneyFromCents(totalCents)}.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          sectionTitle('People', icon: Icons.group_outlined),
          const SizedBox(height: 10),
          ...List<Widget>.generate(_people.length, (index) {
            final person = _people[index];
            final computedShare = (index < sharesCents.length)
                ? sharesCents[index]
                : 0;
            final shareEnabled = _mode == ExpenseSplitMode.unequal;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: person.nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                hintText: 'Person ${index + 1}',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: _people.length <= 2
                                ? null
                                : () => setState(() => _removePerson(index)),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: person.shareController,
                              enabled: shareEnabled,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: shareEnabled
                                    ? 'Share (AUD)'
                                    : 'Share (calculated)',
                                prefixText: '\$ ',
                                helperText: shareEnabled
                                    ? null
                                    : _moneyFromCents(computedShare),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: person.paidController,
                              enabled: _mode != ExpenseSplitMode.whoPaid,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: _mode == ExpenseSplitMode.whoPaid
                                    ? 'Paid (auto)'
                                    : 'Paid (AUD)',
                                prefixText: '\$ ',
                                helperText: _mode == ExpenseSplitMode.whoPaid
                                    ? (index == _whoPaidIndex
                                          ? _moneyFromCents(totalCents)
                                          : _moneyFromCents(0))
                                    : null,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      if (!shareEnabled) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Calculated share: ${_moneyFromCents(computedShare)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _addPerson();
                      _applyModeDefaults();
                    });
                  },
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Add person'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          sectionTitle('Settlement', icon: Icons.compare_arrows_outlined),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settlement.transfers.isEmpty)
                    Text(
                      totalCents == 0
                          ? 'Enter a total amount to see the settlement.'
                          : 'All settled — no one owes anything.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    ...settlement.transfers.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.payments_outlined, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${t.from} pays ${t.to}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              _moneyFromCents(t.cents),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: copySummary,
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('Copy summary'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tip: For roommates, use “Who paid?” mode after groceries or utilities to see exactly who owes whom.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonEntry {
  final TextEditingController nameController;
  final TextEditingController shareController;
  final TextEditingController paidController;

  _PersonEntry({required String name})
    : nameController = TextEditingController(text: name),
      shareController = TextEditingController(),
      paidController = TextEditingController(text: '0');

  void dispose() {
    nameController.dispose();
    shareController.dispose();
    paidController.dispose();
  }
}

class _NetBalance {
  final String name;
  final int shareCents;
  final int paidCents;
  final int netCents;

  const _NetBalance({
    required this.name,
    required this.shareCents,
    required this.paidCents,
    required this.netCents,
  });
}

class _BalanceAmount {
  final String name;
  final int cents;

  const _BalanceAmount({required this.name, required this.cents});
}

class _Transfer {
  final String from;
  final String to;
  final int cents;

  const _Transfer({required this.from, required this.to, required this.cents});
}

class _SettlementResult {
  final List<_NetBalance> people;
  final List<_Transfer> transfers;

  const _SettlementResult({required this.people, required this.transfers});
}
