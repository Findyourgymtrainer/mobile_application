import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import 'common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.search_rounded, 'Find the right trainer', 'Search and filter certified trainers by specialty, location, price and rating.'),
    (Icons.event_available_rounded, 'Book in seconds', 'Pick a free slot, send a request and get notified when your trainer confirms.'),
    (Icons.show_chart_rounded, 'Track your progress', 'Log every workout, see your weekly volume and follow plans from your trainer.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: app.completeOnboarding, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final p in _pages)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(p.$1, size: 64, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 32),
                      Text(p.$2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(p.$3, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                    ]),
                  ),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == _page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => last
                    ? app.completeOnboarding()
                    : _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                child: Text(last ? 'Get started' : 'Next'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _hide = true;
  Role _role = Role.member;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final app = AppScope.of(context);
    final err = _signUp
        ? app.signUp(name: _name.text, email: _email.text, password: _password.text, phone: _phone.text, role: _role)
        : app.login(_email.text, _password.text);
    setState(() => _error = err);
  }

  void _quick(String email) {
    _email.text = email;
    _password.text = 'demo123';
    setState(() {
      _signUp = false;
      _error = AppScope.of(context).login(email, 'demo123');
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Icon(Icons.fitness_center_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('Find Your Gym Trainer',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: const [ButtonSegment(value: false, label: Text('Log in')), ButtonSegment(value: true, label: Text('Sign up'))],
                    selected: {_signUp},
                    onSelectionChanged: (s) => setState(() {
                      _signUp = s.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (_signUp) ...[
                    SegmentedButton<Role>(
                      segments: const [
                        ButtonSegment(value: Role.member, icon: Icon(Icons.person_outline), label: Text('Member')),
                        ButtonSegment(value: Role.trainer, icon: Icon(Icons.sports_gymnastics), label: Text('Trainer')),
                      ],
                      selected: {_role},
                      onSelectionChanged: (s) => setState(() => _role = s.first),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone (optional)'),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _hide,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _submit, child: Padding(padding: const EdgeInsets.all(6), child: Text(_signUp ? 'Create account' : 'Log in'))),
                  if (!_signUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => _forgotPassword(context), child: const Text('Forgot password?')),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _phoneSheet(context),
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Continue with phone (OTP)'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: app.googleLogin,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google (demo)'),
                  ),
                  const SizedBox(height: 24),
                  Text('Try a demo account (password: demo123)',
                      textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 8),
                  Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                    ActionChip(label: const Text('Member'), onPressed: () => _quick('member@demo.com')),
                    ActionChip(label: const Text('Trainer'), onPressed: () => _quick('trainer@demo.com')),
                    ActionChip(label: const Text('Admin'), onPressed: () => _quick('admin@demo.com')),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword(BuildContext context) async {
    final app = AppScope.of(context);
    final email = TextEditingController(text: _email.text);
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Account email')),
          const SizedBox(height: 12),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final err = app.resetPassword(email.text, pass.text);
      showMsg(context, err ?? 'Password updated. You can log in now.');
    }
  }

  void _phoneSheet(BuildContext context) {
    final app = AppScope.of(context);
    final phone = TextEditingController();
    final otp = TextEditingController();
    final name = TextEditingController();
    String? error;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(c).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Sign in with phone', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Demo mode: use OTP $kDemoOtp', style: TextStyle(color: Theme.of(c).hintColor)),
            const SizedBox(height: 16),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name (new users)')),
            const SizedBox(height: 12),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
            const SizedBox(height: 12),
            TextField(controller: otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'OTP')),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: TextStyle(color: Theme.of(c).colorScheme.error))),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final err = app.phoneLogin(phone.text, otp.text, name: name.text);
                if (err == null) {
                  Navigator.pop(c);
                } else {
                  setSheet(() => error = err);
                }
              },
              child: const Text('Verify & continue'),
            ),
          ]),
        ),
      ),
    );
  }
}
