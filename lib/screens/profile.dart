import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../seed.dart';
import 'common.dart';
import 'member.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.user!;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      const SizedBox(height: 16),
      Center(child: Avatar(user.name, radius: 44)),
      const SizedBox(height: 12),
      Center(child: Text(user.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
      Center(child: Text(user.email.endsWith('@phone.local') ? user.phone : user.email, style: TextStyle(color: Theme.of(context).hintColor))),
      Center(child: Padding(padding: const EdgeInsets.only(top: 6), child: Chip(label: Text(user.role.name.toUpperCase())))),
      const SizedBox(height: 8),
      ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: const Text('Edit profile'),
        onTap: () => _editProfile(context),
      ),
      if (user.role == Role.trainer)
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Trainer profile'),
          subtitle: const Text('Bio, specialties, certifications, rate'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainerProfileEditScreen())),
        ),
      if (user.role == Role.member)
        ListTile(
          leading: const Icon(Icons.favorite_border),
          title: const Text('Favourite trainers'),
          trailing: Text('${app.favouriteTrainers.length}'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouritesScreen())),
        ),
      const Divider(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Appearance'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {app.themeMode},
            onSelectionChanged: (s) => app.setThemeMode(s.first),
          ),
        ]),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.restart_alt),
        title: const Text('Reset demo data'),
        subtitle: const Text('Restore sample trainers and accounts'),
        onTap: () async {
          if (await confirm(context, 'Reset demo data?', 'All local data will be replaced with the demo data.', action: 'Reset')) {
            app.resetDemoData();
          }
        },
      ),
      ListTile(leading: const Icon(Icons.logout), title: const Text('Log out'), onTap: app.logout),
      ListTile(
        leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
        title: Text('Delete my account', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        onTap: () async {
          if (await confirm(context, 'Delete account?', 'Your account and all of your data will be permanently removed.', action: 'Delete')) {
            app.deleteAccount();
          }
        },
      ),
    ]);
  }

  Future<void> _editProfile(BuildContext context) async {
    final app = AppScope.of(context);
    final name = TextEditingController(text: app.user!.name);
    final phone = TextEditingController(text: app.user!.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) app.updateProfile(name: name.text, phone: phone.text);
  }
}

class TrainerProfileEditScreen extends StatefulWidget {
  const TrainerProfileEditScreen({super.key});

  @override
  State<TrainerProfileEditScreen> createState() => _TrainerProfileEditScreenState();
}

class _TrainerProfileEditScreenState extends State<TrainerProfileEditScreen> {
  late final Trainer _t = AppScope.of(context).myTrainer!;
  late final _bio = TextEditingController(text: _t.bio);
  late final _certs = TextEditingController(text: _t.certifications.join(', '));
  late final _rate = TextEditingController(text: '${_t.rate}');

  @override
  void dispose() {
    _bio.dispose();
    _certs.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _save() {
    _t.bio = _bio.text.trim();
    _t.certifications = _certs.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    _t.rate = int.tryParse(_rate.text) ?? _t.rate;
    AppScope.of(context).saveTrainerProfile(_t);
    Navigator.pop(context);
    showMsg(context, 'Trainer profile saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainer profile'), actions: [TextButton(onPressed: _save, child: const Text('Save'))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _bio, maxLines: 4, decoration: const InputDecoration(labelText: 'About you')),
        const SizedBox(height: 16),
        const Text('Specialties'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final s in kSpecialties)
            FilterChip(
              label: Text(s),
              selected: _t.specialties.contains(s),
              onSelected: (v) => setState(() => v ? _t.specialties.add(s) : _t.specialties.remove(s)),
            ),
        ]),
        const SizedBox(height: 16),
        TextField(controller: _certs, decoration: const InputDecoration(labelText: 'Certifications (comma separated)')),
        const SizedBox(height: 16),
        TextField(
          controller: _rate,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Rate per hour (₹)'),
        ),
        const SizedBox(height: 16),
        const Text('Location'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final l in kLocations) ChoiceChip(label: Text(l), selected: _t.location == l, onSelected: (_) => setState(() => _t.location = l)),
        ]),
        const SizedBox(height: 16),
        const Text('Gender'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final g in kGenders) ChoiceChip(label: Text(g), selected: _t.gender == g, onSelected: (_) => setState(() => _t.gender = g)),
        ]),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: const Padding(padding: EdgeInsets.all(6), child: Text('Save profile'))),
      ]),
    );
  }
}
