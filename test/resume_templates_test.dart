import 'package:careersetu/features/resume/domain/resume_draft.dart';
import 'package:careersetu/features/resume/presentation/screens/resume_pdf_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// A long resume that needs more than one A4 page in every template.
ResumeDraft _longDraft() => ResumeDraft(
      fullName: 'Rohit Pagare',
      email: 'rohit@example.com',
      phone: '9876543210',
      city: 'Pune',
      headline: 'Senior Flutter Developer',
      summary: 'Flutter developer with 6 years of experience building fintech and e-commerce apps. ' * 4,
      experience: List.generate(
        6,
        (i) => ExperienceEntry(
          title: 'Software Engineer ${i + 1}',
          company: 'Company $i',
          start: 'Jan 20${10 + i}',
          end: 'Dec 20${11 + i}',
          bullets: List.generate(5, (j) => 'Built and shipped feature $j that improved retention by ${j + 5}% across 2 lakh users.'),
        ),
      ),
      education: List.generate(3, (i) => EducationEntry(degree: 'Degree $i', school: 'University $i', start: '2010', end: '2014')),
      skills: List.generate(30, (i) => 'Skill $i'),
      projects: List.generate(5, (i) => ProjectEntry(title: 'Project $i', description: 'An app that does useful thing $i', bullets: ['Used Flutter and Firebase'])),
      certifications: [CertificationEntry(title: 'AWS Certified', organization: 'Amazon', year: '2022')],
      languages: ['English', 'Hindi', 'Marathi'],
    );

void main() {
  for (var i = 0; i < 10; i++) {
    test('template ${i + 1} renders a multi-page resume', () async {
      final bytes = await ResumePdfGenerator.generateResume(_longDraft(), null, i);
      expect(bytes, isNotEmpty);
    });
    test('template ${i + 1} renders an empty resume', () async {
      final bytes = await ResumePdfGenerator.generateResume(ResumeDraft(fullName: 'A'), null, i);
      expect(bytes, isNotEmpty);
    });
  }
}
