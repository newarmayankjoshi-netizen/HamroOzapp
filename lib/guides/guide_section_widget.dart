import 'package:flutter/material.dart';
import 'guide_model.dart';

class GuideSectionWidget extends StatefulWidget {
  final GuideSection section;
  const GuideSectionWidget({super.key, required this.section});

  @override
  State<GuideSectionWidget> createState() => _GuideSectionWidgetState();
}

class _GuideSectionWidgetState extends State<GuideSectionWidget> {
  bool showNepali = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // English title
            Text(
              widget.section.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // English content
            Text(
              widget.section.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 12),

            // Toggle button
            if (widget.section.nepaliContent != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    showNepali = !showNepali;
                  });
                },
                child: Text(
                  showNepali
                      ? "Hide Nepali Translation"
                      : "Show Nepali Translation",
                ),
              ),

            // Nepali content
            if (showNepali && widget.section.nepaliContent != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.section.nepaliTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.section.nepaliContent!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
