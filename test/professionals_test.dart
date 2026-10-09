import 'package:careersetu/features/appointments/domain/appointment_model.dart';
import 'package:careersetu/features/professionals/domain/availability.dart';
import 'package:careersetu/features/professionals/domain/professional_filter_state.dart';
import 'package:careersetu/features/professionals/domain/professional_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape returned by GET /api/professionals (from a real local record).
final _real = <String, dynamic>{
  'id': 'p1',
  'name': 'Dr. Meera Iyer',
  'profession': 'Doctor',
  'specialty': 'Cardiology',
  'qualification': 'MBBS, MD',
  'clinic': 'Heart Care',
  'location_city': 'Bangalore',
  'experience': '12 Years',
  'years_experience_numeric': 12,
  'consultation_fee': '2000',
  'image_url': 'https://ui-avatars.com/api/?name=Dr.+Meera+Iyer&background=random',
  'available_days': ['Mon', 'Tue', 'Wed', 'Thu'],
  'time_slots': ['08:00 PM', '12:00 PM', '04:00 PM', '02:00 PM'],
  'consultation_mode': ['In-Person', 'Phone'],
  'languages_spoken': ['English', 'Kannada'],
  'is_featured': true,
  'rating': 4.6,
  'reviews': 12,
  'next_available': {'date': '2026-10-12', 'weekday': 'Mon', 'time': '02:00 PM'},
};

void main() {
  test('parses a real professional', () {
    final p = Professional.fromJson(_real);
    expect(p.consultationFee, 2000, reason: 'fee arrives as a string from Numeric');
    expect(p.timeSlots, ['12:00 PM', '02:00 PM', '04:00 PM', '08:00 PM']);
    expect(p.photoUrl, isNull, reason: 'generated avatar URLs fall back to initials');
    expect(p.initials, 'MI', reason: '"Dr." is ignored');
    expect(p.daysLabel, 'Mon–Thu');
    expect(p.subtitle, 'Doctor · Cardiology');
    expect(p.isDoctor, isTrue);
    expect(p.nextAvailable!.weekday, 'Mon');
  });

  test('survives missing fields', () {
    final p = Professional.fromJson({'id': 'x', 'name': 'Asha', 'available_days': ['Mon', 'Wed', 'Fri']});
    expect(p.profession, 'Professional');
    expect(p.feeLabel, 'Free');
    expect(p.ratingLabel, 'New');
    expect(p.daysLabel, 'Mon, Wed, Fri', reason: 'non-consecutive days are listed');
    expect(p.nextAvailable, isNull);
    expect(p.initials, 'A');
  });

  test('availability parsing', () {
    final d = AvailableDate.fromJson({
      'date': '2026-10-12',
      'weekday': 'Mon',
      'slots': [
        {'time': '10:00 AM', 'status': 'past'},
        {'time': '02:00 PM', 'status': 'available'},
        {'time': '04:00 PM', 'status': 'full'},
        {'time': '06:00 PM', 'status': 'booked'},
      ],
    })!;
    expect(d.isoDate, '2026-10-12');
    expect(d.openCount, 1);
    expect(d.mineCount, 1, reason: "a slot the user already holds isn't open to them again");
    expect(d.slots.last.isMine, isTrue);
    expect(d.slots.last.isAvailable, isFalse);
    expect(AvailableDate.fromJson({'date': 'bad'}), isNull);
  });

  test('filters build the API query', () {
    const f = ProfessionalFilterState(city: 'Pune', consultationMode: 'Online', minFee: 200, experience: '5-10', minRating: 4.0, featuredOnly: true);
    expect(f.toQuery(), {'city': 'Pune', 'consultation_mode': 'Online', 'min_fee': 200, 'experience': '5-10', 'min_rating': 4.0, 'featured': true});
    expect(f.activeCount, 6);
    expect(f.copyWith(clearFee: true).hasFee, isFalse);
  });

  test('appointment status from the server', () {
    final a = Appointment.fromJson({
      'id': 'a1',
      'professional': _real,
      'appointment_date': '2026-10-12',
      'appointment_time': '02:00 PM',
      'status': 'sent_to_doctor',
      'display_status': 'confirmed',
      'consultation_mode': 'Online',
      'can_cancel': true,
    });
    expect(a.isUpcoming, isTrue);
    expect(a.statusLabel, 'Confirmed');
    expect(a.date, DateTime(2026, 10, 12));
    expect(a.canCancel, isTrue);
    expect(Appointment.fromJson({'id': 'b', 'status': 'cancelled', 'display_status': 'cancelled'}).isCancelled, isTrue);
    expect(Appointment.fromJson({'id': 'c', 'display_status': 'missed'}).isPast, isTrue);
  });
}
