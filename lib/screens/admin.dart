import 'package:flutter/material.dart';

import '../app_state.dart';
import 'common.dart';
import 'member.dart';

class AdminTrainersTab extends StatelessWidget {
  const AdminTrainersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pending = app.trainers.where((t) => !t.approved).toList();
    final approved = app.trainers.where((t) => t.approved).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      SectionTitle('Awaiting approval (${pending.length})'),
      if (pending.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No trainers waiting for approval.'))),
      for (final t in pending)
        Card(
          child: ListTile(
            leading: Avatar(t.name),
            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(app.userById(t.id)?.email ?? ''),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Reject', icon: const Icon(Icons.close, color: Colors.red), onPressed: () => app.setApproval(t.id, false)),
              IconButton(tooltip: 'Approve', icon: const Icon(Icons.check, color: Colors.green), onPressed: () => app.setApproval(t.id, true)),
            ]),
          ),
        ),
      SectionTitle('Active trainers (${approved.length})'),
      for (final t in approved)
        Card(
          child: ListTile(
            leading: Avatar(t.name),
            title: Text(t.name),
            subtitle: Text('${t.location} · ${t.specialties.join(', ')}'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainerId: t.id))),
            trailing: IconButton(
              tooltip: 'Remove trainer',
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: () async {
                if (await confirm(context, 'Remove ${t.name}?', 'Their account and bookings will be deleted.', action: 'Remove')) {
                  app.setApproval(t.id, false);
                }
              },
            ),
          ),
        ),
    ]);
  }
}

class AdminReviewsTab extends StatelessWidget {
  const AdminReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final reviews = app.reviews.reversed.toList();
    if (reviews.isEmpty) return const EmptyState(Icons.rate_review_outlined, 'No reviews to moderate.');
    return ListView(children: [
      const SizedBox(height: 8),
      for (final r in reviews)
        Card(
          child: ListTile(
            leading: Avatar(r.memberName),
            title: Text('${r.memberName} → ${app.nameOf(r.trainerId)}'),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stars(r.rating.toDouble(), size: 14),
              if (r.comment.isNotEmpty) Text(r.comment),
            ]),
            isThreeLine: r.comment.isNotEmpty,
            trailing: IconButton(
              tooltip: 'Remove review',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context, 'Remove review?', 'This review will be permanently deleted.', action: 'Remove')) {
                  app.deleteReview(r.id);
                }
              },
            ),
          ),
        ),
    ]);
  }
}
