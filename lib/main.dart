import 'package:flutter/material.dart';

void main() {
  runApp(const FslmsApp());
}

enum Role { student, parent, teacher, director }

extension RoleInfo on Role {
  String get label {
    switch (this) {
      case Role.student:
        return 'Student';
      case Role.parent:
        return 'Parent';
      case Role.teacher:
        return 'Teacher';
      case Role.director:
        return 'Director';
    }
  }

  String get subtitle {
    switch (this) {
      case Role.student:
        return 'Learn, grow, and stay on track';
      case Role.parent:
        return 'Stay connected with your child';
      case Role.teacher:
        return 'Teach, manage, and inspire';
      case Role.director:
        return 'Manage your school community';
    }
  }

  IconData get icon {
    switch (this) {
      case Role.student:
        return Icons.school_rounded;
      case Role.parent:
        return Icons.family_restroom_rounded;
      case Role.teacher:
        return Icons.cast_for_education_rounded;
      case Role.director:
        return Icons.admin_panel_settings_rounded;
    }
  }
}

class FslmsApp extends StatefulWidget {
  const FslmsApp({super.key});

  @override
  State<FslmsApp> createState() => _FslmsAppState();
}

class _FslmsAppState extends State<FslmsApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void openDashboard(Role role) {
    navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(
        builder: (_) => FslmsShell(
          role: role,
          themeMode: themeMode,
          onThemeChanged: toggleTheme,
        ),
      ),
    );
  }

  void openLogin() {
    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(onLogin: openDashboard)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FSLMS',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xfff6f7fb),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      home: LoginScreen(onLogin: openDashboard),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final ValueChanged<Role> onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  Role selectedRole = Role.student;

  bool obscurePassword = true;
  bool rememberMe = false;
  bool registerMode = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void submit() {
    final id = emailController.text.trim();
    final password = passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your FSLMS ID and password.'),
        ),
      );
      return;
    }

    if (registerMode && nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }

    widget.onLogin(selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        registerMode ? 'Create your account' : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome to FSLMS 👋',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      if (registerMode) ...[
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'FSLMS ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Role>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: Role.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.label),
                          );
                        }).toList(),
                        onChanged: (role) {
                          if (role != null) {
                            setState(() {
                              selectedRole = role;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                        title: const Text('Remember me'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            registerMode ? 'Create account' : 'Sign in',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            registerMode = !registerMode;
                          });
                        },
                        child: Text(
                          registerMode
                              ? 'Already have an account? Sign in'
                              : 'Create account',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FslmsShell extends StatefulWidget {
  final Role role;
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;

  const FslmsShell({
    super.key,
    required this.role,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<FslmsShell> createState() => _FslmsShellState();
}

class _FslmsShellState extends State<FslmsShell> {
  int selectedIndex = 0;

  final pages = const [
    DashboardPage(),
    LearningPage(),
    PlannerPage(),
    CommunicationPage(),
    NotificationsPage(),
    SettingsPage(),
  ];

  final titles = const [
    'Dashboard',
    'My Learning',
    'Study Planner',
    'Communication',
    'Notifications',
    'Settings',
  ];

  void signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onLogin: (role) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => FslmsShell(
                  role: role,
                  themeMode: widget.themeMode,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            );
          },
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  selectedIndex: selectedIndex,
                  onSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  role: widget.role,
                  onSignOut: signOut,
                ),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(titles[selectedIndex]),
                      actions: [
                        IconButton(
                          tooltip: 'Toggle theme',
                          onPressed: widget.onThemeChanged,
                          icon: Icon(
                            widget.themeMode == ThemeMode.dark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    body: pages[selectedIndex],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[selectedIndex]),
            actions: [
              IconButton(
                tooltip: 'Toggle theme',
                onPressed: widget.onThemeChanged,
                icon: Icon(
                  widget.themeMode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              ),
            ],
          ),
          body: pages[selectedIndex],
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ),
              ),
              NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book_rounded),
                    label: 'Learning',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Planner',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_outlined),
                    selectedIcon: Icon(Icons.chat_rounded),
                    label: 'Chat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_outlined),
                    selectedIcon: Icon(Icons.notifications_rounded),
                    label: 'Alerts',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Role role;
  final VoidCallback onSignOut;

  const _Sidebar({
    required this.selectedIndex,
    required this.onSelected,
    required this.role,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const items = [
      ('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
      ('My Learning', Icons.menu_book_outlined, Icons.menu_book_rounded),
      (
        'Study Planner',
        Icons.calendar_month_outlined,
        Icons.calendar_month_rounded,
      ),
      ('Communication', Icons.chat_outlined, Icons.chat_rounded),
      (
        'Notifications',
        Icons.notifications_outlined,
        Icons.notifications_rounded,
      ),
      ('Settings', Icons.settings_outlined, Icons.settings_rounded),
    ];

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'FSLMS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = selectedIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        selected: selected,
                        selectedTileColor: theme.colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Icon(selected ? item.$3 : item.$2),
                        title: Text(item.$1),
                        onTap: () => onSelected(index),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(child: Icon(role.icon)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'FSLMS Account',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _HeroBanner(),
          SizedBox(height: 24),
          _Metrics(),
          SizedBox(height: 24),
          _PrimaryDashboardCard(),
          SizedBox(height: 24),
          _ProgressCard(),
          SizedBox(height: 24),
          _QuickActions(),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to FSLMS 👋',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your school journey, connected in one place.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        _MetricCard(
          title: 'Attendance',
          value: '92%',
          icon: Icons.calendar_today_rounded,
        ),
        _MetricCard(
          title: 'Average Grade',
          value: 'A−',
          icon: Icons.grade_rounded,
        ),
        _MetricCard(
          title: 'Assignments',
          value: '04',
          icon: Icons.assignment_rounded,
        ),
        _MetricCard(
          title: 'Day Streak',
          value: '12',
          icon: Icons.local_fire_department_rounded,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(title),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryDashboardCard extends StatelessWidget {
  const _PrimaryDashboardCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today’s Schedule',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            _ScheduleItem(
              time: '08:00',
              subject: 'Mathematics',
              icon: Icons.calculate_rounded,
            ),
            _ScheduleItem(
              time: '10:00',
              subject: 'Science',
              icon: Icons.science_rounded,
            ),
            _ScheduleItem(
              time: '13:00',
              subject: 'English',
              icon: Icons.menu_book_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final String time;
  final String subject;
  final IconData icon;

  const _ScheduleItem({
    required this.time,
    required this.subject,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(subject),
      trailing: Text(time),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learning Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: 0.72,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 10),
            const Text('72% of your learning goals completed'),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assignment_rounded),
                  label: const Text('Assignments'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: const Text('Planner'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Messages'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      icon: Icons.menu_book_rounded,
      title: 'My Learning',
      description:
          'Access your subjects, lessons, assignments, and learning resources.',
    );
  }
}

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      icon: Icons.calendar_month_rounded,
      title: 'Study Planner',
      description:
          'Plan your study sessions, assignments, and important school activities.',
    );
  }
}

class CommunicationPage extends StatelessWidget {
  const CommunicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      icon: Icons.chat_rounded,
      title: 'Communication',
      description:
          'Stay connected with teachers, parents, and your school community.',
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      icon: Icons.notifications_rounded,
      title: 'Notifications',
      description:
          'View announcements, reminders, messages, and important updates.',
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      icon: Icons.settings_rounded,
      title: 'Settings',
      description: 'Manage your FSLMS preferences and account settings.',
    );
  }
}

class _SimplePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SimplePage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
