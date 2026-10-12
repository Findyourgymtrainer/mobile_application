import 'package:flutter_test/flutter_test.dart';
import 'package:gym_trainer/app_state.dart';
import 'package:gym_trainer/main.dart';
import 'package:gym_trainer/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _freshState() async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  await state.load();
  return state;
}

void main() {
  test('login rejects wrong password and accepts demo account', () async {
    final app = await _freshState();
    expect(app.login('member@demo.com', 'wrong'), isNotNull);
    expect(app.login('member@demo.com', 'demo123'), isNull);
    expect(app.user!.role, Role.member);
  });

  test('new trainers need admin approval before they are listed', () async {
    final app = await _freshState();
    app.signUp(name: 'New Coach', email: 'coach@test.com', password: 'secret1', role: Role.trainer);
    final id = app.currentUserId!;
    expect(app.approvedTrainers.any((t) => t.id == id), isFalse);
    app.setApproval(id, true);
    expect(app.approvedTrainers.any((t) => t.id == id), isTrue);
  });

  test('booking flow: request, accept, no double booking of a slot', () async {
    final app = await _freshState();
    app.login('member@demo.com', 'demo123');
    final trainer = app.trainerById('tdemo')!;
    var day = DateTime.now().add(const Duration(days: 1));
    while (app.slotsFor(trainer, day).isEmpty) {
      day = day.add(const Duration(days: 1));
    }
    final slot = app.slotsFor(trainer, day).first;
    expect(app.requestBooking(trainer.id, slot), isNull);
    expect(app.slotsFor(trainer, day).contains(slot), isFalse);
    final booking = app.bookings.last;
    app.respond(booking, true);
    expect(booking.status, BookingStatus.confirmed);
  });

  test('ratings are averaged from reviews', () async {
    final app = await _freshState();
    expect(app.ratingOf('t1'), 4.5);
  });

  test('deleting an account removes its data', () async {
    final app = await _freshState();
    app.login('member@demo.com', 'demo123');
    app.deleteAccount();
    expect(app.userById('m1'), isNull);
    expect(app.workouts.where((w) => w.memberId == 'm1'), isEmpty);
  });

  testWidgets('app shows onboarding, then login, then member home', (tester) async {
    final app = await _freshState();
    await tester.pumpWidget(GymApp(state: app));
    expect(find.text('Find the right trainer'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Find Your Gym Trainer'), findsOneWidget);

    await tester.ensureVisible(find.text('Member'));
    await tester.tap(find.text('Member'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hi, Demo'), findsOneWidget);
    expect(find.text('Trainers'), findsWidgets);
  });
}
