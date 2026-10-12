import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String fmtDate(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

String fmtHour(int hour) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h ${hour < 12 || hour == 24 ? 'AM' : 'PM'}';
}

String fmtTime(DateTime d) => fmtHour(d.hour);

String weekdayName(int weekday) => _days[weekday - 1];

void showMsg(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> confirm(BuildContext context, String title, String body, {String action = 'Yes'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
      ],
    ),
  );
  return r ?? false;
}

class Avatar extends StatelessWidget {
  final String name;
  final double radius;

  const Avatar(this.name, {super.key, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    final hue = (name.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = HSLColor.fromAHSL(1, hue.toDouble(), 0.45, dark ? 0.30 : 0.82).toColor();
    final fg = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, dark ? 0.85 : 0.25).toColor();
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(initials, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: radius * 0.75)),
    );
  }
}

class Stars extends StatelessWidget {
  final double rating;
  final int? count;
  final double size;

  const Stars(this.rating, {super.key, this.count, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.star_rounded, size: size, color: Colors.amber.shade700),
      const SizedBox(width: 2),
      Text(rating == 0 ? 'New' : rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
      if (count != null) Text(' ($count)', style: TextStyle(color: Theme.of(context).hintColor)),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const EmptyState(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
        ]),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        ?trailing,
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  final BookingStatus status;

  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BookingStatus.pending => ('Pending', Colors.orange),
      BookingStatus.confirmed => ('Confirmed', Colors.green),
      BookingStatus.declined => ('Declined', Colors.red),
      BookingStatus.cancelled => ('Cancelled', Colors.grey),
      BookingStatus.completed => ('Completed', Colors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color.shade700Safe, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

extension on Color {
  Color get shade700Safe => HSLColor.fromColor(this).withLightness(0.35).toColor();
}

/// Weekly volume bar chart for the last 7 days.
class VolumeChart extends StatelessWidget {
  final List<Workout> workouts;

  const VolumeChart(this.workouts, {super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day).subtract(Duration(days: i))];
    final totals = [
      for (final d in days) workouts.where((w) => dayKey(w.date) == dayKey(d)).fold<double>(0, (s, w) => s + w.volume),
    ];
    final maxV = totals.fold<double>(0, (a, b) => b > a ? b : a);
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(totals[i] == 0 ? '' : totals[i].round().toString(), style: const TextStyle(fontSize: 10)),
                const SizedBox(height: 2),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: maxV == 0 ? 3 : 3 + 80 * totals[i] / maxV,
                  decoration: BoxDecoration(color: totals[i] == 0 ? color.withValues(alpha: 0.2) : color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 4),
                Text(weekdayName(days[i].weekday), style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
              ]),
            ),
        ],
      ),
    );
  }
}
