import 'package:flutter/material.dart';

import 'services/rent_calculator.dart';

class RentCalculatorPage extends StatefulWidget {
  final double initialWeeklyRent;

  const RentCalculatorPage({
    super.key,
    this.initialWeeklyRent = 0,
  });

  @override
  State<RentCalculatorPage> createState() => _RentCalculatorPageState();
}

class _RentCalculatorPageState extends State<RentCalculatorPage> {
  late final TextEditingController _weeklyController;
  late final TextEditingController _utilitiesController;
  int _people = 1;
  bool _splitUtilities = true;

  @override
  void initState() {
    super.initState();
    _weeklyController = TextEditingController(
      text: (widget.initialWeeklyRent > 0)
          ? widget.initialWeeklyRent.toStringAsFixed(0)
          : '',
    );
    _utilitiesController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _utilitiesController.dispose();
    super.dispose();
  }

  double _parseMoney(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _money(double value) {
    if (value.isNaN || value.isInfinite) return '\$0';
    return '\$${value.roundToDouble().toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final weeklyRent = _parseMoney(_weeklyController.text);
    final utilitiesWeekly = _parseMoney(_utilitiesController.text);
    final people = _people <= 0 ? 1 : _people;

    final monthlyRent = RentCalculator.monthlyFromWeekly(weeklyRent);
    final yearlyRent = RentCalculator.yearlyFromWeekly(weeklyRent);
    final bond = RentCalculator.bondFromWeekly(weeklyRent);
    final rentPerPerson = RentCalculator.rentPerPersonWeekly(weeklyRent, people);
    final utilitiesPerPerson = RentCalculator.utilitiesPerPersonWeekly(
      utilitiesWeekly,
      people,
    );
    final perPersonTotal = rentPerPerson + (_splitUtilities ? utilitiesPerPerson : 0);
    final moveInCost = RentCalculator.moveInCost(weeklyRent);
    final moveInTotal = moveInCost + (utilitiesWeekly > 0 ? utilitiesWeekly : 0);

    Widget outputTile({
      required String label,
      required String value,
      IconData? icon,
    }) {
      return Card(
        elevation: 0,
        color: const Color(0xFFF9FAFB),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rent Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Quickly estimate rent totals, bond, splits, and move-in cost.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weeklyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weekly rent (AUD)',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'People',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Decrease',
                onPressed: _people <= 1 ? null : () => setState(() => _people -= 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_people',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Increase',
                onPressed: () => setState(() => _people += 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _utilitiesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Utilities per week (optional)',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
              helperText: 'Electricity, gas, internet, etc.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _splitUtilities,
            onChanged: (v) => setState(() => _splitUtilities = v),
            title: const Text('Split utilities between people'),
          ),
          const SizedBox(height: 8),
          outputTile(
            label: 'Weekly rent',
            value: _money(weeklyRent),
            icon: Icons.payments_outlined,
          ),
          outputTile(
            label: 'Monthly rent',
            value: _money(monthlyRent),
            icon: Icons.calendar_month_outlined,
          ),
          outputTile(
            label: 'Yearly rent',
            value: _money(yearlyRent),
            icon: Icons.event_repeat_outlined,
          ),
          outputTile(
            label: 'Bond (4 weeks)',
            value: _money(bond),
            icon: Icons.lock_outline,
          ),
          outputTile(
            label: 'Rent per person',
            value: '${_money(rentPerPerson)}/week',
            icon: Icons.group_outlined,
          ),
          if (utilitiesWeekly > 0) ...[
            outputTile(
              label: 'Utilities per person',
              value: '${_money(utilitiesPerPerson)}/week',
              icon: Icons.wifi_outlined,
            ),
            outputTile(
              label: _splitUtilities
                  ? 'Total per person (incl. utilities)'
                  : 'Total per person (rent only)',
              value: '${_money(perPersonTotal)}/week',
              icon: Icons.calculate_outlined,
            ),
          ],
          outputTile(
            label: 'Move-in cost (bond + 1st week)',
            value: _money(moveInCost),
            icon: Icons.door_front_door_outlined,
          ),
          if (utilitiesWeekly > 0)
            outputTile(
              label: 'Move-in total (incl. utilities estimate)',
              value: _money(moveInTotal),
              icon: Icons.account_balance_wallet_outlined,
            ),
        ],
      ),
    );
  }
}
