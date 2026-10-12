import 'models.dart';

const kSpecialties = [
  'Weight Loss',
  'Strength',
  'Bodybuilding',
  'Yoga',
  'HIIT',
  'Boxing',
  'CrossFit',
  'Nutrition',
  'Mobility',
];

const kLocations = ['Hyderabad', 'Bengaluru', 'Mumbai', 'Delhi', 'Chennai'];

const kGenders = ['Male', 'Female', 'Other'];

List<Slot> _week(int start, int end, {List<int> days = const [1, 2, 3, 4, 5, 6]}) =>
    [for (final d in days) Slot(d, start, end)];

List<Trainer> seedTrainers() => [
      Trainer(
        id: 't1',
        name: 'Arjun Reddy',
        bio: 'Former state-level powerlifter helping people build real strength with simple, progressive programs.',
        specialties: ['Strength', 'Bodybuilding'],
        certifications: ['ACE Certified Personal Trainer', 'CSCS'],
        rate: 900,
        location: 'Hyderabad',
        gender: 'Male',
        availability: _week(6, 12) + _week(17, 21, days: [1, 3, 5]),
      ),
      Trainer(
        id: 't2',
        name: 'Priya Sharma',
        bio: 'Yoga and mobility coach focused on posture, flexibility and pain-free movement for desk workers.',
        specialties: ['Yoga', 'Mobility'],
        certifications: ['RYT-500 Yoga Alliance', 'FMS Level 1'],
        rate: 700,
        location: 'Bengaluru',
        gender: 'Female',
        availability: _week(7, 13, days: [1, 2, 3, 4, 5, 6, 7]),
      ),
      Trainer(
        id: 't3',
        name: 'Rahul Verma',
        bio: 'HIIT and fat-loss specialist. Short, sweaty, effective sessions that fit around a busy day.',
        specialties: ['HIIT', 'Weight Loss'],
        certifications: ['NASM-CPT', 'Precision Nutrition L1'],
        rate: 800,
        location: 'Mumbai',
        gender: 'Male',
        availability: _week(5, 10) + _week(18, 22),
      ),
      Trainer(
        id: 't4',
        name: 'Sneha Iyer',
        bio: 'Certified nutrition coach and trainer. I build meal and training plans you can actually stick to.',
        specialties: ['Nutrition', 'Weight Loss'],
        certifications: ['ISSA Nutritionist', 'ACE-CPT'],
        rate: 850,
        location: 'Chennai',
        gender: 'Female',
        availability: _week(9, 18, days: [1, 2, 3, 4, 5]),
      ),
      Trainer(
        id: 't5',
        name: 'Karan Malhotra',
        bio: 'Amateur boxing champion teaching boxing fitness, footwork and conditioning for all levels.',
        specialties: ['Boxing', 'HIIT'],
        certifications: ['USA Boxing Coach', 'NSCA-CPT'],
        rate: 1000,
        location: 'Delhi',
        gender: 'Male',
        availability: _week(16, 21, days: [1, 2, 3, 4, 5, 6]),
      ),
      Trainer(
        id: 't6',
        name: 'Ananya Rao',
        bio: 'CrossFit Level 2 coach. Functional fitness, Olympic lifting basics and community-driven training.',
        specialties: ['CrossFit', 'Strength'],
        certifications: ['CrossFit L2', 'USAW Level 1'],
        rate: 950,
        location: 'Bengaluru',
        gender: 'Female',
        availability: _week(6, 11) + _week(16, 20, days: [2, 4, 6]),
      ),
      Trainer(
        id: 't7',
        name: 'Vikram Singh',
        bio: 'Bodybuilding prep and hypertrophy coach with 10 years of experience coaching natural athletes.',
        specialties: ['Bodybuilding', 'Nutrition'],
        certifications: ['IFBB Pro Coach', 'ACSM-CPT'],
        rate: 1200,
        location: 'Hyderabad',
        gender: 'Male',
        availability: _week(5, 9) + _week(19, 22),
      ),
      Trainer(
        id: 't8',
        name: 'Meera Nair',
        bio: 'Beginner-friendly weight loss trainer. Gentle progress, no crash diets, lots of encouragement.',
        specialties: ['Weight Loss', 'Yoga'],
        certifications: ['ACE-CPT', 'Group Fitness Instructor'],
        rate: 600,
        location: 'Mumbai',
        gender: 'Female',
        availability: _week(8, 14, days: [1, 2, 3, 4, 5, 6, 7]),
      ),
      // Linked to the trainer@demo.com account.
      Trainer(
        id: 'tdemo',
        name: 'Demo Trainer',
        bio: 'Demo trainer account – log in as trainer@demo.com to manage requests and availability.',
        specialties: ['Strength', 'HIIT'],
        certifications: ['Demo Certified Trainer'],
        rate: 500,
        location: 'Hyderabad',
        gender: 'Other',
        availability: _week(9, 17),
      ),
    ];

List<AppUser> seedUsers() => [
      AppUser(id: 'm1', name: 'Demo Member', email: 'member@demo.com', password: 'demo123', phone: '9000000001', role: Role.member),
      AppUser(id: 'tdemo', name: 'Demo Trainer', email: 'trainer@demo.com', password: 'demo123', phone: '9000000002', role: Role.trainer),
      AppUser(id: 'a1', name: 'Demo Admin', email: 'admin@demo.com', password: 'demo123', phone: '9000000003', role: Role.admin),
    ];

List<Review> seedReviews() {
  Review r(String id, String t, String who, int stars, String text) =>
      Review(id: id, bookingId: 'seed-$id', memberId: 'seed-$who', memberName: who, trainerId: t, rating: stars, comment: text);
  return [
    r('r1', 't1', 'Rohit', 5, 'Added 20 kg to my squat in two months. Clear coaching.'),
    r('r2', 't1', 'Divya', 4, 'Very knowledgeable, sessions are tough but fair.'),
    r('r3', 't2', 'Neha', 5, 'My back pain is almost gone. Wonderful teacher.'),
    r('r4', 't2', 'Sameer', 5, 'Calm, patient and very detailed with corrections.'),
    r('r5', 't3', 'Imran', 4, 'Great energy, lost 6 kg in 10 weeks.'),
    r('r6', 't4', 'Kavya', 5, 'The meal plan was realistic and easy to follow.'),
    r('r7', 't5', 'Arun', 5, 'Best boxing workouts I have done.'),
    r('r8', 't5', 'Pooja', 4, 'Pushes you hard but keeps it fun.'),
    r('r9', 't6', 'Nikhil', 4, 'Great programming and community feel.'),
    r('r10', 't7', 'Farhan', 5, 'Got me stage-ready. Top-class coach.'),
    r('r11', 't8', 'Lakshmi', 5, 'Perfect for beginners. So encouraging!'),
    r('r12', 't8', 'Anil', 4, 'Friendly and flexible with timings.'),
  ];
}
