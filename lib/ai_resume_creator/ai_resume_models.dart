enum ResumeStyle {
  modern,
  minimalist,
  corporate,
  creative,
  classic,
  compact,
}

enum ResumeTone {
  professionalCorporate,
  hospitalityFriendly,
  retailFriendly,
  itTech,
  minimalistModern,
  studentFriendly,
}

enum ResumeBuildMode {
  createNew,
  improveExisting,
}

class ResumeExperienceEntry {
  final String jobTitle;
  final String company;
  final String dates;
  final String responsibilities;
  final String achievements;
  final String toolsUsed;
  final String metrics;

  const ResumeExperienceEntry({
    required this.jobTitle,
    required this.company,
    required this.dates,
    required this.responsibilities,
    required this.achievements,
    required this.toolsUsed,
    required this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'jobTitle': jobTitle,
      'company': company,
      'dates': dates,
      'responsibilities': responsibilities,
      'achievements': achievements,
      'toolsUsed': toolsUsed,
      'metrics': metrics,
    };
  }
}

class ResumePromptInput {
  final String prompt;

  // Optional contact details (for header and PDF export).
  final String? fullName;
  final String? phone;
  final String? email;
  final String? suburb;

  const ResumePromptInput({
    required this.prompt,
    this.fullName,
    this.phone,
    this.email,
    this.suburb,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'suburb': suburb,
    };
  }
}

class ResumeFormData {
  final String fullName;
  final String phone;
  final String email;
  final String suburb;

  final String careerGoal;
  final String summary;

  // Personal branding / positioning
  final String? strengths;
  final String? personalityTraits;
  final String? workStyle;
  final String? proudAchievements;

  // Job-specific targeting
  /// Optional: one of the app's job categories (e.g. Nepalese Restaurant, Grocery Store, Cleaning Job).
  final String? jobCategory;
  final String? targetJobTitle;
  final String? industry;
  final String? highlightSkills;
  final String? experienceLevel;

  /// Comma or newline separated.
  final String skills;

  /// Free-text; users can paste bullet points.
  final String workExperience;

  /// Optional structured experience entries (preferred when provided).
  final List<ResumeExperienceEntry>? experienceEntries;

  /// Optional: existing resume text (for Improve mode).
  final String? existingResumeText;

  /// Optional: required keywords (if extracted separately).
  final String? keywords;
  final String education;
  final String certifications;
  final String languages;
  final String availability;
  final String? visaStatus;

  /// Optional job description to tailor the resume.
  final String? targetJobDescription;

  const ResumeFormData({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.suburb,
    required this.careerGoal,
    required this.summary,
    this.strengths,
    this.personalityTraits,
    this.workStyle,
    this.proudAchievements,
    this.jobCategory,
    this.targetJobTitle,
    this.industry,
    this.highlightSkills,
    this.experienceLevel,
    required this.skills,
    required this.workExperience,
    this.experienceEntries,
    this.existingResumeText,
    this.keywords,
    required this.education,
    required this.certifications,
    required this.languages,
    required this.availability,
    this.visaStatus,
    this.targetJobDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'suburb': suburb,
      'careerGoal': careerGoal,
      'summary': summary,
      'strengths': strengths,
      'personalityTraits': personalityTraits,
      'workStyle': workStyle,
      'proudAchievements': proudAchievements,
      'jobCategory': jobCategory,
      'targetJobTitle': targetJobTitle,
      'industry': industry,
      'highlightSkills': highlightSkills,
      'experienceLevel': experienceLevel,
      'skills': skills,
      'workExperience': workExperience,
      'experienceEntries': experienceEntries?.map((e) => e.toJson()).toList(),
      'existingResumeText': existingResumeText,
      'keywords': keywords,
      'education': education,
      'certifications': certifications,
      'languages': languages,
      'availability': availability,
      'visaStatus': visaStatus,
      'targetJobDescription': targetJobDescription,
    };
  }
}

class ResumeGenerationResult {
  final String resumeText;
  final String source; // e.g. "api" or "local"

  const ResumeGenerationResult({
    required this.resumeText,
    required this.source,
  });
}
