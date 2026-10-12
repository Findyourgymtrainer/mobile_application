import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import 'admin.dart';
import 'member.dart';
import 'messages.dart';
import 'profile.dart';
import 'trainer.dart';

class _Tab {
  final String label;
  final IconData icon;
  final Widget body;

  const _Tab(this.label, this.icon, this.body);
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  List<_Tab> _tabs(Role role) => switch (role) {
        Role.member => const [
            _Tab('Home', Icons.home_outlined, HomeTab()),
            _Tab('Trainers', Icons.search, TrainersTab()),
            _Tab('Bookings', Icons.event_outlined, MemberBookingsTab()),
            _Tab('Workouts', Icons.fitness_center, WorkoutsTab()),
            _Tab('Profile', Icons.person_outline, ProfileTab()),
          ],
        Role.trainer => const [
            _Tab('Dashboard', Icons.dashboard_outlined, TrainerDashboardTab()),
            _Tab('Availability', Icons.schedule, AvailabilityTab()),
            _Tab('Clients', Icons.groups_outlined, ClientsTab()),
            _Tab('Profile', Icons.person_outline, ProfileTab()),
          ],
        Role.admin => const [
            _Tab('Trainers', Icons.verified_user_outlined, AdminTrainersTab()),
            _Tab('Reviews', Icons.rate_review_outlined, AdminReviewsTab()),
            _Tab('Profile', Icons.person_outline, ProfileTab()),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.user!;
    final tabs = _tabs(user.role);
    final index = _index.clamp(0, tabs.length - 1);
    final unread = app.unreadCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[index].label),
        actions: [
          if (user.role != Role.admin)
            IconButton(
              tooltip: 'Messages',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationsScreen())),
            ),
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_outlined)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: [for (final t in tabs) t.body]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.icon), label: t.label)],
      ),
    );
  }
}
