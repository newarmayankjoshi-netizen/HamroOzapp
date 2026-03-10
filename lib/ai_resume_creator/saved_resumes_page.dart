import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'ai_resume_pdf.dart';
import 'ai_resume_preview.dart';
import 'ai_resume_storage.dart';

class SavedResumesPage extends StatefulWidget {
  const SavedResumesPage({super.key});

  @override
  State<SavedResumesPage> createState() => _SavedResumesPageState();
}

class _SavedResumesPageState extends State<SavedResumesPage> {
  bool _loading = true;
  List<SavedResumeEntry> _entries = const [];

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final m = months[(dt.month - 1).clamp(0, 11)];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    return '${dt.day} $m ${dt.year}, $hour12:$minute $ampm';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final entries = await AiResumeStorage.loadAll();

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _rename(BuildContext context, SavedResumeEntry entry) async {
    final controller = TextEditingController(text: entry.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename resume'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final newTitle = result?.trim();
    if (newTitle == null || newTitle.isEmpty) return;

    await AiResumeStorage.rename(entry.id, newTitle);
    await _load();
  }

  Future<void> _delete(BuildContext context, SavedResumeEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete resume?'),
        content: Text('This will remove "${entry.title}" from saved history.'),
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
    );

    if (ok != true) return;

    await AiResumeStorage.delete(entry.id);
    await _load();
  }

  Future<void> _exportPdf(SavedResumeEntry entry) async {
    final doc = AiResumePdf.buildPdf(
      input: entry.input,
      result: entry.result,
      style: entry.style,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'resume.pdf',
    );
  }

  void _openPreview(SavedResumeEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SavedResumePreviewPage(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Resumes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No saved resumes yet. Generate a resume to save it here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.description_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  entry.style.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Saved: ${_formatDateTime(entry.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openPreview(entry),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('View'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _exportPdf(entry),
                                    icon: const Icon(Icons.picture_as_pdf_outlined),
                                    label: const Text('PDF'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _rename(context, entry),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Rename'),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _delete(context, entry),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _SavedResumePreviewPage extends StatelessWidget {
  final SavedResumeEntry entry;

  const _SavedResumePreviewPage({required this.entry});

  Future<void> _exportPdf() async {
    final doc = AiResumePdf.buildPdf(
      input: entry.input,
      result: entry.result,
      style: entry.style,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'resume.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: AiResumeFormattedPreview(resumeText: entry.result.resumeText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
