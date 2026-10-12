import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'seed.dart';

/// Demo OTP accepted by the simulated phone sign-in.
const kDemoOtp = '123456';

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// All app data, kept in memory and persisted as JSON in local storage.
/// There is no backend yet – this layer is what a real API would replace.
class AppState extends ChangeNotifier {
  static const _storeKey = 'gym_trainer_state_v1';

  List<AppUser> users = [];
  List<Trainer> trainers = [];
  List<Booking> bookings = [];
  List<Review> reviews = [];
  List<Workout> workouts = [];
  List<Message> messages = [];
  List<Notice> notices = [];
  Map<String, List<String>> favourites = {};
  String? currentUserId;
  ThemeMode themeMode = ThemeMode.system;
  bool onboarded = false;

  SharedPreferences? _prefs;
  int _idCounter = 0;

  String _id() => '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  // ---------------------------------------------------------------- storage

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storeKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
            (j[k] as List).map((e) => f(e as Map<String, dynamic>)).toList();
        users = list('users', AppUser.fromJson);
        trainers = list('trainers', Trainer.fromJson);
        bookings = list('bookings', Booking.fromJson);
        reviews = list('reviews', Review.fromJson);
        workouts = list('workouts', Workout.fromJson);
        messages = list('messages', Message.fromJson);
        notices = list('notices', Notice.fromJson);
        favourites = (j['favourites'] as Map<String, dynamic>).map((k, v) => MapEntry(k, List<String>.from(v)));
        currentUserId = j['currentUserId'];
        themeMode = ThemeMode.values[j['themeMode'] ?? 0];
        onboarded = j['onboarded'] ?? false;
        return;
      } catch (_) {
        // Corrupted or incompatible data – fall back to a fresh seed.
      }
    }
    _seed();
  }

  void _seed() {
    users = seedUsers();
    trainers = seedTrainers();
    reviews = seedReviews();
    bookings = [
      // A session in the past so the demo member can leave a review.
      Booking(
        id: 'b-seed',
        memberId: 'm1',
        trainerId: 't1',
        start: DateTime.now().subtract(const Duration(days: 3)).copyWith(hour: 7, minute: 0, second: 0, millisecond: 0, microsecond: 0),
        status: BookingStatus.confirmed,
        note: 'Leg day',
      ),
    ];
    final today = DateTime.now();
    workouts = [
      for (var i = 0; i < 5; i++)
        Workout(
          id: 'w-seed$i',
          memberId: 'm1',
          date: today.subtract(Duration(days: i)),
          exercise: ['Squat', 'Bench Press', 'Deadlift', 'Overhead Press', 'Barbell Row'][i],
          sets: 4,
          reps: 8,
          weight: [60, 40, 80, 30, 45][i].toDouble(),
        ),
    ];
    messages = [];
    notices = [];
    favourites = {};
    currentUserId = null;
    onboarded = false;
    _changed();
  }

  void _changed() {
    notifyListeners();
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(
      _storeKey,
      jsonEncode({
        'users': users.map((e) => e.toJson()).toList(),
        'trainers': trainers.map((e) => e.toJson()).toList(),
        'bookings': bookings.map((e) => e.toJson()).toList(),
        'reviews': reviews.map((e) => e.toJson()).toList(),
        'workouts': workouts.map((e) => e.toJson()).toList(),
        'messages': messages.map((e) => e.toJson()).toList(),
        'notices': notices.map((e) => e.toJson()).toList(),
        'favourites': favourites,
        'currentUserId': currentUserId,
        'themeMode': themeMode.index,
        'onboarded': onboarded,
      }),
    );
  }

  /// Wipes all local data and restores the demo data.
  void resetDemoData() => _seed();

  // --------------------------------------------------------------- settings

  void completeOnboarding() {
    onboarded = true;
    _changed();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _changed();
  }

  // ------------------------------------------------------------------- auth

  AppUser? get user => users.where((u) => u.id == currentUserId).firstOrNull;

  AppUser? userById(String id) => users.where((u) => u.id == id).firstOrNull;

  Trainer? trainerById(String id) => trainers.where((t) => t.id == id).firstOrNull;

  Trainer? get myTrainer => currentUserId == null ? null : trainerById(currentUserId!);

  String nameOf(String id) => userById(id)?.name ?? trainerById(id)?.name ?? 'Unknown';

  /// Returns an error message, or null on success.
  String? login(String email, String password) {
    final u = users.where((u) => u.email.toLowerCase() == email.trim().toLowerCase()).firstOrNull;
    if (u == null || u.password != password) return 'Incorrect email or password.';
    currentUserId = u.id;
    _changed();
    return null;
  }

  String? signUp({
    required String name,
    required String email,
    required String password,
    String phone = '',
    required Role role,
  }) {
    if (users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return 'An account with this email already exists.';
    }
    final u = AppUser(id: _id(), name: name.trim(), email: email.trim(), password: password, phone: phone.trim(), role: role);
    users.add(u);
    if (role == Role.trainer) {
      // New trainers stay hidden until an admin approves them.
      trainers.add(Trainer(id: u.id, name: u.name, approved: false, bio: 'Tell members about yourself.'));
      for (final a in users.where((x) => x.role == Role.admin)) {
        _notify(a.id, '${u.name} signed up as a trainer and needs approval.');
      }
    }
    currentUserId = u.id;
    _changed();
    return null;
  }

  /// Simulated phone sign-in. The OTP is always [kDemoOtp].
  String? phoneLogin(String phone, String otp, {String name = ''}) {
    if (otp != kDemoOtp) return 'Invalid OTP. Use $kDemoOtp in this demo.';
    final p = phone.trim();
    if (p.length < 10) return 'Enter a valid 10-digit phone number.';
    var u = users.where((u) => u.phone == p).firstOrNull;
    u ??= () {
      final created = AppUser(
          id: _id(), name: name.trim().isEmpty ? 'Member $p' : name.trim(), email: '$p@phone.local', password: '', phone: p, role: Role.member);
      users.add(created);
      return created;
    }();
    currentUserId = u.id;
    _changed();
    return null;
  }

  /// Simulated Google sign-in (no real OAuth in this build).
  void googleLogin() {
    var u = users.where((u) => u.email == 'google.user@gmail.com').firstOrNull;
    u ??= () {
      final created = AppUser(id: _id(), name: 'Google User', email: 'google.user@gmail.com', password: '', role: Role.member);
      users.add(created);
      return created;
    }();
    currentUserId = u.id;
    _changed();
  }

  String? resetPassword(String email, String newPassword) {
    final u = users.where((u) => u.email.toLowerCase() == email.trim().toLowerCase()).firstOrNull;
    if (u == null) return 'No account found for that email.';
    if (newPassword.length < 6) return 'Password must be at least 6 characters.';
    u.password = newPassword;
    _changed();
    return null;
  }

  void logout() {
    currentUserId = null;
    _changed();
  }

  /// Removes the account and all of its data (privacy requirement).
  void deleteAccount() {
    final id = currentUserId;
    if (id == null) return;
    users.removeWhere((u) => u.id == id);
    trainers.removeWhere((t) => t.id == id);
    bookings.removeWhere((b) => b.memberId == id || b.trainerId == id);
    reviews.removeWhere((r) => r.memberId == id || r.trainerId == id);
    workouts.removeWhere((w) => w.memberId == id);
    messages.removeWhere((m) => m.fromId == id || m.toId == id);
    notices.removeWhere((n) => n.userId == id);
    favourites.remove(id);
    currentUserId = null;
    _changed();
  }

  void updateProfile({String? name, String? phone}) {
    final u = user;
    if (u == null) return;
    if (name != null && name.trim().isNotEmpty) {
      u.name = name.trim();
      myTrainer?.name = u.name;
    }
    if (phone != null) u.phone = phone.trim();
    _changed();
  }

  // --------------------------------------------------------------- trainers

  List<Trainer> get approvedTrainers => trainers.where((t) => t.approved).toList();

  List<Review> reviewsFor(String trainerId) => reviews.where((r) => r.trainerId == trainerId).toList();

  double ratingOf(String trainerId) {
    final rs = reviewsFor(trainerId);
    if (rs.isEmpty) return 0;
    return rs.fold<int>(0, (s, r) => s + r.rating) / rs.length;
  }

  bool isFavourite(String trainerId) => favourites[currentUserId]?.contains(trainerId) ?? false;

  void toggleFavourite(String trainerId) {
    final list = favourites.putIfAbsent(currentUserId!, () => []);
    list.contains(trainerId) ? list.remove(trainerId) : list.add(trainerId);
    _changed();
  }

  List<Trainer> get favouriteTrainers =>
      approvedTrainers.where((t) => isFavourite(t.id)).toList();

  void saveTrainerProfile(Trainer t) => _changed();

  void setApproval(String trainerId, bool approved) {
    final t = trainerById(trainerId);
    if (t == null) return;
    if (approved) {
      t.approved = true;
      _notify(t.id, 'Your trainer profile was approved. Members can now find and book you.');
    } else {
      // Rejecting removes the trainer account entirely.
      users.removeWhere((u) => u.id == trainerId);
      trainers.removeWhere((x) => x.id == trainerId);
      bookings.removeWhere((b) => b.trainerId == trainerId);
    }
    _changed();
  }

  void deleteReview(String reviewId) {
    reviews.removeWhere((r) => r.id == reviewId);
    _changed();
  }

  // ----------------------------------------------------------- availability

  /// Free one-hour start times for [trainer] on [day].
  List<DateTime> slotsFor(Trainer trainer, DateTime day, {String? ignoreBookingId}) {
    if (trainer.blockedDates.contains(dayKey(day))) return [];
    final now = DateTime.now();
    final taken = bookings
        .where((b) => b.trainerId == trainer.id && b.isActive && b.id != ignoreBookingId)
        .map((b) => b.start)
        .toSet();
    final out = <DateTime>[];
    for (final s in trainer.availability.where((s) => s.weekday == day.weekday)) {
      for (var h = s.startHour; h < s.endHour; h++) {
        final start = DateTime(day.year, day.month, day.day, h);
        if (start.isAfter(now) && !taken.contains(start)) out.add(start);
      }
    }
    out.sort();
    return out;
  }

  void setWeekdayAvailability(Trainer t, int weekday, {int? start, int? end, bool enabled = true}) {
    t.availability.removeWhere((s) => s.weekday == weekday);
    if (enabled) t.availability.add(Slot(weekday, start ?? 9, end ?? 17));
    _changed();
  }

  void blockDate(Trainer t, DateTime d) {
    final k = dayKey(d);
    if (!t.blockedDates.contains(k)) t.blockedDates.add(k);
    t.blockedDates.sort();
    _changed();
  }

  void unblockDate(Trainer t, String key) {
    t.blockedDates.remove(key);
    _changed();
  }

  // --------------------------------------------------------------- bookings

  List<Booking> bookingsForMember(String memberId) =>
      bookings.where((b) => b.memberId == memberId).toList()..sort((a, b) => a.start.compareTo(b.start));

  List<Booking> bookingsForTrainer(String trainerId) =>
      bookings.where((b) => b.trainerId == trainerId).toList()..sort((a, b) => a.start.compareTo(b.start));

  /// Returns an error message, or null on success.
  String? requestBooking(String trainerId, DateTime start, {String note = ''}) {
    final me = currentUserId!;
    if (bookings.any((b) => b.memberId == me && b.isActive && b.start == start)) {
      return 'You already have a session at that time.';
    }
    final b = Booking(id: _id(), memberId: me, trainerId: trainerId, start: start, note: note);
    bookings.add(b);
    _notify(trainerId, '${nameOf(me)} requested a session on ${_stamp(start)}.');
    _notify(me, 'Booking request sent to ${nameOf(trainerId)} for ${_stamp(start)}.');
    _changed();
    return null;
  }

  void reschedule(Booking b, DateTime newStart) {
    b.start = newStart;
    b.status = BookingStatus.pending;
    _notify(b.trainerId, '${nameOf(b.memberId)} asked to move their session to ${_stamp(newStart)}.');
    _notify(b.memberId, 'Reschedule request sent to ${nameOf(b.trainerId)} for ${_stamp(newStart)}.');
    _changed();
  }

  void cancel(Booking b) {
    final byMember = currentUserId == b.memberId;
    b.status = BookingStatus.cancelled;
    _notify(byMember ? b.trainerId : b.memberId, '${nameOf(currentUserId!)} cancelled the session on ${_stamp(b.start)}.');
    _changed();
  }

  void respond(Booking b, bool accept) {
    b.status = accept ? BookingStatus.confirmed : BookingStatus.declined;
    _notify(b.memberId, '${nameOf(b.trainerId)} ${accept ? 'confirmed' : 'declined'} your session on ${_stamp(b.start)}.');
    _changed();
  }

  void markCompleted(Booking b) {
    b.status = BookingStatus.completed;
    _notify(b.memberId, 'Your session with ${nameOf(b.trainerId)} is complete. Leave a review!');
    _changed();
  }

  bool hasReview(String bookingId) => reviews.any((r) => r.bookingId == bookingId);

  bool canReview(Booking b) =>
      b.memberId == currentUserId && b.effective == BookingStatus.completed && !hasReview(b.id);

  void addReview(Booking b, int rating, String comment) {
    reviews.add(Review(
      id: _id(),
      bookingId: b.id,
      memberId: b.memberId,
      memberName: nameOf(b.memberId),
      trainerId: b.trainerId,
      rating: rating,
      comment: comment.trim(),
    ));
    _notify(b.trainerId, '${nameOf(b.memberId)} left you a $rating-star review.');
    _changed();
  }

  /// Members the trainer has (or had) an active relationship with.
  List<AppUser> clientsOf(String trainerId) {
    final ids = bookings
        .where((b) => b.trainerId == trainerId && b.effective != BookingStatus.declined && b.effective != BookingStatus.cancelled)
        .map((b) => b.memberId)
        .toSet();
    return ids.map(userById).whereType<AppUser>().toList();
  }

  // --------------------------------------------------------------- workouts

  List<Workout> workoutsOf(String memberId) =>
      workouts.where((w) => w.memberId == memberId).toList()..sort((a, b) => b.date.compareTo(a.date));

  void addWorkout(String memberId, DateTime date, String exercise, int sets, int reps, double weight, {String? assignedBy}) {
    workouts.add(Workout(
      id: _id(),
      memberId: memberId,
      date: date,
      exercise: exercise.trim(),
      sets: sets,
      reps: reps,
      weight: weight,
      assignedBy: assignedBy,
    ));
    if (assignedBy != null) {
      _notify(memberId, '$assignedBy assigned you a workout: ${exercise.trim()}.');
    }
    _changed();
  }

  void deleteWorkout(String id) {
    workouts.removeWhere((w) => w.id == id);
    _changed();
  }

  // --------------------------------------------------------------- messages

  List<Message> thread(String a, String b) => messages
      .where((m) => (m.fromId == a && m.toId == b) || (m.fromId == b && m.toId == a))
      .toList()
    ..sort((x, y) => x.sentAt.compareTo(y.sentAt));

  /// Ids of everyone the current user has exchanged messages with, newest first.
  List<String> conversationPartners() {
    final me = currentUserId!;
    final latest = <String, DateTime>{};
    for (final m in messages) {
      if (m.fromId != me && m.toId != me) continue;
      final other = m.fromId == me ? m.toId : m.fromId;
      if (latest[other] == null || m.sentAt.isAfter(latest[other]!)) latest[other] = m.sentAt;
    }
    return latest.keys.toList()..sort((a, b) => latest[b]!.compareTo(latest[a]!));
  }

  void sendMessage(String toId, String text) {
    final me = currentUserId!;
    messages.add(Message(id: _id(), fromId: me, toId: toId, text: text.trim(), sentAt: DateTime.now()));
    _notify(toId, 'New message from ${nameOf(me)}.');
    _changed();
    // Seeded trainers have no real person behind them, so answer automatically.
    if (RegExp(r'^t\d$').hasMatch(toId)) {
      Timer(const Duration(seconds: 1), () {
        messages.add(Message(
          id: _id(),
          fromId: toId,
          toId: me,
          text: 'Thanks for reaching out! I will check my calendar – feel free to book a slot from my profile.',
          sentAt: DateTime.now(),
        ));
        _changed();
      });
    }
  }

  // ---------------------------------------------------------- notifications

  List<Notice> get myNotices =>
      notices.where((n) => n.userId == currentUserId).toList()..sort((a, b) => b.at.compareTo(a.at));

  int get unreadCount => myNotices.where((n) => !n.read).length;

  void markNoticesRead() {
    var any = false;
    for (final n in notices.where((n) => n.userId == currentUserId && !n.read)) {
      n.read = true;
      any = true;
    }
    if (any) _changed();
  }

  void _notify(String userId, String text) {
    notices.add(Notice(id: _id(), userId: userId, text: text, at: DateTime.now()));
  }

  String _stamp(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${d.day} ${m[d.month - 1]}, $h ${d.hour < 12 ? 'AM' : 'PM'}';
  }
}
