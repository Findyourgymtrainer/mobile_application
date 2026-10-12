import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import 'common.dart';
import 'member.dart';
import 'messages.dart';

// --------------------------------------------------------------- dashboard

class TrainerDashboardTab extends StatelessWidget {
  const TrainerDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.myTrainer!;
    final all = app.bookingsForTrainer(t.id);
    final requests = all.where((b) => b.effective == BookingStatus.pending).toList();
    final upcoming = all.where((b) => b.effective == BookingStatus.confirmed).toList();
    final past = all.where((b) => b.effective == BookingStatus.completed).toList().reversed.toList();
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      if (!t.approved)
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: const ListTile(
            leading: Icon(Icons.hourglass_top),
            title: Text('Waiting for admin approval'),
            subtitle: Text('Your profile is hidden from members until an admin approves it. Complete your trainer profile meanwhile.'),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          _Stat('Rating', app.ratingOf(t.id) == 0 ? '–' : app.ratingOf(t.id).toStringAsFixed(1), Icons.star_rounded),
          _Stat('Requests', '${requests.length}', Icons.inbox_outlined),
          _Stat('Upcoming', '${upcoming.length}', Icons.event_available),
          _Stat('Done', '${past.length}', Icons.check_circle_outline),
        ]),
      ),
      SectionTitle('Booking requests (${requests.length})'),
      if (requests.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No pending requests.'))),
      for (final b in requests) _RequestCard(b),
      SectionTitle('Upcoming sessions (${upcoming.length})'),
      if (upcoming.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Nothing scheduled yet.'))),
      for (final b in upcoming) _UpcomingCard(b),
      if (past.isNotEmpty) ...[
        const SectionTitle('Past sessions'),
        for (final b in past.take(5)) BookingCard(b, forMember: false),
      ],
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Stat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
          ]),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Booking booking;

  const _RequestCard(this.booking);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final b = booking;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(app.nameOf(b.memberId), radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.nameOf(b.memberId), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${fmtDate(b.start)} · ${fmtTime(b.start)}'),
              ]),
            ),
          ]),
          if (b.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('“${b.note}”')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => app.respond(b, false), child: const Text('Decline'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: () => app.respond(b, true), child: const Text('Accept'))),
          ]),
        ]),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final Booking booking;

  const _UpcomingCard(this.booking);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final b = booking;
    return Card(
      child: ListTile(
        leading: Avatar(app.nameOf(b.memberId), radius: 20),
        title: Text(app.nameOf(b.memberId), style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${fmtDate(b.start)} · ${fmtTime(b.start)} – ${fmtTime(b.end)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'cancel' && await confirm(context, 'Cancel session?', 'The member will be notified.', action: 'Cancel session')) {
              app.cancel(b);
            } else if (v == 'done') {
              app.markCompleted(b);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'done', child: Text('Mark completed')),
            PopupMenuItem(value: 'cancel', child: Text('Cancel session')),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ availability

class AvailabilityTab extends StatelessWidget {
  const AvailabilityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.myTrainer!;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      const SectionTitle('Weekly availability'),
      for (var d = 1; d <= 7; d++) _DayRow(t, d),
      SectionTitle(
        'Blocked dates',
        trailing: TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Block date'),
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) app.blockDate(t, d);
          },
        ),
      ),
      if (t.blockedDates.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('No blocked dates.', style: TextStyle(color: Theme.of(context).hintColor))),
      for (final k in t.blockedDates)
        ListTile(
          leading: const Icon(Icons.event_busy),
          title: Text(fmtDate(DateTime.parse(k))),
          trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => app.unblockDate(t, k)),
        ),
    ]);
  }
}

class _DayRow extends StatelessWidget {
  final Trainer trainer;
  final int weekday;

  const _DayRow(this.trainer, this.weekday);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final slot = trainer.availability.where((s) => s.weekday == weekday).firstOrNull;
    final enabled = slot != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: [
        Switch(value: enabled, onChanged: (v) => app.setWeekdayAvailability(trainer, weekday, enabled: v)),
        SizedBox(width: 44, child: Text(weekdayName(weekday), style: const TextStyle(fontWeight: FontWeight.w600))),
        const Spacer(),
        if (enabled) ...[
          _HourPicker(
            value: slot.startHour,
            hours: [for (var h = 0; h < slot.endHour; h++) h],
            onChanged: (h) => app.setWeekdayAvailability(trainer, weekday, start: h, end: slot.endHour),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('to')),
          _HourPicker(
            value: slot.endHour,
            hours: [for (var h = slot.startHour + 1; h <= 24; h++) h],
            onChanged: (h) => app.setWeekdayAvailability(trainer, weekday, start: slot.startHour, end: h),
          ),
        ] else
          Text('Unavailable', style: TextStyle(color: Theme.of(context).hintColor)),
        const SizedBox(width: 8),
      ]),
    );
  }
}

class _HourPicker extends StatelessWidget {
  final int value;
  final List<int> hours;
  final ValueChanged<int> onChanged;

  const _HourPicker({required this.value, required this.hours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      underline: const SizedBox.shrink(),
      items: [for (final h in hours) DropdownMenuItem(value: h, child: Text(fmtHour(h)))],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ----------------------------------------------------------------- clients

class ClientsTab extends StatelessWidget {
  const ClientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final clients = app.clientsOf(app.currentUserId!);
    if (clients.isEmpty) return const EmptyState(Icons.groups_outlined, 'No clients yet.\nMembers who book you will appear here.');
    return ListView(children: [
      const SizedBox(height: 8),
      for (final c in clients)
        Card(
          child: ListTile(
            leading: Avatar(c.name),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${app.workoutsOf(c.id).length} workouts logged'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientScreen(memberId: c.id))),
          ),
        ),
    ]);
  }
}

class ClientScreen extends StatelessWidget {
  final String memberId;

  const ClientScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final workouts = app.workoutsOf(memberId);
    return Scaffold(
      appBar: AppBar(title: Text(app.nameOf(memberId)), actions: [
        IconButton(
          tooltip: 'Message',
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherId: memberId))),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWorkoutDialog(context, memberId, assignedBy: app.user!.name),
        icon: const Icon(Icons.assignment_add),
        label: const Text('Assign workout'),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
        const SectionTitle('Last 7 days'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: VolumeChart(workouts)),
        const SectionTitle('Workout history'),
        if (workouts.isEmpty) const Padding(padding: EdgeInsets.all(32), child: EmptyState(Icons.fitness_center, 'No workouts yet.')),
        for (final w in workouts) WorkoutTile(w),
      ]),
    );
  }
}
