import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'ai_resume_models.dart';
import 'ai_resume_template_engine.dart';

class AiResumePdf {
  static pw.Document buildPdf({
    required ResumePromptInput input,
    required ResumeGenerationResult result,
    required ResumeStyle style,
  }) {
    final doc = pw.Document();
    final parsed = AiResumeTemplateEngine.parsePlainText(result.resumeText);

    String? inferredName;
    String? inferredContact;
    for (final section in parsed.sections) {
      final title = section.title.trim().toUpperCase();
      if (title == 'FULL NAME' && section.lines.isNotEmpty) {
        inferredName ??= section.lines.first.text.trim();
      }
      if (title == 'CONTACT' && section.lines.isNotEmpty) {
        // Prefer the first line; keep it as plain text.
        inferredContact ??= section.lines.first.text.trim();
      }
    }

    final sectionsToRender = parsed.sections.where((s) {
      final t = s.title.trim().toUpperCase();
      return t != 'FULL NAME' && t != 'CONTACT';
    }).toList();

    final accent = _accentColor(style);
    final spacing = _spacing(style);

    final titleStyle = pw.TextStyle(
      fontSize: style == ResumeStyle.compact ? 11 : 12,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: style == ResumeStyle.minimalist ? 0.2 : 0.6,
      color: style == ResumeStyle.classic || style == ResumeStyle.minimalist
          ? PdfColors.black
          : accent,
    );
    final bodyStyle = pw.TextStyle(
      fontSize: style == ResumeStyle.compact ? 10.5 : 11,
      height: style == ResumeStyle.compact ? 1.1 : 1.2,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          final nameInput = (input.fullName ?? '').trim();
          final name = nameInput.isNotEmpty ? nameInput : (inferredName ?? '').trim();
          final suburb = (input.suburb ?? '').trim();
          final phone = (input.phone ?? '').trim();
          final email = (input.email ?? '').trim();

          final contactParts = <String>[];
          if (suburb.isNotEmpty) contactParts.add(suburb);
          if (phone.isNotEmpty) contactParts.add(phone);
          if (email.isNotEmpty) contactParts.add(email);
            final contactLine = contactParts.isNotEmpty
              ? contactParts.join(' • ')
              : (inferredContact ?? '').trim();

          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    name.isNotEmpty ? name : 'Resume',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (style != ResumeStyle.minimalist &&
                    style != ResumeStyle.classic)
                  pw.Container(
                    width: 56,
                    height: 6,
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: spacing.headerGap),
            if (contactLine.isNotEmpty) ...[
              pw.Text(
                contactLine,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
            pw.SizedBox(height: spacing.afterHeader),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: spacing.afterDivider),
            for (final section in sectionsToRender) ...[
              pw.Text(section.title, style: titleStyle),
              pw.SizedBox(height: spacing.afterSectionTitle),
              for (final line in section.lines)
                pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: spacing.lineGap),
                  child: line.kind == ResumeTemplateLineKind.bullet
                      ? pw.Bullet(text: line.text, style: bodyStyle)
                      : pw.Text(line.text, style: bodyStyle),
                ),
              pw.SizedBox(height: spacing.afterSection),
            ],
          ];
        },
      ),
    );

    return doc;
  }

  static PdfColor _accentColor(ResumeStyle style) {
    switch (style) {
      case ResumeStyle.modern:
        return PdfColors.blueGrey800;
      case ResumeStyle.minimalist:
        return PdfColors.grey700;
      case ResumeStyle.corporate:
        return PdfColors.blue800;
      case ResumeStyle.creative:
        return PdfColors.purple700;
      case ResumeStyle.classic:
        return PdfColors.black;
      case ResumeStyle.compact:
        return PdfColors.blueGrey900;
    }
  }

  static _PdfSpacing _spacing(ResumeStyle style) {
    switch (style) {
      case ResumeStyle.compact:
        return const _PdfSpacing(
          headerGap: 6,
          afterHeader: 10,
          afterDivider: 10,
          afterSectionTitle: 4,
          lineGap: 2,
          afterSection: 8,
        );
      default:
        return const _PdfSpacing(
          headerGap: 8,
          afterHeader: 12,
          afterDivider: 12,
          afterSectionTitle: 6,
          lineGap: 3,
          afterSection: 10,
        );
    }
  }
}

class _PdfSpacing {
  final double headerGap;
  final double afterHeader;
  final double afterDivider;
  final double afterSectionTitle;
  final double lineGap;
  final double afterSection;

  const _PdfSpacing({
    required this.headerGap,
    required this.afterHeader,
    required this.afterDivider,
    required this.afterSectionTitle,
    required this.lineGap,
    required this.afterSection,
  });
}
