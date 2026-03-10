import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final urlRegExp = RegExp(r"(https?:\/\/[\w\-\.\/~\?\#\&\=\%\+\:;,@]+)");

// Helper to render a bank link row and open the URL externally.
Widget bankLinkRow(BuildContext context, String name, String url) {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
    child: Row(
      children: [
        Expanded(child: Text(name)),
        TextButton.icon(
          onPressed: () async {
            final uri = Uri.parse(url);
            final messenger = ScaffoldMessenger.of(context);
            bool opened = false;
            try {
              opened = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              opened = false;
            }
            if (!opened) {
              messenger.showSnackBar(
                SnackBar(content: Text('Could not open link')),
              );
            }
          },
          icon: Icon(Icons.open_in_new, size: 18),
          label: Text('Apply'),
        ),
      ],
    ),
  );
}

PreferredSizeWidget buildGuideAppBar(String title) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    backgroundColor: Color(0xFF2193b0),
    foregroundColor: Colors.white,
    elevation: 0,
  );
}

Widget wrapGuideBody(BuildContext context, Widget child) {
  return Theme(
    data: Theme.of(context).copyWith(
      cardTheme: CardThemeData(
        elevation: 2,
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    child: child,
  );
}

Widget buildStep(String title, String subtitle, List<String> points) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle),
          ],
          const SizedBox(height: 8),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(point)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildStepNepali(String title, String subtitle, List<String> points) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle),
          ],
          const SizedBox(height: 8),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(point)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
