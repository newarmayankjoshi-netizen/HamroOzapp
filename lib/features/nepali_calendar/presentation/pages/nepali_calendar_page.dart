import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hamro_oz/utils/map_utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../data/nepali_calendar_api_model.dart';



class NepaliCalendarPage extends StatefulWidget {
  const NepaliCalendarPage({super.key});

  @override
  State<NepaliCalendarPage> createState() => _NepaliCalendarPageState();
}

class _NepaliCalendarPageState extends State<NepaliCalendarPage> {
  DateTime get today => DateTime.now();

  List<NepaliCalendarDay> days = [];
  int selectedYear = 2083;
  int selectedMonth = 1;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => loading = true);
    final fileName = 'lib/features/nepali_calendar/data/nepali_calendar_$selectedYear.json';
    String data = '';
    try {
      data = await DefaultAssetBundle.of(context).loadString(fileName);
    } catch (e) {
      days = [];
      setState(() => loading = false);
      return;
    }
    final List<dynamic> jsonList = data.isNotEmpty ? List<dynamic>.from(jsonDecode(data)) : [];
    days = jsonList.map<NepaliCalendarDay>((e) => NepaliCalendarDay.fromJson(e)).toList();
    final todayAd = today.toIso8601String().substring(0, 10);
    final todayBs = days.firstWhere(
      (d) => d.adDate == todayAd,
      orElse: () => days.isNotEmpty ? days.first : NepaliCalendarDay(bsDate: '${selectedYear.toString()}-01-01', adDate: todayAd),
    ).bsDate;
    if (todayBs.isNotEmpty) {
      final parts = todayBs.split('-');
      if (parts.length >= 2) {
        selectedYear = int.tryParse(parts[0]) ?? selectedYear;
        selectedMonth = int.tryParse(parts[1]) ?? selectedMonth;
      }
    }
    setState(() => loading = false);
  }
  List<NepaliCalendarDay> get daysInMonth => days.where((d) {
    final parts = d.bsDate.split('-');
    if (parts.length < 2) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    return year == selectedYear && month == selectedMonth;
  }).toList();


  void _nextMonth() {
    // Only allow next month if it exists in the loaded data
    final Map<int, Set<int>> yearToMonths = {};
    for (final d in days) {
      final parts = d.bsDate.split('-');
      if (parts.length < 2) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      yearToMonths.putIfAbsent(y, () => <int>{});
      yearToMonths[y]!.add(m);
    }
    setState(() {
      final months = yearToMonths[selectedYear]?.toList() ?? [];
      months.sort();
      final idx = months.indexOf(selectedMonth);
      if (idx != -1 && idx < months.length - 1) {
        selectedMonth = months[idx + 1];
      } else {
        // Try next year if available
        final years = yearToMonths.keys.toList()..sort();
        final yearIdx = years.indexOf(selectedYear);
        if (yearIdx != -1 && yearIdx < years.length - 1) {
          final nextYear = years[yearIdx + 1];
          final nextMonths = yearToMonths[nextYear]?.toList() ?? [];
          nextMonths.sort();
          if (nextMonths.isNotEmpty) {
            selectedYear = nextYear;
            selectedMonth = nextMonths.first;
          }
        }
      }
    });
  }

  void _prevMonth() {
    // Only allow previous month if it exists in the loaded data
    final Map<int, Set<int>> yearToMonths = {};
    for (final d in days) {
      final parts = d.bsDate.split('-');
      if (parts.length < 2) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      yearToMonths.putIfAbsent(y, () => <int>{});
      yearToMonths[y]!.add(m);
    }
    setState(() {
      final months = yearToMonths[selectedYear]?.toList() ?? [];
      months.sort();
      final idx = months.indexOf(selectedMonth);
      if (idx > 0) {
        selectedMonth = months[idx - 1];
      } else {
        // Try previous year if available
        final years = yearToMonths.keys.toList()..sort();
        final yearIdx = years.indexOf(selectedYear);
        if (yearIdx > 0) {
          final prevYear = years[yearIdx - 1];
          final prevMonths = yearToMonths[prevYear]?.toList() ?? [];
          prevMonths.sort();
          if (prevMonths.isNotEmpty) {
            selectedYear = prevYear;
            selectedMonth = prevMonths.last;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nepali Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            // Use raster map icon asset (replace assets/australia_map.png with provided image)
            icon: Image.asset('assets/australia_map.jpg', width: 26, height: 26),
            tooltip: 'Australian Holidays',
            onPressed: () {
              // selectedYear/selectedMonth are BS (Bikram Sambat). Convert to AD year
              final monthDays = days.where((d) {
                final parts = d.bsDate.split('-');
                if (parts.length < 2) return false;
                final y = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                return y == selectedYear && m == selectedMonth;
              }).toList();
              if (monthDays.isEmpty) {
                _showAustralianHolidays(context, DateTime.now().year);
                return;
              }
              final firstAd = monthDays.first.adDate;
              final adYear = DateTime.tryParse(firstAd)?.year ?? DateTime.now().year;
              _showAustralianHolidays(context, adYear);
            },
          ),
        ],
      ),
      // FloatingActionButton removed — app now uses the top month controls.
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom + 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildMonthHeader(theme),
                      const SizedBox(height: 8),
                      _buildDayLabels(theme),
                      Expanded(child: _buildCalendarGrid(theme)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme) {

    final months = [
      '', 'Baishakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
    ];

    // Collect all unique (year, month) pairs from the loaded data
    final Set<int> availableYears = {};
    final Map<int, Set<int>> yearToMonths = {};
    for (final d in days) {
      final parts = d.bsDate.split('-');
      if (parts.length < 2) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      availableYears.add(y);
      yearToMonths.putIfAbsent(y, () => <int>{});
      yearToMonths[y]!.add(m);
    }
    final years = availableYears.toList()..sort();
    final availableMonths = yearToMonths[selectedYear]?.toList() ?? [];
    availableMonths.sort();

    final daysInSelectedMonth = days.where((d) {
      final bsParts = d.bsDate.split('-');
      if (bsParts.length < 2) return false;
      final y = int.tryParse(bsParts[0]);
      final m = int.tryParse(bsParts[1]);
      return y == selectedYear && m == selectedMonth;
    }).toList();

    String adDisplay = '';
    if (daysInSelectedMonth.isNotEmpty) {
      final firstAd = daysInSelectedMonth.first.adDate;
      final lastAd = daysInSelectedMonth.last.adDate;
      final firstDate = DateTime.tryParse(firstAd);
      final lastDate = DateTime.tryParse(lastAd);
      if (firstDate != null && lastDate != null) {
        final adMonths = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final firstMonth = adMonths[firstDate.month];
        final lastMonth = adMonths[lastDate.month];
        if (firstMonth == lastMonth) {
          adDisplay = '$firstMonth ${firstDate.year}';
        } else if (firstDate.year == lastDate.year) {
          adDisplay = '$firstMonth/$lastMonth ${firstDate.year}';
        } else {
          adDisplay = '$firstMonth ${firstDate.year}/$lastMonth ${lastDate.year}';
        }
      }
    }

    // Determine if previous/next month is available
    bool hasPrev = false, hasNext = false;
    final sortedYears = years;
    final yearIdx = sortedYears.indexOf(selectedYear);
    final monthsInYear = yearToMonths[selectedYear]?.toList() ?? [];
    monthsInYear.sort();
    final monthIdx = monthsInYear.indexOf(selectedMonth);
    if (monthIdx > 0) {
      hasPrev = true;
    } else if (yearIdx > 0) {
      final prevYear = sortedYears[yearIdx - 1];
      final prevMonths = yearToMonths[prevYear]?.toList() ?? [];
      if (prevMonths.isNotEmpty) hasPrev = true;
    }
    if (monthIdx < monthsInYear.length - 1) {
      hasNext = true;
    } else if (yearIdx < sortedYears.length - 1) {
      final nextYear = sortedYears[yearIdx + 1];
      final nextMonths = yearToMonths[nextYear]?.toList() ?? [];
      if (nextMonths.isNotEmpty) hasNext = true;
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: hasPrev ? _prevMonth : null,
          ),
          DropdownButton<int>(
            value: selectedYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (y) async {
              if (y != null && y != selectedYear) {
                selectedYear = y;
                if (!(yearToMonths[y]?.contains(selectedMonth) ?? false)) {
                  selectedMonth = yearToMonths[y]?.first ?? 1;
                }
                await _loadCalendarData();
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 4),
          DropdownButton<int>(
            value: selectedMonth,
            items: availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(months[m]))).toList(),
            onChanged: (m) => setState(() => selectedMonth = m ?? selectedMonth),
          ),
          const SizedBox(width: 8),
          Text(
            adDisplay.isNotEmpty ? adDisplay : 'AD',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: hasNext ? _nextMonth : null,
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildDayLabels(ThemeData theme) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final daysList = daysInMonth;
    if (daysList.isEmpty) {
      return const Center(child: Text('No data for this month or year. Please add the data file.'));
    }
    final firstDay = daysList.first;
    final firstDate = DateTime.parse(firstDay.adDate);
    int firstWeekday = firstDate.weekday;
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    final totalDays = daysList.length;
    int totalCells = firstWeekday + totalDays;
    int numRows = (totalCells / 7).ceil();
    int gridCellCount = numRows * 7;
    final gridCells = List<Widget>.filled(gridCellCount, Container(), growable: false);
    for (int i = 0; i < firstWeekday; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    for (int i = 0; i < totalDays; i++) {
      final d = daysList[i];
      final isToday = d.adDate == today.toIso8601String().substring(0, 10);
      final hasFestival = d.festival != null && d.festival!.isNotEmpty;
      final hasHoliday = d.publicHoliday != null && d.publicHoliday!.isNotEmpty;
      final events = <String>[];
      if (hasFestival) events.add(d.festival!);
      if (hasHoliday) events.add(d.publicHoliday!);
      final eventCount = events.length;
      gridCells[firstWeekday + i] = GestureDetector(
        onTap: () => _showDayDetails(d),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isToday ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? Colors.green : Colors.grey.shade300,
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (isToday)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 0.5),
            child: Builder(
              builder: (cellContext) {
                final screenWidth = MediaQuery.of(cellContext).size.width;
                double dayFont = 22;
                if (screenWidth < 360) {
                  dayFont = 16;
                } else if (screenWidth < 420) {
                  dayFont = 20;
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Do not display festival text inline. Show +n badge only when multiple events exist.
                    if (eventCount > 1)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 2.0),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+${eventCount - 1}', style: TextStyle(color: Colors.red.shade700, fontSize: 10)),
                        ),
                      ),
                    const SizedBox(height: 0),
                    AutoSizeText(
                      d.bsDate.split('-')[2],
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: dayFont,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Colors.green.shade900
                            : (hasFestival || hasHoliday ? Colors.red.shade700 : Colors.black),
                      ),
                    ),
                    // Lift the AD date slightly so it sits closer to the BS date
                    Transform.translate(
                      offset: const Offset(0, -1),
                      child: AutoSizeText(
                        d.adDate.substring(8, 10),
                        maxLines: 1,
                        minFontSize: 8,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }
    for (int i = firstWeekday + totalDays; i < gridCellCount; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          double aspect = 0.95;
          if (width < 360) {
            aspect = 0.75; // small screens - taller cells
          } else if (width < 600) {
            aspect = 0.95; // medium
          } else {
            aspect = 1.15; // large - slightly wider cells
          }
          return GridView.count(
            crossAxisCount: 7,
            childAspectRatio: aspect,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: gridCells,
          );
        },
      ),
    );
  }

  void _showDayDetails(NepaliCalendarDay d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0 + bottomPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BS: ${d.bsDate}', style: Theme.of(context).textTheme.titleLarge),
                    Text('AD: ${d.adDate}', style: Theme.of(context).textTheme.bodyMedium),
                    if (d.festival != null && d.festival!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.celebration, color: Colors.orangeAccent),
                            const SizedBox(width: 8),
                            Text('Festival: ${d.festival!}', style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    if (d.publicHoliday != null && d.publicHoliday!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.flag, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text('Public Holiday: ${d.publicHoliday!}', style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    if (d.description != null && d.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(d.description!, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _fetchAustralianHolidays(int year) async {
    final url = 'https://date.nager.at/api/v3/PublicHolidays/$year/AU';
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      }
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      // try local asset fallback
      try {
        final assetPath = 'assets/australia_holidays_$year.json';
        final data = await rootBundle.loadString(assetPath);
        return jsonDecode(data) as List<dynamic>;
      } catch (fallbackErr) {
        throw Exception('Network/fetch error: $e; fallback error: $fallbackErr');
      }
    }
  }

  Future<void> _showAustralianHolidays(BuildContext context, int year) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<dynamic>>(
            future: _fetchAustralianHolidays(year),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 200,
                  child: Center(child: Text('Failed to load Australian holidays:\n${snapshot.error}')),
                );
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return SizedBox(height: 200, child: Center(child: Text('No holidays for $year')));
              }
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Australian Holidays — $year', style: Theme.of(context).textTheme.titleLarge)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final item = toStringKeyMap(list[i]);
                          final dateStr = item['date'] as String? ?? '';
                          final parsed = DateTime.tryParse(dateStr);
                          final displayDate = parsed != null ? DateFormat('dd MMM').format(parsed) : dateStr;
                          final name = item['localName'] as String? ?? item['name'] as String? ?? '';
                          return ListTile(
                            leading: Text(displayDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                            title: Text(name),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
/*class NepaliCalendarPage extends StatefulWidget {
  const NepaliCalendarPage({Key? key}) : super(key: key);

  @override
  State<NepaliCalendarPage> createState() => _NepaliCalendarPageState();
}

class _NepaliCalendarPageState extends State<NepaliCalendarPage> {
  DateTime get today => DateTime.now();

  List<NepaliCalendarDay> days = [];
  int selectedYear = 2083;
  int selectedMonth = 1;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => loading = true);
    final fileName = 'lib/features/nepali_calendar/data/nepali_calendar_' + selectedYear.toString() + '.json';
    String data = '';
    try {
      data = await DefaultAssetBundle.of(context).loadString(fileName);
    } catch (e) {
      days = [];
      setState(() => loading = false);
      return;
    }
    final List<dynamic> jsonList = data.isNotEmpty ? List<dynamic>.from(jsonDecode(data)) : [];
    days = jsonList.map<NepaliCalendarDay>((e) => NepaliCalendarDay.fromJson(e)).toList();
    final todayAd = today.toIso8601String().substring(0, 10);
    final todayBs = days.firstWhere(
      (d) => d.adDate == todayAd,
      orElse: () => days.isNotEmpty ? days.first : NepaliCalendarDay(bsDate: '${selectedYear.toString()}-01-01', adDate: todayAd),
    ).bsDate;
    if (todayBs.isNotEmpty) {
      final parts = todayBs.split('-');
      if (parts.length >= 2) {
        selectedYear = int.tryParse(parts[0]) ?? selectedYear;
        selectedMonth = int.tryParse(parts[1]) ?? selectedMonth;
      }
    }
    setState(() => loading = false);
  }

  List<NepaliCalendarDay> get daysInMonth => days.where((d) {
    final parts = d.bsDate.split('-');
    if (parts.length < 2) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    return year == selectedYear && month == selectedMonth;
  }).toList();

  void _nextMonth() {
    setState(() {
      if (selectedMonth < 12) {
        selectedMonth++;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      if (selectedMonth > 1) {
        selectedMonth--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nepali Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            tooltip: 'Show Festivals',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.today),
        label: const Text('Today'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildMonthHeader(theme),
                  const SizedBox(height: 8),
                  _buildDayLabels(theme),
                  Expanded(child: _buildCalendarGrid(theme)),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme) {
    final months = [
      '', 'Baishakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
    ];
    final years = List.generate(10, (i) => 2083 - i);

    final daysInSelectedMonth = days.where((d) {
      final bsParts = d.bsDate.split('-');
      if (bsParts.length < 2) return false;
      final y = int.tryParse(bsParts[0]);
      final m = int.tryParse(bsParts[1]);
      return y == selectedYear && m == selectedMonth;
    }).toList();

    String adDisplay = '';
    if (daysInSelectedMonth.isNotEmpty) {
      final firstAd = daysInSelectedMonth.first.adDate;
      final lastAd = daysInSelectedMonth.last.adDate;
      final firstDate = DateTime.tryParse(firstAd);
      final lastDate = DateTime.tryParse(lastAd);
      if (firstDate != null && lastDate != null) {
        final adMonths = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final firstMonth = adMonths[firstDate.month];
        final lastMonth = adMonths[lastDate.month];
        if (firstMonth == lastMonth) {
          adDisplay = '$firstMonth ${firstDate.year}';
        } else if (firstDate.year == lastDate.year) {
          adDisplay = '$firstMonth/$lastMonth ${firstDate.year}';
        } else {
          adDisplay = '$firstMonth ${firstDate.year}/$lastMonth ${lastDate.year}';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: selectedMonth > 1 ? _prevMonth : null,
          ),
          DropdownButton<int>(
            value: selectedYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (y) async {
              if (y != null && y != selectedYear) {
                selectedYear = y;
                await _loadCalendarData();
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 4),
          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(months[i+1]))),
            onChanged: (m) => setState(() => selectedMonth = m ?? selectedMonth),
          ),
          const SizedBox(width: 8),
          Text(
            '$selectedYear/${adDisplay.isNotEmpty ? adDisplay : 'AD'}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: selectedMonth < 12 ? _nextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels(ThemeData theme) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final daysList = daysInMonth;
    if (daysList.isEmpty) {
      return const Center(child: Text('No data for this month or year. Please add the data file.'));
    }
    final firstDay = daysList.first;
    final firstDate = DateTime.parse(firstDay.adDate);
    int firstWeekday = firstDate.weekday;
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    final totalDays = daysList.length;
    int totalCells = firstWeekday + totalDays;
    int numRows = (totalCells / 7).ceil();
    int gridCellCount = numRows * 7;
    final gridCells = List<Widget>.filled(gridCellCount, Container(), growable: false);
    for (int i = 0; i < firstWeekday; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    for (int i = 0; i < totalDays; i++) {
      final d = daysList[i];
      final isToday = d.adDate == today.toIso8601String().substring(0, 10);
      final hasFestival = d.festival != null && d.festival!.isNotEmpty;
      final hasHoliday = d.publicHoliday != null && d.publicHoliday!.isNotEmpty;
      gridCells[firstWeekday + i] = GestureDetector(
        onTap: () => _showDayDetails(d),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isToday ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? Colors.green : Colors.grey.shade300,
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (isToday)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasFestival || hasHoliday)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, left: 2.0, right: 2.0),
                    child: Text(
                      d.festival ?? d.publicHoliday ?? '',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                Text(
                  d.bsDate.split('-')[2],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.green.shade900 : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.adDate.substring(8, 10),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    for (int i = firstWeekday + totalDays; i < gridCellCount; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: gridCells,
      ),
    );
  }

  void _showDayDetails(NepaliCalendarDay d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BS: ${d.bsDate}', style: Theme.of(context).textTheme.titleLarge),
              Text('AD: ${d.adDate}', style: Theme.of(context).textTheme.bodyMedium),
              if (d.festival != null && d.festival!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Text('Festival: ${d.festival!}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              if (d.publicHoliday != null && d.publicHoliday!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('Public Holiday: ${d.publicHoliday!}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              if (d.description != null && d.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(d.description!, style: Theme.of(context).textTheme.bodyMedium),
                ),
            ],
          ),
        );
      },
    );
  }
}
      setState(() => loading = false);
      return;
    }
    final List<dynamic> jsonList = data.isNotEmpty ? List<dynamic>.from(jsonDecode(data)) : [];
    days = jsonList.map<NepaliCalendarDay>((e) => NepaliCalendarDay.fromJson(e)).toList();
    final todayAd = today.toIso8601String().substring(0, 10);
    final todayBs = days.firstWhere(
      (d) => d.adDate == todayAd,
      orElse: () => days.isNotEmpty ? days.first : NepaliCalendarDay(bsDate: '${selectedYear.toString()}-01-01', adDate: todayAd),
    ).bsDate;
    if (todayBs.isNotEmpty) {
      final parts = todayBs.split('-');
      if (parts.length >= 2) {
        selectedYear = int.tryParse(parts[0]) ?? selectedYear;
        selectedMonth = int.tryParse(parts[1]) ?? selectedMonth;
      }
    }
    setState(() => loading = false);
  }

  List<NepaliCalendarDay> get daysInMonth => days.where((d) {
    final parts = d.bsDate.split('-');
    if (parts.length < 2) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    return year == selectedYear && month == selectedMonth;
  }).toList();

  void _nextMonth() {
    setState(() {
      if (selectedMonth < 12) {
        selectedMonth++;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      if (selectedMonth > 1) {
        selectedMonth--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nepali Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            tooltip: 'Show Festivals',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.today),
        label: const Text('Today'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildMonthHeader(theme),
                  const SizedBox(height: 8),
                  _buildDayLabels(theme),
                  Expanded(child: _buildCalendarGrid(theme)),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme) {
    final months = [
      '', 'Baishakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
    ];
    final years = List.generate(10, (i) => 2083 - i);

    final daysInSelectedMonth = days.where((d) {
      final bsParts = d.bsDate.split('-');
      if (bsParts.length < 2) return false;
      final y = int.tryParse(bsParts[0]);
      final m = int.tryParse(bsParts[1]);
      return y == selectedYear && m == selectedMonth;
    }).toList();

    String adDisplay = '';
    if (daysInSelectedMonth.isNotEmpty) {
      final firstAd = daysInSelectedMonth.first.adDate;
      final lastAd = daysInSelectedMonth.last.adDate;
      final firstDate = DateTime.tryParse(firstAd);
      final lastDate = DateTime.tryParse(lastAd);
      if (firstDate != null && lastDate != null) {
        final adMonths = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final firstMonth = adMonths[firstDate.month];
        final lastMonth = adMonths[lastDate.month];
        if (firstMonth == lastMonth) {
          adDisplay = '$firstMonth ${firstDate.year}';
        } else if (firstDate.year == lastDate.year) {
          adDisplay = '$firstMonth/$lastMonth ${firstDate.year}';
        } else {
          adDisplay = '$firstMonth ${firstDate.year}/$lastMonth ${lastDate.year}';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 32),
            onPressed: selectedMonth > 1 ? _prevMonth : null,
          ),
          DropdownButton<int>(
            value: selectedYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (y) async {
              if (y != null && y != selectedYear) {
                selectedYear = y;
                await _loadCalendarData();
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(months[i+1]))),
            onChanged: (m) => setState(() => selectedMonth = m ?? selectedMonth),
          ),
          const SizedBox(width: 16),
          Text(
            '$selectedYear/${adDisplay.isNotEmpty ? adDisplay : 'AD'}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 32),
            onPressed: selectedMonth < 12 ? _nextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels(ThemeData theme) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days
            .map((d) => Flexible(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final daysList = daysInMonth;
    if (daysList.isEmpty) {
      return const Center(child: Text('No data for this month or year. Please add the data file.'));
    }
    final firstDay = daysList.first;
    final firstDate = DateTime.parse(firstDay.adDate);
    int firstWeekday = firstDate.weekday;
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    final totalDays = daysList.length;
    int totalCells = firstWeekday + totalDays;
    int numRows = (totalCells / 7).ceil();
    int gridCellCount = numRows * 7;
    final gridCells = List<Widget>.filled(gridCellCount, Container(), growable: false);
    for (int i = 0; i < firstWeekday; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    for (int i = 0; i < totalDays; i++) {
      final d = daysList[i];
      final isToday = d.adDate == today.toIso8601String().substring(0, 10);
      final hasFestival = d.festival != null && d.festival!.isNotEmpty;
      final hasHoliday = d.publicHoliday != null && d.publicHoliday!.isNotEmpty;
      gridCells[firstWeekday + i] = GestureDetector(
        onTap: () => _showDayDetails(d),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isToday ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? Colors.green : Colors.grey.shade300,
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (isToday)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasFestival || hasHoliday)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, left: 2.0, right: 2.0),
                    child: Text(
                      d.festival ?? d.publicHoliday ?? '',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                Text(
                  d.bsDate.split('-')[2],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.green.shade900 : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.adDate.substring(8, 10),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    for (int i = firstWeekday + totalDays; i < gridCellCount; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: gridCells,
      ),
    );
  }

  void _showDayDetails(NepaliCalendarDay d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BS: d.bsDate}', style: Theme.of(context).textTheme.titleLarge),
              // ...existing code...
            ],
          ),
        );
      },
    );
    // ...existing code...
    try {
      final List<dynamic> jsonList = data.isNotEmpty ? List<dynamic>.from(jsonDecode(data)) : [];
      days = jsonList.map<NepaliCalendarDay>((e) => NepaliCalendarDay.fromJson(e)).toList();
      final todayAd = today.toIso8601String().substring(0, 10);
      final todayBs = days.firstWhere(
        (d) => d.adDate == todayAd,
        orElse: () => days.isNotEmpty ? days.first : NepaliCalendarDay(bsDate: '${selectedYear.toString()}-01-01', adDate: todayAd),
      ).bsDate;
      if (todayBs.isNotEmpty) {
        final parts = todayBs.split('-');
        if (parts.length >= 2) {
          selectedYear = int.tryParse(parts[0]) ?? selectedYear;
          selectedMonth = int.tryParse(parts[1]) ?? selectedMonth;
        }
      }
      setState(() => loading = false);
    } catch (e) {
      days = [];
      setState(() => loading = false);
      return;
    }

  List<NepaliCalendarDay> get daysInMonth {
    return days.where((d) {
      final parts = d.bsDate.split('-');
      if (parts.length < 2) return false;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      return year == selectedYear && month == selectedMonth;
    }).toList();
  }

  void _nextMonth() {
    setState(() {
      if (selectedMonth < 12) {
        selectedMonth++;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      if (selectedMonth > 1) {
        selectedMonth--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nepali Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
          ),
        ],
      ); // End of children
    }
  }
  // ...existing code...
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme) {
    final months = [
      '', 'Baishakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
    ];
    final years = List.generate(10, (i) => 2083 - i);

    final daysInSelectedMonth = days.where((d) {
      final bsParts = d.bsDate.split('-');
      if (bsParts.length < 2) return false;
      final y = int.tryParse(bsParts[0]);
      final m = int.tryParse(bsParts[1]);
      return y == selectedYear && m == selectedMonth;
    }).toList();

    String adDisplay = '';
    if (daysInSelectedMonth.isNotEmpty) {
      final firstAd = daysInSelectedMonth.first.adDate;
      final lastAd = daysInSelectedMonth.last.adDate;
      final firstDate = DateTime.tryParse(firstAd);
      final lastDate = DateTime.tryParse(lastAd);
      if (firstDate != null && lastDate != null) {
        final adMonths = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final firstMonth = adMonths[firstDate.month];
        final lastMonth = adMonths[lastDate.month];
        if (firstMonth == lastMonth) {
          adDisplay = '$firstMonth ${firstDate.year}';
        } else if (firstDate.year == lastDate.year) {
          adDisplay = '$firstMonth/$lastMonth ${firstDate.year}';
        } else {
          adDisplay = '$firstMonth ${firstDate.year}/$lastMonth ${lastDate.year}';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 32),
            onPressed: selectedMonth > 1 ? _prevMonth : null,
          ),
          DropdownButton<int>(
            value: selectedYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (y) async {
              if (y != null && y != selectedYear) {
                selectedYear = y;
                await _loadCalendarData();
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(months[i+1]))),
            onChanged: (m) => setState(() => selectedMonth = m ?? selectedMonth),
          ),
          const SizedBox(width: 16),
          Text(
            '$selectedYear/${adDisplay.isNotEmpty ? adDisplay : 'AD'}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 32),
            onPressed: selectedMonth < 12 ? _nextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels(ThemeData theme) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days
            .map((d) => Flexible(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final daysList = daysInMonth;
    if (daysList.isEmpty) {
      return const Center(child: Text('No data for this month or year. Please add the data file.'));
    }
    final firstDay = daysList.first;
    final firstDate = DateTime.parse(firstDay.adDate);
    int firstWeekday = firstDate.weekday;
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    final totalDays = daysList.length;
    int totalCells = firstWeekday + totalDays;
    int numRows = (totalCells / 7).ceil();
    int gridCellCount = numRows * 7;
    final gridCells = List<Widget>.filled(gridCellCount, Container(), growable: false);
    for (int i = 0; i < firstWeekday; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    for (int i = 0; i < totalDays; i++) {
      final d = daysList[i];
      final isToday = d.adDate == today.toIso8601String().substring(0, 10);
      final hasFestival = d.festival != null && d.festival!.isNotEmpty;
      final hasHoliday = d.publicHoliday != null && d.publicHoliday!.isNotEmpty;
      gridCells[firstWeekday + i] = GestureDetector(
        onTap: () => _showDayDetails(d),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isToday ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? Colors.green : Colors.grey.shade300,
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (isToday)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasFestival || hasHoliday)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, left: 2.0, right: 2.0),
                    child: Text(
                      d.festival ?? d.publicHoliday ?? '',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                Text(
                  d.bsDate.split('-')[2],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.green.shade900 : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.adDate.substring(8, 10),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    for (int i = firstWeekday + totalDays; i < gridCellCount; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: gridCells,
      ),
    );
  }

  void _showDayDetails(NepaliCalendarDay d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BS: ${d.bsDate}', style: Theme.of(context).textTheme.titleLarge),
              Text('AD: ${d.adDate}', style: Theme.of(context).textTheme.bodyMedium),
              if (d.festival != null && d.festival!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Text('Festival: ${d.festival!}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              if (d.publicHoliday != null && d.publicHoliday!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('Public Holiday: ${d.publicHoliday!}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              if (d.description != null && d.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(d.description!, style: Theme.of(context).textTheme.bodyMedium),
                ),
            ],
          ),
        );
      },
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.today),
        label: const Text('Today'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildMonthHeader(theme),
                  const SizedBox(height: 8),
                  _buildDayLabels(theme),
                  Expanded(child: _buildCalendarGrid(theme)),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme) {
    final months = [
      '', 'Baishakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
    ];
    final years = List.generate(10, (i) => 2083 - i);

    final daysInSelectedMonth = days.where((d) {
      final bsParts = d.bsDate.split('-');
      if (bsParts.length < 2) return false;
      final y = int.tryParse(bsParts[0]);
      final m = int.tryParse(bsParts[1]);
      return y == selectedYear && m == selectedMonth;
    }).toList();

    String adDisplay = '';
    if (daysInSelectedMonth.isNotEmpty) {
      final firstAd = daysInSelectedMonth.first.adDate;
      final lastAd = daysInSelectedMonth.last.adDate;
      final firstDate = DateTime.tryParse(firstAd);
      final lastDate = DateTime.tryParse(lastAd);
      if (firstDate != null && lastDate != null) {
        final adMonths = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final firstMonth = adMonths[firstDate.month];
        final lastMonth = adMonths[lastDate.month];
        if (firstMonth == lastMonth) {
          adDisplay = '$firstMonth ${firstDate.year}';
        } else if (firstDate.year == lastDate.year) {
          adDisplay = '$firstMonth/$lastMonth ${firstDate.year}';
        } else {
          adDisplay = '$firstMonth ${firstDate.year}/$lastMonth ${lastDate.year}';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 32),
            onPressed: selectedMonth > 1 ? _prevMonth : null,
          ),
          DropdownButton<int>(
            value: selectedYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (y) async {
              if (y != null && y != selectedYear) {
                selectedYear = y;
                await _loadCalendarData();
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(months[i+1]))),
            onChanged: (m) => setState(() => selectedMonth = m ?? selectedMonth),
          ),
          const SizedBox(width: 16),
          Text(
            '$selectedYear/${adDisplay.isNotEmpty ? adDisplay : 'AD'}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 32),
            onPressed: selectedMonth < 12 ? _nextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels(ThemeData theme) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days
            .map((d) => Flexible(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final daysList = daysInMonth;
    if (daysList.isEmpty) {
      return const Center(child: Text('No data for this month or year. Please add the data file.'));
    }
    final firstDay = daysList.first;
    final firstDate = DateTime.parse(firstDay.adDate);
    int firstWeekday = firstDate.weekday;
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    final totalDays = daysList.length;
    int totalCells = firstWeekday + totalDays;
    int numRows = (totalCells / 7).ceil();
    int gridCellCount = numRows * 7;
    final gridCells = List<Widget>.filled(gridCellCount, Container(), growable: false);
    for (int i = 0; i < firstWeekday; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    for (int i = 0; i < totalDays; i++) {
      final d = daysList[i];
      final isToday = d.adDate == today.toIso8601String().substring(0, 10);
      final hasFestival = d.festival != null && d.festival!.isNotEmpty;
      final hasHoliday = d.publicHoliday != null && d.publicHoliday!.isNotEmpty;
      gridCells[firstWeekday + i] = GestureDetector(
        onTap: () => _showDayDetails(d),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isToday ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? Colors.green : Colors.grey.shade300,
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (isToday)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasFestival || hasHoliday)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, left: 2.0, right: 2.0),
                    child: Text(
                      d.festival ?? d.publicHoliday ?? '',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                Text(
                  d.bsDate.split('-')[2],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.green.shade900 : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.adDate.substring(8, 10),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    for (int i = firstWeekday + totalDays; i < gridCellCount; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: gridCells,
      ),
    );
  }

  void _showDayDetails(NepaliCalendarDay d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BS: ${d.bsDate}', style: Theme.of(context).textTheme.titleLarge),
              Text('AD: ${d.adDate}', style: Theme.of(context).textTheme.bodyMedium),
              if (d.festival != null && d.festival!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Text('Festival: ${d.festival!}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              if (d.publicHoliday != null && d.publicHoliday!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('Public Holiday: ${d.publicHoliday!}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              if (d.description != null && d.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(d.description!, style: Theme.of(context).textTheme.bodyMedium),
                ),
            ],
          ),
        );
      },
    );
  }
  }

  void _nextMonth() {
    setState(() {
      if (selectedMonth < 12) {
        selectedMonth++;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      if (selectedMonth > 1) {
        selectedMonth--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nepali Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            tooltip: 'Show Festivals',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.today),
        label: const Text('Today'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildMonthHeader(theme),
                  const SizedBox(height: 8),
                  _buildDayLabels(theme),
                  Expanded(child: _buildCalendarGrid(theme)),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme) {
    final months = [
      '', 'Baishakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
    ];
    final years = List.generate(10, (i) => 2083 - i);

    final daysInSelectedMonth = days.where((d) {
      final bsParts = d.bsDate.split('-');
      if (bsParts.length < 2) return false;
      final y = int.tryParse(bsParts[0]);
      final m = int.tryParse(bsParts[1]);
      return y == selectedYear && m == selectedMonth;
    }).toList();

    String adDisplay = '';
    if (daysInSelectedMonth.isNotEmpty) {
      final firstAd = daysInSelectedMonth.first.adDate;
      final lastAd = daysInSelectedMonth.last.adDate;
      final firstDate = DateTime.tryParse(firstAd);
      final lastDate = DateTime.tryParse(lastAd);
      if (firstDate != null && lastDate != null) {
        final months = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final firstMonth = months[firstDate.month];
        final lastMonth = months[lastDate.month];
        if (firstMonth == lastMonth) {
          adDisplay = '$firstMonth ${firstDate.year}';
        } else if (firstDate.year == lastDate.year) {
          adDisplay = '$firstMonth/$lastMonth ${firstDate.year}';
        } else {
          adDisplay = '$firstMonth ${firstDate.year}/$lastMonth ${lastDate.year}';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 32),
            onPressed: selectedMonth > 1 ? _prevMonth : null,
          ),
          DropdownButton<int>(
            value: selectedYear,
            items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (y) async {
              if (y != null && y != selectedYear) {
                selectedYear = y;
                await _loadCalendarData();
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(months[i+1]))),
            onChanged: (m) => setState(() => selectedMonth = m ?? selectedMonth),
          ),
          const SizedBox(width: 16),
          Text(
            '$selectedYear/${adDisplay.isNotEmpty ? adDisplay : 'AD'}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 32),
            onPressed: selectedMonth < 12 ? _nextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabels(ThemeData theme) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days
            .map((d) => Flexible(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final daysList = daysInMonth;
    if (daysList.isEmpty) {
      return const Center(child: Text('No data for this month or year. Please add the data file.'));
    }
    final firstDay = daysList.first;
    final firstDate = DateTime.parse(firstDay.adDate);
    int firstWeekday = firstDate.weekday;
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    final totalDays = daysList.length;
    int totalCells = firstWeekday + totalDays;
    int numRows = (totalCells / 7).ceil();
    int gridCellCount = numRows * 7;
    final gridCells = List<Widget>.filled(gridCellCount, Container(), growable: false);
    for (int i = 0; i < firstWeekday; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    for (int i = 0; i < totalDays; i++) {
      final d = daysList[i];
      final isToday = d.adDate == today.toIso8601String().substring(0, 10);
      final hasFestival = d.festival != null && d.festival!.isNotEmpty;
      final hasHoliday = d.publicHoliday != null && d.publicHoliday!.isNotEmpty;
      gridCells[firstWeekday + i] = GestureDetector(
        onTap: () => _showDayDetails(d),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? Colors.green : Colors.grey.shade300,
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (isToday)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasFestival || hasHoliday)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, left: 2.0, right: 2.0),
                    child: Text(
                      d.festival ?? d.publicHoliday ?? '',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                Text(
                  d.bsDate.split('-')[2],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.green.shade900 : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.adDate.substring(8, 10),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    for (int i = firstWeekday + totalDays; i < gridCellCount; i++) {
      gridCells[i] = Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: gridCells,
      ),
    );
  }

  void _showDayDetails(NepaliCalendarDay d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BS: ${d.bsDate}', style: Theme.of(context).textTheme.titleLarge),
              Text('AD: ${d.adDate}', style: Theme.of(context).textTheme.bodyMedium),
              if (d.festival != null && d.festival!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Text('Festival: ${d.festival!}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              if (d.publicHoliday != null && d.publicHoliday!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('Public Holiday: ${d.publicHoliday!}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              if (d.description != null && d.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(d.description!, style: Theme.of(context).textTheme.bodyMedium),
                ),
            ],
          ),
        );
      },*/
  