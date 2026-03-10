import 'package:flutter/material.dart';

import 'ai_resume_models.dart';

class ResumeTemplateInfo {
  final ResumeStyle style;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool atsFriendly;

  const ResumeTemplateInfo({
    required this.style,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.atsFriendly,
  });
}

class AiResumeTemplates {
  static const templates = <ResumeTemplateInfo>[
    ResumeTemplateInfo(
      style: ResumeStyle.modern,
      title: 'Modern',
      subtitle: 'Clean headings, subtle accent, balanced spacing',
      icon: Icons.auto_awesome,
      atsFriendly: true,
    ),
    ResumeTemplateInfo(
      style: ResumeStyle.minimalist,
      title: 'Minimal',
      subtitle: 'Plain and compact (best for strict ATS parsing)',
      icon: Icons.subject,
      atsFriendly: true,
    ),
    ResumeTemplateInfo(
      style: ResumeStyle.corporate,
      title: 'Corporate',
      subtitle: 'Stronger section headers and classic business look',
      icon: Icons.business_center_outlined,
      atsFriendly: true,
    ),
    ResumeTemplateInfo(
      style: ResumeStyle.creative,
      title: 'Creative',
      subtitle: 'More color accents (still ATS-friendly)',
      icon: Icons.palette_outlined,
      atsFriendly: true,
    ),
    ResumeTemplateInfo(
      style: ResumeStyle.classic,
      title: 'Classic',
      subtitle: 'Traditional black-and-white resume styling',
      icon: Icons.description_outlined,
      atsFriendly: true,
    ),
    ResumeTemplateInfo(
      style: ResumeStyle.compact,
      title: 'Compact',
      subtitle: 'Tighter spacing to fit more on one page',
      icon: Icons.compress,
      atsFriendly: true,
    ),
  ];

  static ResumeTemplateInfo info(ResumeStyle style) {
    for (final t in templates) {
      if (t.style == style) return t;
    }
    return templates.first;
  }

  static String displayName(ResumeStyle style) => info(style).title;
}
