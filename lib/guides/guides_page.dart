import 'package:flutter/material.dart';
import 'guide_detail_page.dart';
import 'guide_model.dart';
// ignore: unused_import
import 'guide_section_widget.dart';



class GuidesPage extends StatefulWidget {
  const GuidesPage({super.key});

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends State<GuidesPage> {
  bool showNepali = false;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final guides = allGuides.where((guide) {
      final query = searchQuery.toLowerCase();
      return showNepali
        ? guide.nepaliTitle.toLowerCase().contains(query)
        : guide.title.toLowerCase().contains(query) || guide.subtitle.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guides'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ToggleButtons(
              isSelected: [!showNepali, showNepali],
              onPressed: (int index) {
                setState(() {
                  showNepali = index == 1;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('English'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('नेपाली'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: showNepali ? 'नेपालीमा खोज्नुहोस्...' : 'Search guides...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: guides.length,
              itemBuilder: (context, index) {
                final guide = guides[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuideDetailPage(guide: guide),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(guide.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  showNepali ? guide.nepaliTitle : guide.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (!showNepali && guide.nepaliTitle.isNotEmpty)
                                  Text(
                                    guide.nepaliTitle,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  guide.subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
