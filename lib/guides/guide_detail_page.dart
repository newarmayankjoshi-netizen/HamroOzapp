import 'package:flutter/material.dart';
import 'guide_model.dart';

class GuideDetailPage extends StatefulWidget {
  final Guide guide;

  const GuideDetailPage({super.key, required this.guide});

  @override
  State<GuideDetailPage> createState() => _GuideDetailPageState();
}

class _GuideDetailPageState extends State<GuideDetailPage> {
  bool showNepali = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showNepali ? widget.guide.nepaliTitle.isNotEmpty ? widget.guide.nepaliTitle : widget.guide.title : widget.guide.title),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: widget.guide.sections.map((section) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showNepali ? (section.nepaliTitle.isNotEmpty ? section.nepaliTitle : section.title) : section.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (!showNepali)
                    Text(section.content),
                  if (showNepali && section.nepaliContent != null)
                    Text(section.nepaliContent!),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
