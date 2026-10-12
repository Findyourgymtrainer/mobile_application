enum Role { member, trainer, admin }

enum BookingStatus { pending, confirmed, declined, cancelled, completed }

class AppUser {
  final String id;
  String name;
  String email;
  String password;
  String phone;
  Role role;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone = '',
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role.name,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        password: j['password'],
        phone: j['phone'] ?? '',
        role: Role.values.byName(j['role']),
      );
}

/// A recurring weekly availability window. [weekday] follows DateTime (1 = Monday).
class Slot {
  int weekday;
  int startHour;
  int endHour;

  Slot(this.weekday, this.startHour, this.endHour);

  Map<String, dynamic> toJson() => {'d': weekday, 's': startHour, 'e': endHour};

  factory Slot.fromJson(Map<String, dynamic> j) => Slot(j['d'], j['s'], j['e']);
}

class Trainer {
  final String id;
  String name;
  String bio;
  List<String> specialties;
  List<String> certifications;
  int rate;
  String location;
  String gender;
  bool approved;
  List<Slot> availability;
  List<String> blockedDates;

  Trainer({
    required this.id,
    required this.name,
    this.bio = '',
    List<String>? specialties,
    List<String>? certifications,
    this.rate = 500,
    this.location = 'Hyderabad',
    this.gender = 'Other',
    this.approved = true,
    List<Slot>? availability,
    List<String>? blockedDates,
  })  : specialties = specialties ?? [],
        certifications = certifications ?? [],
        availability = availability ?? [],
        blockedDates = blockedDates ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bio': bio,
        'specialties': specialties,
        'certifications': certifications,
        'rate': rate,
        'location': location,
        'gender': gender,
        'approved': approved,
        'availability': availability.map((s) => s.toJson()).toList(),
        'blockedDates': blockedDates,
      };

  factory Trainer.fromJson(Map<String, dynamic> j) => Trainer(
        id: j['id'],
        name: j['name'],
        bio: j['bio'],
        specialties: List<String>.from(j['specialties']),
        certifications: List<String>.from(j['certifications']),
        rate: j['rate'],
        location: j['location'],
        gender: j['gender'],
        approved: j['approved'],
        availability: (j['availability'] as List).map((e) => Slot.fromJson(e)).toList(),
        blockedDates: List<String>.from(j['blockedDates']),
      );
}

class Booking {
  final String id;
  final String memberId;
  final String trainerId;
  DateTime start;
  BookingStatus status;
  String note;

  Booking({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.start,
    this.status = BookingStatus.pending,
    this.note = '',
  });

  DateTime get end => start.add(const Duration(hours: 1));

  /// Status taking the clock into account: past confirmed sessions count as
  /// completed and past pending requests count as expired (cancelled).
  BookingStatus get effective {
    final now = DateTime.now();
    if (status == BookingStatus.confirmed && end.isBefore(now)) return BookingStatus.completed;
    if (status == BookingStatus.pending && start.isBefore(now)) return BookingStatus.cancelled;
    return status;
  }

  bool get isActive => effective == BookingStatus.pending || effective == BookingStatus.confirmed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'start': start.toIso8601String(),
        'status': status.name,
        'note': note,
      };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'],
        memberId: j['memberId'],
        trainerId: j['trainerId'],
        start: DateTime.parse(j['start']),
        status: BookingStatus.values.byName(j['status']),
        note: j['note'] ?? '',
      );
}

class Workout {
  final String id;
  final String memberId;
  DateTime date;
  String exercise;
  int sets;
  int reps;
  double weight;
  String? assignedBy;

  Workout({
    required this.id,
    required this.memberId,
    required this.date,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.weight,
    this.assignedBy,
  });

  double get volume => sets * reps * weight;

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'date': date.toIso8601String(),
        'exercise': exercise,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'assignedBy': assignedBy,
      };

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
        id: j['id'],
        memberId: j['memberId'],
        date: DateTime.parse(j['date']),
        exercise: j['exercise'],
        sets: j['sets'],
        reps: j['reps'],
        weight: (j['weight'] as num).toDouble(),
        assignedBy: j['assignedBy'],
      );
}

class Review {
  final String id;
  final String bookingId;
  final String memberId;
  final String memberName;
  final String trainerId;
  final int rating;
  final String comment;

  Review({
    required this.id,
    required this.bookingId,
    required this.memberId,
    required this.memberName,
    required this.trainerId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'memberId': memberId,
        'memberName': memberName,
        'trainerId': trainerId,
        'rating': rating,
        'comment': comment,
      };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'],
        bookingId: j['bookingId'],
        memberId: j['memberId'],
        memberName: j['memberName'],
        trainerId: j['trainerId'],
        rating: j['rating'],
        comment: j['comment'],
      );
}

class Message {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime sentAt;

  Message({required this.id, required this.fromId, required this.toId, required this.text, required this.sentAt});

  Map<String, dynamic> toJson() =>
      {'id': id, 'fromId': fromId, 'toId': toId, 'text': text, 'sentAt': sentAt.toIso8601String()};

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'],
        fromId: j['fromId'],
        toId: j['toId'],
        text: j['text'],
        sentAt: DateTime.parse(j['sentAt']),
      );
}

/// In-app notification (stands in for push notifications in this build).
class Notice {
  final String id;
  final String userId;
  final String text;
  final DateTime at;
  bool read;

  Notice({required this.id, required this.userId, required this.text, required this.at, this.read = false});

  Map<String, dynamic> toJson() => {'id': id, 'userId': userId, 'text': text, 'at': at.toIso8601String(), 'read': read};

  factory Notice.fromJson(Map<String, dynamic> j) =>
      Notice(id: j['id'], userId: j['userId'], text: j['text'], at: DateTime.parse(j['at']), read: j['read']);
}
