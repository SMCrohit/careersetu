import 'package:careersetu/features/jobs/domain/job_application.dart';
import 'package:careersetu/features/jobs/domain/job_filter_state.dart';
import 'package:careersetu/features/jobs/domain/job_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape returned by GET /api/jobs (taken from a real local record).
final _realJob = <String, dynamic>{
  'title': 'Marketing Specialist',
  'company_name': 'Innovate LLC',
  'job_type': 'Part-time',
  'work_model': 'Remote',
  'location': {'pincode': '400001', 'area': 'Fort', 'city': 'Mumbai', 'state': 'Maharashtra'},
  'description': 'We are looking for a highly motivated Marketing Specialist.',
  'status': 'published',
  'is_featured': true,
  'application_routing_mode': 'external_link',
  'employer_contact_email': null,
  'external_apply_url': 'https://example.com/apply',
  'company_website': null,
  'vacancies_count': 9,
  'shift_timing': null,
  'is_cover_letter_required': true,
  'screening_questions': ['Why do you want to work for our company?'],
  'salary_min': 800000,
  'salary_max': 1600000,
  'salary_type': 'Per Year',
  'currency': 'INR',
  'experience_required_years': 9.0,
  'education_required': 'B.Tech',
  'skills_required': ['React', 'Java'],
  'languages_required': ['English'],
  'id': 'f0b51c5e-30f4-42b0-8d2b-5d0c7d58e9f1',
  'created_datetime': '2026-09-23T00:00:00',
  'is_active': true,
  'deleted_datetime': null,
  'applicants_count': 1,
  'has_applied': false,
};

void main() {
  test('parses a real backend job', () {
    final job = JobModel.fromJson(_realJob);
    expect(job.companyName, 'Innovate LLC');
    expect(job.jobType, 'Part-time');
    expect(job.location.short, 'Fort, Mumbai');
    expect(job.location.full, 'Fort, Mumbai, Maharashtra - 400001');
    expect(job.salaryLabel, '₹8L – ₹16L / year');
    expect(job.experienceLabel, '9+ yrs');
    expect(job.isExternal, isTrue);
    expect(job.isFeatured, isTrue);
    expect(job.vacancies, 9);
    expect(job.shiftTiming, '');
    expect(job.initial, 'I');
  });

  test('survives missing, null and oddly typed fields', () {
    final job = JobModel.fromJson({
      'id': 'x',
      'title': null,
      'location': 'Pune',
      'salary_min': null,
      'salary_max': '45000',
      'salary_type': 'Per Month',
      'experience_required_years': 0,
      'skills_required': null,
      'created_datetime': 'not a date',
    });
    expect(job.title, 'Untitled job');
    expect(job.location.city, 'Pune');
    expect(job.salaryLabel, '₹45K / month');
    expect(job.experienceLabel, 'Fresher');
    expect(job.skills, isEmpty);
    expect(job.postedAgo, '');
    expect(job.routingMode, 'manual_review');
  });

  test('no salary reads as not disclosed', () {
    expect(JobModel.fromJson({'id': '1', 'title': 'A'}).salaryLabel, 'Not disclosed');
  });

  test('parses an application with its status track', () {
    final app = JobApplication.fromJson({
      'id': 'a1',
      'job_id': _realJob['id'],
      'status': 'Interview_Scheduled',
      'applied_datetime': '2026-10-01T10:00:00',
      'interview_datetime': null,
      'job': _realJob,
    });
    expect(app.job.hasApplied, isTrue);
    expect(app.isInterview, isTrue);
    expect(app.stage, 2);
    expect(app.statusLabel, 'Interview');
    expect(app.appliedAt, isNotNull);
  });

  test('application whose job was removed still parses', () {
    final app = JobApplication.fromJson({'id': 'a2', 'job_id': 'j', 'status': 'rejected', 'job': null});
    expect(app.job.title, 'Job no longer available');
    expect(app.isClosed, isTrue);
  });

  test('filters build the API query', () {
    const f = JobFilterState(type: 'Full-time', city: 'Pune', experience: '1-3 Years', minSalary: 300000, postedWithinDays: 7);
    expect(f.toQuery(), {
      'type': 'Full-time',
      'city': 'Pune',
      'experience': '1-3 Years',
      'min_salary': 300000,
      'posted_within_days': 7,
    });
    expect(f.activeCount, 5);
    expect(const JobFilterState(maxSalary: JobFilterState.salaryCap).toQuery(), isEmpty);
  });
}
