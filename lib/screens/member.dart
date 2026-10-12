import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../seed.dart';
import 'common.dart';
import 'messages.dart';

// ---------------------------------------------------------------- home tab

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.user!;
    final upcoming = app.bookingsForMember(me.id).where((b) => b.isActive).toList();
    final top = (app.approvedTrainers..sort((a, b) => app.ratingOf(b.id).compareTo(app.ratingOf(a.id)))).take(6).toList();
    final favs = app.favouriteTrainers;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text('Hi, ${me.name.split(' ').first} 👋', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      ),
      const SectionTitle('Upcoming sessions'),
      if (upcoming.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No upcoming sessions. Find a trainer and book one!')))
      else
        for (final b in upcoming.take(3)) BookingCard(b, forMember: true),
      const SectionTitle('Top-rated trainers'),
      SizedBox(
        height: 170,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: top.length,
          itemBuilder: (_, i) => _FeaturedTrainer(top[i]),
        ),
      ),
      if (favs.isNotEmpty) ...[
        const SectionTitle('Your favourites'),
        for (final t in favs) TrainerCard(t),
      ],
    ]);
  }
}

class _FeaturedTrainer extends StatelessWidget {
  final Trainer trainer;

  const _FeaturedTrainer(this.trainer);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return SizedBox(
      width: 150,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainerId: trainer.id))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Avatar(trainer.name, radius: 28),
              const SizedBox(height: 8),
              Text(trainer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(trainer.specialties.take(1).join(), style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
              const SizedBox(height: 4),
              Stars(app.ratingOf(trainer.id), count: app.reviewsFor(trainer.id).length),
            ]),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ trainers tab

class _Filters {
  Set<String> specialties = {};
  String? location;
  String? gender;
  int maxPrice = 1500;
  double minRating = 0;

  int get count =>
      (specialties.isEmpty ? 0 : 1) + (location == null ? 0 : 1) + (gender == null ? 0 : 1) + (maxPrice < 1500 ? 1 : 0) + (minRating > 0 ? 1 : 0);
}

class TrainersTab extends StatefulWidget {
  const TrainersTab({super.key});

  @override
  State<TrainersTab> createState() => _TrainersTabState();
}

class _TrainersTabState extends State<TrainersTab> {
  final _filters = _Filters();
  String _query = '';

  Future<void> _openFilters() async {
    final f = _Filters()
      ..specialties = {..._filters.specialties}
      ..location = _filters.location
      ..gender = _filters.gender
      ..maxPrice = _filters.maxPrice
      ..minRating = _filters.minRating;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Filters', style: Theme.of(c).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => setSheet(() {
                    f
                      ..specialties = {}
                      ..location = null
                      ..gender = null
                      ..maxPrice = 1500
                      ..minRating = 0;
                  }),
                  child: const Text('Clear'),
                ),
              ]),
              const Text('Specialty'),
              Wrap(spacing: 8, children: [
                for (final s in kSpecialties)
                  FilterChip(
                    label: Text(s),
                    selected: f.specialties.contains(s),
                    onSelected: (v) => setSheet(() => v ? f.specialties.add(s) : f.specialties.remove(s)),
                  ),
              ]),
              const SizedBox(height: 12),
              const Text('Location'),
              Wrap(spacing: 8, children: [
                for (final l in kLocations)
                  ChoiceChip(label: Text(l), selected: f.location == l, onSelected: (v) => setSheet(() => f.location = v ? l : null)),
              ]),
              const SizedBox(height: 12),
              const Text('Gender'),
              Wrap(spacing: 8, children: [
                for (final g in kGenders)
                  ChoiceChip(label: Text(g), selected: f.gender == g, onSelected: (v) => setSheet(() => f.gender = v ? g : null)),
              ]),
              const SizedBox(height: 12),
              Text(f.maxPrice >= 1500 ? 'Max price: any' : 'Max price: ₹${f.maxPrice}/hr'),
              Slider(
                min: 500,
                max: 1500,
                divisions: 10,
                value: f.maxPrice.toDouble(),
                onChanged: (v) => setSheet(() => f.maxPrice = v.round()),
              ),
              const Text('Minimum rating'),
              Wrap(spacing: 8, children: [
                for (final r in [0.0, 3.0, 4.0, 4.5])
                  ChoiceChip(
                    label: Text(r == 0 ? 'Any' : '$r+'),
                    selected: f.minRating == r,
                    onSelected: (_) => setSheet(() => f.minRating = r),
                  ),
              ]),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Show results'))),
            ]),
          ),
        ),
      ),
    );
    if (apply == true) {
      setState(() {
        _filters
          ..specialties = f.specialties
          ..location = f.location
          ..gender = f.gender
          ..maxPrice = f.maxPrice
          ..minRating = f.minRating;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final q = _query.trim().toLowerCase();
    final results = app.approvedTrainers.where((t) {
      if (q.isNotEmpty && !t.name.toLowerCase().contains(q) && !t.specialties.any((s) => s.toLowerCase().contains(q))) return false;
      if (_filters.specialties.isNotEmpty && !t.specialties.any(_filters.specialties.contains)) return false;
      if (_filters.location != null && t.location != _filters.location) return false;
      if (_filters.gender != null && t.gender != _filters.gender) return false;
      if (_filters.maxPrice < 1500 && t.rate > _filters.maxPrice) return false;
      if (_filters.minRating > 0 && app.ratingOf(t.id) < _filters.minRating) return false;
      return true;
    }).toList()
      ..sort((a, b) => app.ratingOf(b.id).compareTo(app.ratingOf(a.id)));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Search by name or specialty', prefixIcon: Icon(Icons.search), isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Filters',
            onPressed: _openFilters,
            icon: Badge(isLabelVisible: _filters.count > 0, label: Text('${_filters.count}'), child: const Icon(Icons.tune)),
          ),
        ]),
      ),
      Expanded(
        child: results.isEmpty
            ? const EmptyState(Icons.search_off, 'No trainers match your search.\nTry removing some filters.')
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: results.length,
                itemBuilder: (_, i) => TrainerCard(results[i]),
              ),
      ),
    ]);
  }
}

class TrainerCard extends StatelessWidget {
  final Trainer trainer;

  const TrainerCard(this.trainer, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final fav = app.isFavourite(trainer.id);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainerId: trainer.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Avatar(trainer.name, radius: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trainer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(trainer.specialties.join(' · '), style: TextStyle(color: Theme.of(context).hintColor)),
                const SizedBox(height: 4),
                Row(children: [
                  Stars(app.ratingOf(trainer.id), count: app.reviewsFor(trainer.id).length),
                  const SizedBox(width: 10),
                  Icon(Icons.place_outlined, size: 14, color: Theme.of(context).hintColor),
                  Text(trainer.location, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                ]),
              ]),
            ),
            Column(children: [
              IconButton(
                tooltip: fav ? 'Remove favourite' : 'Add favourite',
                onPressed: () => app.toggleFavourite(trainer.id),
                icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.red : null),
              ),
              Text('₹${trainer.rate}/hr', style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = AppScope.of(context).favouriteTrainers;
    return Scaffold(
      appBar: AppBar(title: const Text('Favourite trainers')),
      body: favs.isEmpty
          ? const EmptyState(Icons.favorite_border, 'No favourites yet.\nTap the heart on a trainer to save them.')
          : ListView(children: [for (final t in favs) TrainerCard(t)]),
    );
  }
}

// ---------------------------------------------------------- trainer detail

class TrainerDetailScreen extends StatelessWidget {
  final String trainerId;

  const TrainerDetailScreen({super.key, required this.trainerId});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.trainerById(trainerId);
    if (t == null) return Scaffold(appBar: AppBar(), body: const EmptyState(Icons.error_outline, 'This trainer is no longer available.'));
    final reviews = app.reviewsFor(t.id);
    final isMember = app.user?.role == Role.member;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.name),
        actions: [
          if (isMember)
            IconButton(
              onPressed: () => app.toggleFavourite(t.id),
              icon: Icon(app.isFavourite(t.id) ? Icons.favorite : Icons.favorite_border, color: app.isFavourite(t.id) ? Colors.red : null),
            ),
        ],
      ),
      bottomNavigationBar: isMember
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherId: t.id))),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(trainerId: t.id))),
                      icon: const Icon(Icons.event_available),
                      label: Text('Book · ₹${t.rate}/hr'),
                    ),
                  ),
                ]),
              ),
            )
          : null,
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Avatar(t.name, radius: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Stars(app.ratingOf(t.id), count: reviews.length, size: 18),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.place_outlined, size: 16),
                Text(' ${t.location} · ${t.gender}'),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: [for (final s in t.specialties) Chip(label: Text(s))]),
        const SizedBox(height: 12),
        Text(t.bio),
        const SizedBox(height: 20),
        Text('Certifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        for (final c in t.certifications) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.verified_outlined), title: Text(c)),
        const SizedBox(height: 12),
        Text('Reviews (${reviews.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (reviews.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No reviews yet.')),
        for (final r in reviews)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Avatar(r.memberName, radius: 18),
            title: Row(children: [Text(r.memberName), const Spacer(), Stars(r.rating.toDouble(), size: 14)]),
            subtitle: r.comment.isEmpty ? null : Text(r.comment),
          ),
      ]),
    );
  }
}

// ----------------------------------------------------------------- booking

/// Pick a date and a free one-hour slot. Also used to reschedule a booking.
class BookingScreen extends StatefulWidget {
  final String trainerId;
  final Booking? reschedule;

  const BookingScreen({super.key, required this.trainerId, this.reschedule});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _day = DateTime.now();
  DateTime? _slot;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.trainerById(widget.trainerId)!;
    final today = DateTime.now();
    final days = [for (var i = 0; i < 14; i++) DateTime(today.year, today.month, today.day).add(Duration(days: i))];
    final slots = app.slotsFor(t, _day, ignoreBookingId: widget.reschedule?.id);
    final rescheduling = widget.reschedule != null;
    return Scaffold(
      appBar: AppBar(title: Text(rescheduling ? 'Reschedule session' : 'Book ${t.name}')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _slot == null
                ? null
                : () {
                    if (rescheduling) {
                      app.reschedule(widget.reschedule!, _slot!);
                    } else {
                      final err = app.requestBooking(t.id, _slot!, note: _note.text.trim());
                      if (err != null) {
                        showMsg(context, err);
                        return;
                      }
                    }
                    Navigator.pop(context);
                    showMsg(context, rescheduling ? 'Reschedule request sent' : 'Request sent – waiting for ${t.name} to confirm');
                  },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(_slot == null ? 'Select a time' : '${rescheduling ? 'Request new time' : 'Request session'} · ${fmtDate(_slot!)}, ${fmtTime(_slot!)}'),
            ),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Choose a date', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = days[i];
              final sel = dayKey(d) == dayKey(_day);
              final scheme = Theme.of(context).colorScheme;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _day = d;
                  _slot = null;
                }),
                child: Container(
                  width: 58,
                  decoration: BoxDecoration(
                    color: sel ? scheme.primary : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? scheme.primary : scheme.outlineVariant),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(weekdayName(d.weekday), style: TextStyle(color: sel ? scheme.onPrimary : null, fontSize: 12)),
                    Text('${d.day}', style: TextStyle(color: sel ? scheme.onPrimary : null, fontWeight: FontWeight.w800, fontSize: 18)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text('Available times', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (slots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(t.blockedDates.contains(dayKey(_day)) ? '${t.name} is unavailable on this date.' : 'No free slots on this day. Try another date.',
                style: TextStyle(color: Theme.of(context).hintColor)),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in slots) ChoiceChip(label: Text(fmtTime(s)), selected: _slot == s, onSelected: (_) => setState(() => _slot = s)),
          ]),
        if (!rescheduling) ...[
          const SizedBox(height: 20),
          TextField(controller: _note, maxLines: 2, decoration: const InputDecoration(labelText: 'Note for the trainer (optional)')),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------- member bookings

class MemberBookingsTab extends StatefulWidget {
  const MemberBookingsTab({super.key});

  @override
  State<MemberBookingsTab> createState() => _MemberBookingsTabState();
}

class _MemberBookingsTabState extends State<MemberBookingsTab> {
  bool _upcoming = true;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final all = app.bookingsForMember(app.currentUserId!);
    final list = _upcoming ? all.where((b) => b.isActive).toList() : (all.where((b) => !b.isActive).toList()..sort((a, b) => b.start.compareTo(a.start)));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SegmentedButton<bool>(
          segments: const [ButtonSegment(value: true, label: Text('Upcoming')), ButtonSegment(value: false, label: Text('Past'))],
          selected: {_upcoming},
          onSelectionChanged: (s) => setState(() => _upcoming = s.first),
        ),
      ),
      Expanded(
        child: list.isEmpty
            ? EmptyState(Icons.event_busy, _upcoming ? 'No upcoming sessions.' : 'No past sessions yet.')
            : ListView(children: [for (final b in list) BookingCard(b, forMember: true)]),
      ),
    ]);
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool forMember;

  const BookingCard(this.booking, {super.key, required this.forMember});

  Future<void> _review(BuildContext context) async {
    final app = AppScope.of(context);
    var stars = 5;
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: Text('Rate ${app.nameOf(booking.trainerId)}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setD(() => stars = i),
                  icon: Icon(i <= stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber.shade700, size: 32),
                ),
            ]),
            TextField(controller: text, maxLines: 3, decoration: const InputDecoration(labelText: 'Comment (optional)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (ok == true) app.addReview(booking, stars, text.text);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final b = booking;
    final status = b.effective;
    final otherId = forMember ? b.trainerId : b.memberId;
    final future = b.start.isAfter(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(app.nameOf(otherId), radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.nameOf(otherId), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${fmtDate(b.start)} · ${fmtTime(b.start)} – ${fmtTime(b.end)}'),
              ]),
            ),
            StatusChip(status),
          ]),
          if (b.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('“${b.note}”', style: TextStyle(color: Theme.of(context).hintColor))),
          if (forMember && (b.isActive && future || app.canReview(b)))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 8, children: [
                if (b.isActive && future) ...[
                  OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(trainerId: b.trainerId, reschedule: b))),
                    child: const Text('Reschedule'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      if (await confirm(context, 'Cancel session?', 'This will cancel your session with ${app.nameOf(b.trainerId)}.', action: 'Cancel session')) {
                        app.cancel(b);
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                ],
                if (app.canReview(b)) FilledButton(onPressed: () => _review(context), child: const Text('Leave review')),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- workouts

class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final list = app.workoutsOf(app.currentUserId!);
    final week = list.where((w) => w.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    final volume = week.fold<double>(0, (s, w) => s + w.volume);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWorkoutDialog(context, app.currentUserId!),
        icon: const Icon(Icons.add),
        label: const Text('Log workout'),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
        const SectionTitle('Last 7 days'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: VolumeChart(list)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('${week.length} exercises · ${volume.round()} kg total volume', style: TextStyle(color: Theme.of(context).hintColor)),
        ),
        const SectionTitle('History'),
        if (list.isEmpty) const Padding(padding: EdgeInsets.all(32), child: EmptyState(Icons.fitness_center, 'No workouts logged yet.')),
        for (final w in list) WorkoutTile(w, deletable: true),
      ]),
    );
  }
}

class WorkoutTile extends StatelessWidget {
  final Workout workout;
  final bool deletable;

  const WorkoutTile(this.workout, {super.key, this.deletable = false});

  @override
  Widget build(BuildContext context) {
    final w = workout;
    return Card(
      child: ListTile(
        title: Text(w.exercise, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${fmtDate(w.date)} · ${w.sets} × ${w.reps} @ ${w.weight % 1 == 0 ? w.weight.toInt() : w.weight} kg'
            '${w.assignedBy != null ? '\nAssigned by ${w.assignedBy}' : ''}'),
        isThreeLine: w.assignedBy != null,
        trailing: deletable
            ? IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => AppScope.of(context).deleteWorkout(w.id),
              )
            : null,
      ),
    );
  }
}

/// Shared by members logging their own workouts and trainers assigning plans.
Future<void> showWorkoutDialog(BuildContext context, String memberId, {String? assignedBy}) async {
  final app = AppScope.of(context);
  final exercise = TextEditingController();
  final sets = TextEditingController(text: '3');
  final reps = TextEditingController(text: '10');
  final weight = TextEditingController(text: '0');
  var date = DateTime.now();
  String? error;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setD) => AlertDialog(
        title: Text(assignedBy == null ? 'Log workout' : 'Assign workout'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: exercise, decoration: const InputDecoration(labelText: 'Exercise (e.g. Bench Press)')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: sets, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sets'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: reps, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kg'))),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(fmtDate(date)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: c,
                  initialDate: date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setD(() => date = d);
              },
            ),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: TextStyle(color: Theme.of(c).colorScheme.error))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (exercise.text.trim().isEmpty || (int.tryParse(sets.text) ?? 0) < 1 || (int.tryParse(reps.text) ?? 0) < 1) {
                setD(() => error = 'Enter an exercise name, sets and reps.');
                return;
              }
              Navigator.pop(c, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  if (ok == true) {
    app.addWorkout(memberId, date, exercise.text, int.parse(sets.text), int.parse(reps.text), double.tryParse(weight.text) ?? 0, assignedBy: assignedBy);
  }
}
