import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================
// FSLMS USER MODEL
// ============================================================

class FslmsUser {
  final String id;
  final String name;
  final Role role;

  const FslmsUser({required this.id, required this.name, required this.role});
}

// ============================================================
// FSLMS API
// ============================================================

class FslmsApi {
  static const String baseUrl = 'http://localhost:3000';

  static Role roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Role.student;
      case 'parent':
        return Role.parent;
      case 'teacher':
        return Role.teacher;
      case 'director':
        return Role.director;
      default:
        throw Exception('Unknown user role: $role');
    }
  }

  static Future<FslmsUser> login({
    required String id,
    required String password,
    required Role selectedRole,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': id,
            'password': password,
            'role': selectedRole.name,
          }),
        )
        .timeout(const Duration(seconds: 10));

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The backend returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message']?.toString() ?? 'Login failed.');
    }

    if (data['success'] != true || data['user'] == null) {
      throw Exception(data['message']?.toString() ?? 'Login failed.');
    }

    final user = data['user'] as Map<String, dynamic>;

    return FslmsUser(
      id: user['id'].toString(),
      name: user['name'].toString(),
      role: roleFromString(user['role'].toString()),
    );
  }

  static Future<List<Map<String, dynamic>>> getStudentGrades(
    String studentId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/students/$studentId/grades'))
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message']?.toString() ?? 'Unable to load grades.');
    }

    return List<Map<String, dynamic>>.from(
      (data['grades'] as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<List<Map<String, dynamic>>> getStudentAssignments(
    String studentId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/students/$studentId/assignments'))
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to load assignments.',
      );
    }

    return List<Map<String, dynamic>>.from(
      (data['assignments'] as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<void> sendAssignment({
    required String teacherId,
    required String studentId,
    required String title,
    required String subject,
    required String description,
    required String dueDate,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/assignments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'teacherId': teacherId,
            'studentId': studentId,
            'title': title,
            'subject': subject,
            'description': description,
            'dueDate': dueDate,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to send assignment.',
      );
    }
  }

  static Future<Map<String, dynamic>> getStudentAttendance(
    String studentId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/students/$studentId/attendance'))
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to load attendance.',
      );
    }

    return data;
  }

  static Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    final headers = {'Content-Type': 'application/json'};
    if (method == 'GET') {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
    } else if (method == 'POST') {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 10));
    } else if (method == 'PATCH') {
      response = await http
          .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 10));
    } else if (method == 'DELETE') {
      response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
    } else {
      throw Exception('Unsupported request method.');
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The backend returned an invalid response.');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] == false) {
      throw Exception(
        data['message']?.toString() ??
            'Request failed (${response.statusCode}).',
      );
    }
    return data;
  }

  static Future<List<Map<String, dynamic>>> getPlanner(String studentId) async {
    final data = await _requestJson('GET', '/api/students/$studentId/planner');
    return List<Map<String, dynamic>>.from(
      (data['sessions'] as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<Map<String, dynamic>> createPlannerSession(
    String studentId,
    Map<String, dynamic> session,
  ) async {
    final data = await _requestJson(
      'POST',
      '/api/students/$studentId/planner',
      body: session,
    );
    return Map<String, dynamic>.from(data['session'] as Map);
  }

  static Future<Map<String, dynamic>> updatePlannerSession(
    String studentId,
    int sessionId,
    Map<String, dynamic> changes,
  ) async {
    final data = await _requestJson(
      'PATCH',
      '/api/students/$studentId/planner/$sessionId',
      body: changes,
    );
    return Map<String, dynamic>.from(data['session'] as Map);
  }

  static Future<void> deletePlannerSession(
    String studentId,
    int sessionId,
  ) async {
    await _requestJson('DELETE', '/api/students/$studentId/planner/$sessionId');
  }

  static Future<List<Map<String, dynamic>>> getLearning(
    String studentId,
  ) async {
    final data = await _requestJson('GET', '/api/students/$studentId/learning');
    return List<Map<String, dynamic>>.from(
      (data['lessons'] as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<void> setLessonCompleted(
    String studentId,
    int lessonId,
    bool completed,
  ) async {
    await _requestJson(
      'PATCH',
      '/api/students/$studentId/lessons/$lessonId',
      body: {'completed': completed},
    );
  }

  static Future<void> submitAssignment(
    String studentId,
    int assignmentId,
    String submissionText,
  ) async {
    await _requestJson(
      'PATCH',
      '/api/students/$studentId/assignments/$assignmentId/submission',
      body: {'submissionText': submissionText},
    );
  }

  static Future<void> setAssignmentStatus(
    String studentId,
    int assignmentId,
    String status,
  ) async {
    await _requestJson(
      'PATCH',
      '/api/students/$studentId/assignments/$assignmentId/status',
      body: {'status': status},
    );
  }

  static Future<List<Map<String, dynamic>>> getNotifications(
    String studentId,
  ) async {
    final data = await _requestJson(
      'GET',
      '/api/students/$studentId/notifications',
    );
    return List<Map<String, dynamic>>.from(
      (data['notifications'] as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<void> markMessageRead(int messageId, String userId) async {
    await _requestJson(
      'PATCH',
      '/api/messages/$messageId/read',
      body: {'userId': userId},
    );
  }

  static Future<List<Map<String, dynamic>>> getParentChildren(
    String parentId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/parents/$parentId/children'))
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to load children.',
      );
    }

    return List<Map<String, dynamic>>.from(
      (data['children'] as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<List<Map<String, dynamic>>> getTeacherStudents(
    String teacherId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/teachers/$teacherId/students'))
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to load students.',
      );
    }

    return List<Map<String, dynamic>>.from(
      (data['students'] as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<List<Map<String, dynamic>>> getMessages(String userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/messages/$userId'))
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to load messages.',
      );
    }

    return List<Map<String, dynamic>>.from(
      (data['messages'] as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<void> sendMessage({
    required String from,
    required String to,
    required String subject,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/messages'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'from': from,
            'to': to,
            'subject': subject,
            'message': message,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message']?.toString() ?? 'Unable to send message.');
    }
  }

  static Future<Map<String, dynamic>> getDirectorDashboard() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/director/dashboard'))
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to load dashboard.',
      );
    }

    return Map<String, dynamic>.from(data['dashboard'] as Map);
  }
}

// ============================================================
// APP
// ============================================================

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
        return 'Learn, track progress and grow';
      case Role.parent:
        return 'Stay connected with your child';
      case Role.teacher:
        return 'Teach, manage and communicate';
      case Role.director:
        return 'Manage your school';
    }
  }

  String get dashboardTitle {
    switch (this) {
      case Role.student:
        return 'Student Hub';
      case Role.parent:
        return 'Family Overview';
      case Role.teacher:
        return 'Teaching Center';
      case Role.director:
        return 'School Command Center';
    }
  }

  IconData get icon {
    switch (this) {
      case Role.student:
        return Icons.school_rounded;
      case Role.parent:
        return Icons.family_restroom_rounded;
      case Role.teacher:
        return Icons.co_present_rounded;
      case Role.director:
        return Icons.admin_panel_settings_rounded;
    }
  }
}

class NavItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  const NavItem(this.title, this.icon, this.selectedIcon);
}

List<NavItem> navItemsFor(Role role) {
  switch (role) {
    case Role.student:
      return const [
        NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
        NavItem(
          'My Learning',
          Icons.menu_book_outlined,
          Icons.menu_book_rounded,
        ),
        NavItem(
          'Study Planner',
          Icons.calendar_month_outlined,
          Icons.calendar_month_rounded,
        ),
        NavItem(
          'Assignments',
          Icons.assignment_outlined,
          Icons.assignment_rounded,
        ),
        NavItem('Grades', Icons.grade_outlined, Icons.grade_rounded),
        NavItem(
          'Communication',
          Icons.chat_bubble_outline_rounded,
          Icons.chat_bubble_rounded,
        ),
        NavItem(
          'Notifications',
          Icons.notifications_none_rounded,
          Icons.notifications_rounded,
        ),
        NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
      ];

    case Role.parent:
      return const [
        NavItem('Overview', Icons.dashboard_outlined, Icons.dashboard_rounded),
        NavItem('Children', Icons.people_outline_rounded, Icons.people_rounded),
        NavItem(
          'Attendance',
          Icons.event_available_outlined,
          Icons.event_available_rounded,
        ),
        NavItem('Results', Icons.assessment_outlined, Icons.assessment_rounded),
        NavItem('Messages', Icons.forum_outlined, Icons.forum_rounded),
        NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
      ];

    case Role.teacher:
      return const [
        NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
        NavItem('My Classes', Icons.class_outlined, Icons.class_rounded),
        NavItem('Students', Icons.groups_outlined, Icons.groups_rounded),
        NavItem(
          'Assignments',
          Icons.assignment_outlined,
          Icons.assignment_rounded,
        ),
        NavItem('Messages', Icons.forum_outlined, Icons.forum_rounded),
        NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
      ];

    case Role.director:
      return const [
        NavItem(
          'Command Center',
          Icons.space_dashboard_outlined,
          Icons.space_dashboard_rounded,
        ),
        NavItem('Students', Icons.school_outlined, Icons.school_rounded),
        NavItem(
          'Teachers',
          Icons.co_present_outlined,
          Icons.co_present_rounded,
        ),
        NavItem('Reports', Icons.analytics_outlined, Icons.analytics_rounded),
        NavItem(
          'Announcements',
          Icons.campaign_outlined,
          Icons.campaign_rounded,
        ),
        NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
      ];
  }
}

// ============================================================
// APP STATE
// ============================================================

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

  void openDashboard(FslmsUser user) {
    navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(
        builder: (_) => FslmsShell(
          user: user,
          themeMode: themeMode,
          onThemeChanged: toggleTheme,
          onSignOut: signOut,
        ),
      ),
    );
  }

  void signOut() {
    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(onLogin: openDashboard)),
      (route) => false,
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff5B5FEF),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xffF6F7FB),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xff5B5FEF), width: 1.5),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff7C82FF),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff101116),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xff1B1D25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xff7C82FF), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FSLMS',
      themeMode: themeMode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: LoginScreen(onLogin: openDashboard),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginScreen extends StatefulWidget {
  final void Function(FslmsUser user) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  Role selectedRole = Role.student;

  bool obscurePassword = true;
  bool rememberMe = false;
  bool registerMode = false;
  bool isLoading = false;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (isLoading) return;

    final id = idController.text.trim().toUpperCase();
    final password = passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      _message('Please enter your FSLMS ID and password.');
      return;
    }

    if (registerMode) {
      if (nameController.text.trim().isEmpty) {
        _message('Please enter your full name.');
        return;
      }

      _message('Account registration will be connected to the backend next.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final user = await FslmsApi.login(
        id: id,
        password: password,
        selectedRole: selectedRole,
      );

      if (!mounted) return;

      widget.onLogin(user);
    } on http.ClientException {
      if (!mounted) return;

      _message('Could not connect to the FSLMS backend.');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      _message(message);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: desktop
                  ? Row(
                      children: [
                        Expanded(child: LoginIntro(registerMode: registerMode)),
                        const SizedBox(width: 50),
                        SizedBox(
                          width: 430,
                          child: LoginCard(
                            selectedRole: selectedRole,
                            registerMode: registerMode,
                            obscurePassword: obscurePassword,
                            rememberMe: rememberMe,
                            isLoading: isLoading,
                            idController: idController,
                            passwordController: passwordController,
                            nameController: nameController,
                            onRoleChanged: (role) {
                              setState(() {
                                selectedRole = role;
                              });
                            },
                            onRegisterModeChanged: (value) {
                              setState(() {
                                registerMode = value;
                              });
                            },
                            onPasswordVisibilityChanged: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            onRememberChanged: (value) {
                              setState(() {
                                rememberMe = value ?? false;
                              });
                            },
                            onSubmit: submit,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        LoginIntro(registerMode: registerMode, compact: true),
                        const SizedBox(height: 30),
                        LoginCard(
                          selectedRole: selectedRole,
                          registerMode: registerMode,
                          obscurePassword: obscurePassword,
                          rememberMe: rememberMe,
                          isLoading: isLoading,
                          idController: idController,
                          passwordController: passwordController,
                          nameController: nameController,
                          onRoleChanged: (role) {
                            setState(() {
                              selectedRole = role;
                            });
                          },
                          onRegisterModeChanged: (value) {
                            setState(() {
                              registerMode = value;
                            });
                          },
                          onPasswordVisibilityChanged: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          onRememberChanged: (value) {
                            setState(() {
                              rememberMe = value ?? false;
                            });
                          },
                          onSubmit: submit,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginIntro extends StatelessWidget {
  final bool registerMode;
  final bool compact;

  const LoginIntro({
    super.key,
    required this.registerMode,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = compact
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff5B5FEF), Color(0xff7C4DFF)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FSLMS',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          'Family School Learning\nManagement System',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Text(
          registerMode
              ? 'Create a connected school account for your role.'
              : 'One connected platform for students, parents, teachers and school directors.',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class LoginCard extends StatelessWidget {
  final Role selectedRole;
  final bool registerMode;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isLoading;

  final TextEditingController idController;
  final TextEditingController passwordController;
  final TextEditingController nameController;

  final ValueChanged<Role> onRoleChanged;
  final ValueChanged<bool> onRegisterModeChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onSubmit;

  const LoginCard({
    super.key,
    required this.selectedRole,
    required this.registerMode,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isLoading,
    required this.idController,
    required this.passwordController,
    required this.nameController,
    required this.onRoleChanged,
    required this.onRegisterModeChanged,
    required this.onPasswordVisibilityChanged,
    required this.onRememberChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AuthTab(
                    title: 'Sign in',
                    active: !registerMode,
                    onTap: isLoading
                        ? () {}
                        : () => onRegisterModeChanged(false),
                  ),
                ),
                Expanded(
                  child: AuthTab(
                    title: 'Create account',
                    active: registerMode,
                    onTap: isLoading
                        ? () {}
                        : () => onRegisterModeChanged(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              registerMode ? 'Create your account' : 'Welcome back',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              registerMode
                  ? 'Choose your role and create your FSLMS account.'
                  : 'Sign in to continue to your role-specific FSLMS dashboard.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'I am a',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Role.values.map((role) {
                return ChoiceChip(
                  label: Text(role.label),
                  avatar: Icon(role.icon, size: 18),
                  selected: selectedRole == role,
                  onSelected: isLoading ? null : (_) => onRoleChanged(role),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            if (registerMode) ...[
              TextField(
                controller: nameController,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: idController,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'FSLMS ID',
                hintText: 'Example: AGS001',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: isLoading ? null : (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: isLoading ? null : onPasswordVisibilityChanged,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!registerMode)
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: isLoading ? null : onRememberChanged,
                  ),
                  const Text('Remember me'),
                  const Spacer(),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password recovery will be connected to the backend later.',
                                ),
                              ),
                            );
                          },
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: isLoading ? null : onSubmit,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        registerMode ? 'Create account' : 'Sign in',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                '${selectedRole.label} • ${selectedRole.subtitle}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            if (!registerMode) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo accounts',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Student: AGS001\n'
                      'Parent: AGP001\n'
                      'Teacher: AGT001\n'
                      'Director: AGD001\n'
                      'Password: 123456',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AuthTab extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const AuthTab({
    super.key,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAIN SHELL
// ============================================================

class FslmsShell extends StatefulWidget {
  final FslmsUser user;
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;
  final VoidCallback onSignOut;

  const FslmsShell({
    super.key,
    required this.user,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onSignOut,
  });

  @override
  State<FslmsShell> createState() => _FslmsShellState();
}

class _FslmsShellState extends State<FslmsShell> {
  int selectedIndex = 0;

  Role get role => widget.user.role;

  List<Widget> get pages {
    switch (role) {
      case Role.student:
        return [
          StudentDashboard(user: widget.user, onNavigate: select),
          StudentLearningPage(user: widget.user),
          StudentPlannerPage(user: widget.user),
          StudentAssignmentsPage(user: widget.user),
          StudentGradesPage(user: widget.user),
          StudentCommunicationPage(user: widget.user),
          StudentNotificationsPage(user: widget.user),
          StudentSettingsPage(user: widget.user),
        ];

      case Role.parent:
        return [
          ParentDashboard(user: widget.user),
          ParentChildrenPage(user: widget.user),
          ParentAttendancePage(),
          const ParentResultsPage(),
          ParentMessagesPage(user: widget.user),
          const ParentSettingsPage(),
        ];

      case Role.teacher:
        return [
          TeacherDashboard(user: widget.user),
          const TeacherClassesPage(),
          TeacherStudentsPage(user: widget.user),
          TeacherAssignmentsPage(user: widget.user),
          const TeacherMessagesPage(),
          const TeacherSettingsPage(),
        ];

      case Role.director:
        return [
          DirectorDashboard(user: widget.user),
          const DirectorStudentsPage(),
          const DirectorTeachersPage(),
          const DirectorReportsPage(),
          const DirectorAnnouncementsPage(),
          const DirectorSettingsPage(),
        ];
    }
  }

  void select(int index) {
    if (index >= 0 && index < pages.length) {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = navItemsFor(role);
    final desktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: desktop
          ? Row(
              children: [
                RoleSidebar(
                  role: role,
                  user: widget.user,
                  items: items,
                  selectedIndex: selectedIndex,
                  onSelected: select,
                  themeMode: widget.themeMode,
                  onThemeChanged: widget.onThemeChanged,
                  onSignOut: widget.onSignOut,
                ),
                Expanded(
                  child: Column(
                    children: [
                      RoleTopBar(
                        role: role,
                        user: widget.user,
                        item: items[selectedIndex],
                        themeMode: widget.themeMode,
                        onThemeChanged: widget.onThemeChanged,
                        onSignOut: widget.onSignOut,
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: selectedIndex,
                          children: pages,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      RoleTopBar(
                        role: role,
                        user: widget.user,
                        item: items[selectedIndex],
                        themeMode: widget.themeMode,
                        onThemeChanged: widget.onThemeChanged,
                        onSignOut: widget.onSignOut,
                        mobile: true,
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: selectedIndex,
                          children: pages,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex.clamp(
                0,
                items.length > 4 ? 3 : items.length - 1,
              ),
              onDestinationSelected: select,
              destinations: items
                  .take(4)
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.title,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================

class RoleTopBar extends StatelessWidget {
  final Role role;
  final FslmsUser user;
  final NavItem item;
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;
  final VoidCallback onSignOut;
  final bool mobile;

  const RoleTopBar({
    super.key,
    required this.role,
    required this.user,
    required this.item,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onSignOut,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (role) {
      Role.student => item.title,
      Role.parent => 'Family • ${item.title}',
      Role.teacher => 'Teaching • ${item.title}',
      Role.director => 'Administration • ${item.title}',
    };

    final subtitle = switch (role) {
      Role.student => 'Keep learning and make progress.',
      Role.parent => 'Stay informed about your family.',
      Role.teacher => 'Manage your classes and learners.',
      Role.director => 'Monitor and lead the school.',
    };

    return Container(
      height: mobile ? 78 : 88,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.selectedIcon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (!mobile)
                  Text(
                    '$subtitle • ${user.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: themeMode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
            onPressed: onThemeChanged,
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'signout') {
                onSignOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(user.id, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 10),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(child: Icon(role.icon)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================

class RoleSidebar extends StatelessWidget {
  final Role role;
  final FslmsUser user;
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;
  final VoidCallback onSignOut;

  const RoleSidebar({
    super.key,
    required this.role,
    required this.user,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onSignOut,
  });

  String get roleHint {
    switch (role) {
      case Role.student:
        return 'Learning space';
      case Role.parent:
        return 'Family space';
      case Role.teacher:
        return 'Teaching space';
      case Role.director:
        return 'Administration';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 258,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff5B5FEF), Color(0xff7C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'FSLMS',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              roleHint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 26),
          ...List.generate(
            items.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: selectedIndex == index,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  selectedIndex == index
                      ? items[index].selectedIcon
                      : items[index].icon,
                ),
                title: Text(items[index].title),
                onTap: () => onSelected(index),
              ),
            ),
          ),
          const Spacer(),
          ListTile(
            leading: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            title: Text(
              themeMode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
            ),
            onTap: onThemeChanged,
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: CircleAvatar(radius: 18, child: Icon(role.icon, size: 18)),
            title: Text(user.name),
            subtitle: Text(user.id),
          ),
          const SizedBox(height: 4),
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
    );
  }
}

// ============================================================
// SHARED UI
// ============================================================

class FslmsPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const FslmsPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.035),
            scheme.secondary.withValues(alpha: 0.025),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 450));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            PageHeader(title: title, subtitle: subtitle, icon: icon),
            const SizedBox(height: 22),
            ...children,
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff5B5FEF), Color(0xff7C4DFF)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsGrid extends StatelessWidget {
  final List<StatCard> cards;

  const StatsGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 3.2 : 2.1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            scheme.primary.withValues(alpha: 0.035),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: -12,
            offset: const Offset(0, 10),
            color: scheme.primary.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap:
            onTap ??
            () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$title opened')));
            },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                scheme.primary.withValues(alpha: 0.08),
                scheme.secondary.withValues(alpha: 0.035),
              ],
            ),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: scheme.onPrimary),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
        ),
      ),
    );
  }
}

class MiniRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  const MiniRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon, size: 19)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: Text(
        trailing,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  final String title;
  final double value;

  const ProgressLine({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text('${(value * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: value, minHeight: 8),
      ],
    );
  }
}

class GradeRow extends StatelessWidget {
  final String subject;
  final int score;
  final String grade;

  const GradeRow({
    super.key,
    required this.subject,
    required this.score,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '$score%',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                grade,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: score / 100, minHeight: 8),
        ),
      ],
    );
  }
}

// ============================================================
// STUDENT
// ============================================================

class StudentDashboard extends StatefulWidget {
  final FslmsUser user;
  final ValueChanged<int>? onNavigate;
  const StudentDashboard({super.key, required this.user, this.onNavigate});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<List<dynamic>> data;
  @override
  void initState() {
    super.initState();
    data = Future.wait([
      FslmsApi.getStudentGrades(widget.user.id),
      FslmsApi.getStudentAssignments(widget.user.id),
      FslmsApi.getStudentAttendance(widget.user.id),
      FslmsApi.getPlanner(widget.user.id),
    ]);
  }

  Future<void> refresh() async {
    setState(
      () => data = Future.wait([
        FslmsApi.getStudentGrades(widget.user.id),
        FslmsApi.getStudentAssignments(widget.user.id),
        FslmsApi.getStudentAttendance(widget.user.id),
        FslmsApi.getPlanner(widget.user.id),
      ]),
    );
    try {
      await data;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => FslmsPage(
    title: 'Welcome back, ${widget.user.name} 👋',
    subtitle: 'Your learning, assignments and study plan in one place.',
    icon: Icons.school_rounded,
    children: [
      SectionCard(
        title: 'Your school snapshot',
        subtitle: 'Numbers loaded from the FSLMS backend',
        trailing: IconButton(
          onPressed: refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: data,
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (s.hasError)
              return Text('Dashboard data is unavailable: ${s.error}');
            final grades = s.data![0] as List<Map<String, dynamic>>;
            final assignments = s.data![1] as List<Map<String, dynamic>>;
            final attendance = s.data![2] as Map<String, dynamic>;
            final planner = s.data![3] as List<Map<String, dynamic>>;
            final average = grades.isEmpty
                ? 0
                : grades
                          .map((g) => (g['score'] as num).toDouble())
                          .reduce((a, b) => a + b) /
                      grades.length;
            final pending = assignments
                .where((a) => a['status'] == 'pending')
                .length;
            final percentage =
                (attendance['summary'] as Map?)?['percentage'] ?? 0;
            final done = planner.where((p) => p['completed'] == true).length;
            return LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth;
                final columns = width > 850
                    ? 4
                    : width > 500
                    ? 2
                    : 1;
                final stats = [
                  ('Attendance', '$percentage%', Icons.event_available_rounded),
                  (
                    'Grade average',
                    '${average.toStringAsFixed(1)}%',
                    Icons.grade_rounded,
                  ),
                  ('Pending work', '$pending', Icons.assignment_rounded),
                  (
                    'Study sessions',
                    '$done/${planner.length}',
                    Icons.calendar_month_rounded,
                  ),
                ];
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: columns == 1 ? 4.4 : 2.0,
                  children: stats
                      .map(
                        (v) => Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                v.$3,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.$2,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    Text(
                                      v.$1,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
      ),
      const SizedBox(height: 18),
      StudentGradePreview(user: widget.user),
      const SizedBox(height: 18),
      SectionCard(
        title: 'Quick actions',
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ActionChip(
              avatar: const Icon(Icons.assignment_rounded),
              label: const Text('Review assignments'),
              onPressed: () => widget.onNavigate?.call(3),
            ),
            ActionChip(
              avatar: const Icon(Icons.calendar_month_rounded),
              label: const Text('Plan study time'),
              onPressed: () => widget.onNavigate?.call(2),
            ),
            ActionChip(
              avatar: const Icon(Icons.chat_rounded),
              label: const Text('Contact a teacher'),
              onPressed: () => widget.onNavigate?.call(5),
            ),
          ],
        ),
      ),
    ],
  );
}

class StudentGradesPage extends StatelessWidget {
  final FslmsUser user;

  const StudentGradesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'My Grades',
      subtitle: 'Review your subject scores and overall academic progress.',
      icon: Icons.grade_rounded,
      children: [StudentGradePreview(user: user)],
    );
  }
}

class StudentGradePreview extends StatefulWidget {
  final FslmsUser user;

  const StudentGradePreview({super.key, required this.user});

  @override
  State<StudentGradePreview> createState() => _StudentGradePreviewState();
}

class _StudentGradePreviewState extends State<StudentGradePreview> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = FslmsApi.getStudentGrades(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SectionCard(
      title: 'Grading overview',
      subtitle: 'Your latest subject grades',
      trailing: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final grades = snapshot.data!;

          if (grades.isEmpty) {
            return const SizedBox.shrink();
          }

          final average =
              grades
                  .map((g) => (g['score'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              grades.length;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${average.round()}% average',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Text(
              'Could not load grades.',
              style: TextStyle(color: scheme.error),
            );
          }

          final grades = snapshot.data ?? [];

          if (grades.isEmpty) {
            return const Text('No grades available yet.');
          }

          return Column(
            children: grades.map((grade) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GradeRow(
                  subject: grade['subject'].toString(),
                  score: (grade['score'] as num).toInt(),
                  grade: grade['grade'].toString(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class StudentTodayCard extends StatelessWidget {
  const StudentTodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Today',
      subtitle: 'Your next learning activities',
      child: Column(
        children: [
          MiniRow(
            icon: Icons.calculate_rounded,
            title: 'Mathematics',
            subtitle: 'Algebra & Functions',
            trailing: '08:00',
          ),
          MiniRow(
            icon: Icons.science_rounded,
            title: 'Science',
            subtitle: 'Physics',
            trailing: '10:00',
          ),
          MiniRow(
            icon: Icons.menu_book_rounded,
            title: 'English',
            subtitle: 'Reading & Writing',
            trailing: '13:00',
          ),
        ],
      ),
    );
  }
}

class StudentProgressCard extends StatelessWidget {
  const StudentProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Learning progress',
      child: Column(
        children: [
          ProgressLine(title: 'Mathematics', value: .82),
          SizedBox(height: 20),
          ProgressLine(title: 'Science', value: .68),
          SizedBox(height: 20),
          ProgressLine(title: 'English', value: .74),
        ],
      ),
    );
  }
}

class StudentLearningPage extends StatefulWidget {
  final FslmsUser user;
  const StudentLearningPage({super.key, required this.user});
  @override
  State<StudentLearningPage> createState() => _StudentLearningPageState();
}

class _StudentLearningPageState extends State<StudentLearningPage> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = FslmsApi.getLearning(widget.user.id);
  }

  Future<void> reload() async {
    setState(() => future = FslmsApi.getLearning(widget.user.id));
    try {
      await future;
    } catch (_) {}
  }

  Future<void> toggle(Map<String, dynamic> lesson, bool value) async {
    try {
      await FslmsApi.setLessonCompleted(
        widget.user.id,
        (lesson['id'] as num).toInt(),
        value,
      );
      if (!mounted) return;
      setState(() => future = FslmsApi.getLearning(widget.user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Lesson marked complete.' : 'Lesson reopened.'),
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  @override
  Widget build(BuildContext context) => FslmsPage(
    title: 'My Learning',
    subtitle: 'Your subjects, lesson progress and learning activities.',
    icon: Icons.menu_book_rounded,
    children: [
      SectionCard(
        title: 'Lessons and subjects',
        subtitle: 'Progress saved to your FSLMS account',
        trailing: IconButton(
          onPressed: reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Text('Could not load learning content: ${snapshot.error}');
            final lessons = snapshot.data ?? [];
            if (lessons.isEmpty)
              return const Text('Your teachers have not added lessons yet.');
            return Column(
              children: lessons.map((lesson) {
                final done = lesson['completed'] == true;
                final progress =
                    ((lesson['progress'] as num?) ?? 0).toDouble().clamp(
                      0,
                      100,
                    ) /
                    100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: .5),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Icon(
                                done
                                    ? Icons.check_rounded
                                    : Icons.menu_book_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson['title'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    lesson['subject'].toString(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: done,
                              onChanged: (v) => toggle(lesson, v ?? false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(lesson['description']?.toString() ?? ''),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: done ? 1 : progress,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          done
                              ? 'Completed'
                              : '${((done ? 1 : progress) * 100).round()}% progress',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    ],
  );
}

class StudentAssignmentsPage extends StatefulWidget {
  final FslmsUser user;

  const StudentAssignmentsPage({super.key, required this.user});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  late Future<List<Map<String, dynamic>>> future;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    loadAssignments();

    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        loadAssignments(silent: true);
      }
    });
  }

  void loadAssignments({bool silent = false}) {
    final nextFuture = FslmsApi.getStudentAssignments(widget.user.id);

    if (silent) {
      setState(() {
        future = nextFuture;
      });
    } else {
      future = nextFuture;
    }
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshAssignments() async {
    setState(() {
      future = FslmsApi.getStudentAssignments(widget.user.id);
    });

    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Assignments',
      subtitle: 'Assignments sent directly to you by your teachers.',
      icon: Icons.assignment_rounded,
      children: [
        SectionCard(
          title: 'My assignments',
          subtitle: 'Live assignments from your FSLMS account',
          trailing: IconButton(
            tooltip: 'Refresh assignments',
            onPressed: refreshAssignments,
            icon: const Icon(Icons.refresh_rounded),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Could not load assignments.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                );
              }

              final assignments = snapshot.data ?? [];

              if (assignments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No assignments have been sent to you yet.'),
                );
              }

              return Column(
                children: assignments.map((assignment) {
                  final completed =
                      assignment['status']?.toString() == 'completed';

                  final teacher =
                      assignment['teacherName']?.toString() ??
                      assignment['teacherId']?.toString() ??
                      'Teacher';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  completed
                                      ? Icons.check_circle_rounded
                                      : Icons.assignment_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  assignment['title']?.toString() ??
                                      'Assignment',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  completed
                                      ? 'Completed'
                                      : (assignment['status']?.toString() ==
                                                'submitted'
                                            ? 'Submitted'
                                            : 'Pending'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${assignment['subject'] ?? 'Subject'} • Due ${assignment['dueDate'] ?? '—'}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'From: $teacher',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if ((assignment['description']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              assignment['description'].toString(),
                              style: TextStyle(
                                height: 1.45,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                          if (!completed) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final controller = TextEditingController(
                                    text:
                                        assignment['submissionText']
                                            ?.toString() ??
                                        '',
                                  );
                                  final submit = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text(
                                        assignment['status']?.toString() ==
                                                'submitted'
                                            ? 'Edit submission'
                                            : 'Submit your work',
                                      ),
                                      content: SizedBox(
                                        width: 480,
                                        child: TextField(
                                          controller: controller,
                                          minLines: 5,
                                          maxLines: 10,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Your answer / submission notes',
                                            hintText:
                                                'Write your answer or explain how you completed the work.',
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          child: const Text('Submit work'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (submit == true) {
                                    try {
                                      await FslmsApi.submitAssignment(
                                        widget.user.id,
                                        (assignment['id'] as num).toInt(),
                                        controller.text.trim(),
                                      );
                                      if (!mounted) {
                                        controller.dispose();
                                        return;
                                      }
                                      await refreshAssignments();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Your work was submitted to the backend.',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (mounted)
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceFirst(
                                                'Exception: ',
                                                '',
                                              ),
                                            ),
                                          ),
                                        );
                                    }
                                  }
                                  controller.dispose();
                                },
                                icon: Icon(
                                  assignment['status']?.toString() ==
                                          'submitted'
                                      ? Icons.edit_rounded
                                      : Icons.upload_rounded,
                                ),
                                label: Text(
                                  assignment['status']?.toString() ==
                                          'submitted'
                                      ? 'Edit submission'
                                      : 'Submit work',
                                ),
                              ),
                            ),
                            if ((assignment['submissionText']?.toString() ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Your submission: ${assignment['submissionText']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class StudentPlannerPage extends StatefulWidget {
  final FslmsUser user;
  const StudentPlannerPage({super.key, required this.user});
  @override
  State<StudentPlannerPage> createState() => _StudentPlannerPageState();
}

class _StudentPlannerPageState extends State<StudentPlannerPage> {
  late Future<List<Map<String, dynamic>>> future;
  DateTime selectedDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    future = FslmsApi.getPlanner(widget.user.id);
  }

  Future<void> reload() async {
    setState(() => future = FslmsApi.getPlanner(widget.user.id));
    try {
      await future;
    } catch (_) {}
  }

  String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  void toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> editSession([Map<String, dynamic>? existing]) async {
    final title = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );
    final subject = TextEditingController(
      text: existing?['subject']?.toString() ?? '',
    );
    final notes = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    DateTime date =
        DateTime.tryParse(existing?['date']?.toString() ?? '') ?? selectedDate;
    TimeOfDay time = TimeOfDay(
      hour:
          int.tryParse(
            (existing?['startTime']?.toString() ?? '16:00').split(':').first,
          ) ??
          16,
      minute:
          int.tryParse(
            (existing?['startTime']?.toString() ?? '16:00').split(':').last,
          ) ??
          0,
    );
    int duration = (existing?['duration'] as num?)?.toInt() ?? 30;
    String priority = existing?['priority']?.toString() ?? 'medium';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(
            existing == null ? 'Add study session' : 'Edit study session',
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'What will you study?',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setDialog(() => date = d);
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: Text(dateKey(date)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: time,
                            );
                            if (t != null) setDialog(() => time = t);
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(time.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: duration,
                    decoration: const InputDecoration(labelText: 'Duration'),
                    items: const [15, 25, 30, 45, 60, 90, 120]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v minutes'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialog(() => duration = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const ['low', 'medium', 'high']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialog(() => priority = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty || subject.text.trim().isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Enter a title and subject.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(existing == null ? 'Create session' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      try {
        final data = {
          'title': title.text.trim(),
          'subject': subject.text.trim(),
          'date': dateKey(date),
          'startTime':
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'duration': duration,
          'priority': priority,
          'notes': notes.text.trim(),
        };
        if (existing == null) {
          await FslmsApi.createPlannerSession(widget.user.id, data);
        } else {
          await FslmsApi.updatePlannerSession(
            widget.user.id,
            (existing['id'] as num).toInt(),
            data,
          );
        }
        if (mounted) {
          await reload();
          toast(
            existing == null
                ? 'Study session created.'
                : 'Study session updated.',
          );
        }
      } catch (e) {
        if (mounted) toast(e.toString().replaceFirst('Exception: ', ''));
      }
    }
    title.dispose();
    subject.dispose();
    notes.dispose();
  }

  Future<void> toggle(Map<String, dynamic> item, bool completed) async {
    try {
      await FslmsApi.updatePlannerSession(
        widget.user.id,
        (item['id'] as num).toInt(),
        {'completed': completed},
      );
      await reload();
    } catch (e) {
      if (mounted) toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deleteSession(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete study session?'),
        content: Text('Delete “${item['title']}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FslmsApi.deletePlannerSession(
        widget.user.id,
        (item['id'] as num).toInt(),
      );
      await reload();
      toast('Study session deleted.');
    } catch (e) {
      if (mounted) toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Study Planner',
      subtitle:
          'Build a realistic plan, schedule focused sessions and track what you finish.',
      icon: Icons.calendar_month_rounded,
      children: [
        SectionCard(
          title: 'Plan your week',
          subtitle: 'Choose a date, then add or manage your sessions.',
          trailing: FilledButton.icon(
            onPressed: () => editSession(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add session'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(
                      () => selectedDate = selectedDate.subtract(
                        const Duration(days: 1),
                      ),
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        dateKey(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => selectedDate = selectedDate.add(
                        const Duration(days: 1),
                      ),
                    ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => selectedDate = DateTime.now()),
                    child: const Text('Today'),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                  ).subtract(Duration(days: selectedDate.weekday - 1 - i));
                  final active = dateKey(day) == dateKey(selectedDate);
                  const dayNames = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  return ChoiceChip(
                    label: Text('${dayNames[i]}\n${day.day}'),
                    selected: active,
                    onSelected: (_) => setState(() => selectedDate = day),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Your study sessions',
          trailing: IconButton(
            onPressed: reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Text('Could not load your plan: ${snapshot.error}');
              final all = snapshot.data ?? [];
              final sessions = all
                  .where((item) => item['date'] == dateKey(selectedDate))
                  .toList();
              final done = all
                  .where((item) => item['completed'] == true)
                  .length;
              if (sessions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 38),
                      const SizedBox(height: 8),
                      Text('No sessions planned for ${dateKey(selectedDate)}.'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => editSession(),
                        icon: const Icon(Icons.add),
                        label: const Text('Plan this day'),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$done of ${all.length} total sessions completed',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  ...sessions.map((item) {
                    final completed = item['completed'] == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: completed,
                              onChanged: (value) =>
                                  toggle(item, value ?? false),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'].toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      decoration: completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    '${item['subject']} • ${item['startTime']} • ${item['duration']} min',
                                  ),
                                  if ((item['notes']?.toString() ?? '')
                                      .isNotEmpty)
                                    Text(item['notes'].toString()),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      Chip(
                                        label: Text(
                                          item['priority']
                                              .toString()
                                              .toUpperCase(),
                                        ),
                                      ),
                                      if (completed)
                                        const Chip(label: Text('DONE')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') editSession(item);
                                if (value == 'delete') deleteSession(item);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class StudentCommunicationPage extends StatefulWidget {
  final FslmsUser user;
  const StudentCommunicationPage({super.key, required this.user});
  @override
  State<StudentCommunicationPage> createState() =>
      _StudentCommunicationPageState();
}

class _StudentCommunicationPageState extends State<StudentCommunicationPage> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = FslmsApi.getMessages(widget.user.id);
  }

  Future<void> reload() async {
    setState(() => future = FslmsApi.getMessages(widget.user.id));
    try {
      await future;
    } catch (_) {}
  }

  void toast(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> compose() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    String recipient = 'AGT001';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Message a teacher'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: recipient,
                    decoration: const InputDecoration(labelText: 'Recipient'),
                    items: const [
                      DropdownMenuItem(
                        value: 'AGT001',
                        child: Text('FSLMS Teacher (AGT001)'),
                      ),
                      DropdownMenuItem(
                        value: 'AGD001',
                        child: Text('FSLMS Director (AGD001)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialog(() => recipient = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: message,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Your message',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      if (subject.text.trim().isEmpty || message.text.trim().isEmpty) {
        toast('Subject and message are required.');
      } else {
        try {
          await FslmsApi.sendMessage(
            from: widget.user.id,
            to: recipient,
            subject: subject.text.trim(),
            message: message.text.trim(),
          );
          await reload();
          if (mounted) toast('Message sent successfully.');
        } catch (e) {
          if (mounted) toast(e.toString().replaceFirst('Exception: ', ''));
        }
      }
    }
    subject.dispose();
    message.dispose();
  }

  @override
  Widget build(BuildContext context) => FslmsPage(
    title: 'Communication',
    subtitle:
        'Contact your teachers and school director. Messages are saved in your FSLMS inbox.',
    icon: Icons.chat_rounded,
    children: [
      SectionCard(
        title: 'Inbox and sent messages',
        subtitle: 'Refresh to check for replies.',
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: reload,
              tooltip: 'Refresh messages',
              icon: const Icon(Icons.refresh_rounded),
            ),
            FilledButton.icon(
              onPressed: compose,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Compose'),
            ),
          ],
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Text('Could not load messages: ${snapshot.error}');
            final list = snapshot.data ?? [];
            if (list.isEmpty)
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Your inbox is empty. Use Compose to contact a teacher.',
                ),
              );
            return Column(
              children: list.map((m) {
                final incoming = m['to'] == widget.user.id;
                final read = m['read'] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        incoming
                            ? Icons.mark_email_unread_rounded
                            : Icons.mark_email_read_rounded,
                      ),
                    ),
                    title: Text(
                      '${incoming ? 'From' : 'To'}: ${incoming ? (m['fromName'] ?? m['from']) : (m['toName'] ?? m['to'])}',
                      style: TextStyle(
                        fontWeight: incoming && !read
                            ? FontWeight.w900
                            : FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['subject']?.toString() ?? '(No subject)',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(m['message']?.toString() ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            m['date']?.toString() ?? '',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    onTap: incoming && !read
                        ? () async {
                            try {
                              await FslmsApi.markMessageRead(
                                (m['id'] as num).toInt(),
                                widget.user.id,
                              );
                              await reload();
                            } catch (e) {
                              toast(e.toString());
                            }
                          }
                        : null,
                    trailing: incoming && !read
                        ? const Icon(Icons.circle, size: 10)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    ],
  );
}

class StudentNotificationsPage extends StatefulWidget {
  final FslmsUser? user;
  const StudentNotificationsPage({super.key, this.user});
  @override
  State<StudentNotificationsPage> createState() =>
      _StudentNotificationsPageState();
}

class _StudentNotificationsPageState extends State<StudentNotificationsPage> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.user == null
        ? Future.value([])
        : FslmsApi.getNotifications(widget.user!.id);
  }

  @override
  Widget build(BuildContext context) => FslmsPage(
    title: 'Notifications',
    subtitle: 'Updates generated from your assignments and messages.',
    icon: Icons.notifications_rounded,
    children: [
      SectionCard(
        title: 'Recent updates',
        trailing: IconButton(
          onPressed: () => setState(
            () => future = widget.user == null
                ? Future.value([])
                : FslmsApi.getNotifications(widget.user!.id),
          ),
          icon: const Icon(Icons.refresh_rounded),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Text('Could not load notifications: ${snapshot.error}');
            final items = snapshot.data ?? [];
            if (items.isEmpty)
              return const Text(
                'You are all caught up. New assignments and messages will appear here.',
              );
            return Column(
              children: items
                  .map(
                    (n) => ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          n['type'] == 'message'
                              ? Icons.mail_outline_rounded
                              : Icons.assignment_outlined,
                        ),
                      ),
                      title: Text(n['title'].toString()),
                      subtitle: Text('${n['body']}\n${n['date'] ?? ''}'),
                      isThreeLine: true,
                      trailing: Icon(
                        n['read'] == true
                            ? Icons.check_circle_outline
                            : Icons.fiber_new_rounded,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    ],
  );
}

class StudentSettingsPage extends StatelessWidget {
  final FslmsUser? user;
  const StudentSettingsPage({super.key, this.user});
  @override
  Widget build(BuildContext context) => FslmsPage(
    title: 'Student Settings',
    subtitle: 'Your account details and practical help for using FSLMS.',
    icon: Icons.settings_rounded,
    children: [
      SectionCard(
        title: 'Account profile',
        child: Column(
          children: [
            MiniRow(
              icon: Icons.person_rounded,
              title: user?.name ?? 'Student',
              subtitle: 'Display name',
              trailing: 'Profile',
            ),
            const Divider(),
            MiniRow(
              icon: Icons.badge_rounded,
              title: user?.id ?? '—',
              subtitle: 'FSLMS ID',
              trailing: 'ID',
            ),
            const Divider(),
            MiniRow(
              icon: Icons.school_rounded,
              title: 'Student',
              subtitle: 'Account role',
              trailing: 'Role',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SectionCard(
        title: 'Learning preferences',
        subtitle: 'These preferences are currently applied for this session.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appearance'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.light_mode_rounded),
                  label: const Text('Light / dark theme'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Use the theme button in the app sidebar or top bar.',
                        ),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh app data'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Open a screen and use its refresh button to reload backend data.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const SectionCard(
        title: 'Security and privacy',
        child: Text(
          'FSLMS demo accounts currently use a development backend. Do not use a real password here. Password changes and secure sessions must be added to the server before this app is used by a real school.',
        ),
      ),
    ],
  );
}

// ============================================================
// PARENT
// ============================================================

class ParentDashboard extends StatelessWidget {
  final FslmsUser user;

  const ParentDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Family Overview',
      subtitle: 'A clear view of your children’s school progress.',
      icon: Icons.family_restroom_rounded,
      children: [
        const StatsGrid(
          cards: [
            StatCard(
              value: '01',
              label: 'Children',
              icon: Icons.people_rounded,
            ),
            StatCard(
              value: '100%',
              label: 'Attendance',
              icon: Icons.event_available_rounded,
            ),
            StatCard(
              value: 'A+',
              label: 'Average Result',
              icon: Icons.grade_rounded,
            ),
            StatCard(value: '02', label: 'Messages', icon: Icons.forum_rounded),
          ],
        ),
        const SizedBox(height: 18),
        ParentChildrenCard(user: user),
        const SizedBox(height: 18),
        const ParentAlertsCard(),
      ],
    );
  }
}

class ParentChildrenCard extends StatefulWidget {
  final FslmsUser user;

  const ParentChildrenCard({super.key, required this.user});

  @override
  State<ParentChildrenCard> createState() => _ParentChildrenCardState();
}

class _ParentChildrenCardState extends State<ParentChildrenCard> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = FslmsApi.getParentChildren(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Children',
      subtitle: 'Current school status',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Text('Could not load children.');
          }

          final children = snapshot.data ?? [];

          if (children.isEmpty) {
            return const Text('No children linked to this account.');
          }

          return Column(
            children: children.map((child) {
              return MiniRow(
                icon: Icons.school_rounded,
                title: child['name'].toString(),
                subtitle: '${child['grade']} • ${child['id']}',
                trailing: '${child['average']}%',
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class ParentAlertsCard extends StatelessWidget {
  const ParentAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Family alerts',
      child: Column(
        children: [
          MiniRow(
            icon: Icons.event_available_rounded,
            title: 'Attendance',
            subtitle: 'No attendance concerns.',
            trailing: 'Good',
          ),
          MiniRow(
            icon: Icons.assignment_rounded,
            title: 'Assignments',
            subtitle: 'One assignment needs attention.',
            trailing: '1',
          ),
          MiniRow(
            icon: Icons.forum_rounded,
            title: 'Teacher message',
            subtitle: 'New message available.',
            trailing: 'New',
          ),
        ],
      ),
    );
  }
}

class ParentChildrenPage extends StatefulWidget {
  final FslmsUser user;

  const ParentChildrenPage({super.key, required this.user});

  @override
  State<ParentChildrenPage> createState() => _ParentChildrenPageState();
}

class _ParentChildrenPageState extends State<ParentChildrenPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = FslmsApi.getParentChildren(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Children',
      subtitle:
          'Manage and review each child connected to your family account.',
      icon: Icons.people_rounded,
      children: [
        SectionCard(
          title: 'My children',
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Text('Could not load children.');
              }

              final children = snapshot.data ?? [];

              return Column(
                children: children.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ActionTile(
                      title: child['name'].toString(),
                      subtitle: '${child['grade']} • ${child['id']}',
                      icon: Icons.school_rounded,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ParentAttendancePage extends StatelessWidget {
  const ParentAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Attendance',
      subtitle: 'Track attendance patterns for your children.',
      icon: Icons.event_available_rounded,
      children: const [
        StatsGrid(
          cards: [
            StatCard(
              value: '100%',
              label: 'Child One',
              icon: Icons.person_rounded,
            ),
            StatCard(
              value: '100%',
              label: 'Present',
              icon: Icons.check_circle_rounded,
            ),
            StatCard(
              value: '00',
              label: 'Late arrivals',
              icon: Icons.schedule_rounded,
            ),
            StatCard(
              value: '00',
              label: 'Unexcused',
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
        SizedBox(height: 18),
        SectionCard(
          title: 'Recent attendance',
          child: Column(
            children: [
              MiniRow(
                icon: Icons.check_circle_rounded,
                title: 'Child One',
                subtitle: 'Present • Today',
                trailing: 'Present',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ParentResultsPage extends StatelessWidget {
  const ParentResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Results',
      subtitle: 'Review grades and academic performance.',
      icon: Icons.assessment_rounded,
      children: const [
        SectionCard(
          title: 'Academic results',
          child: Column(
            children: [
              MiniRow(
                icon: Icons.calculate_rounded,
                title: 'Mathematics',
                subtitle: 'Dagmawi',
                trailing: 'A+',
              ),
              MiniRow(
                icon: Icons.science_rounded,
                title: 'Science',
                subtitle: 'Dagmawi',
                trailing: 'A+',
              ),
              MiniRow(
                icon: Icons.menu_book_rounded,
                title: 'English',
                subtitle: 'Dagmawi',
                trailing: 'A+',
              ),
              MiniRow(
                icon: Icons.computer_rounded,
                title: 'Computer Science',
                subtitle: 'Dagmawi',
                trailing: 'A+',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ParentMessagesPage extends StatefulWidget {
  final FslmsUser user;

  const ParentMessagesPage({super.key, required this.user});

  @override
  State<ParentMessagesPage> createState() => _ParentMessagesPageState();
}

class _ParentMessagesPageState extends State<ParentMessagesPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = FslmsApi.getMessages(widget.user.id);
  }

  Future<void> sendMessage() async {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      await FslmsApi.sendMessage(
        from: widget.user.id,
        to: 'AGT001',
        subject: subjectController.text.trim(),
        message: messageController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully.')),
      );

      setState(() {
        future = FslmsApi.getMessages(widget.user.id);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Messages',
      subtitle: 'Communicate with teachers and school staff.',
      icon: Icons.forum_rounded,
      children: [
        SectionCard(
          title: 'Family communication',
          trailing: FilledButton.icon(
            onPressed: sendMessage,
            icon: const Icon(Icons.send_rounded),
            label: const Text('New message'),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Text('Could not load messages.');
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return const Text('No messages yet.');
              }

              return Column(
                children: messages.map((message) {
                  return MiniRow(
                    icon: Icons.person_rounded,
                    title: message['from'].toString(),
                    subtitle: message['message'].toString(),
                    trailing: message['date'].toString(),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ParentSettingsPage extends StatelessWidget {
  const ParentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Parent Settings',
      subtitle: 'Manage your family account and communication preferences.',
      icon: Icons.settings_rounded,
      children: const [
        ActionTile(
          title: 'Parent profile',
          subtitle: 'Account and contact information',
          icon: Icons.person_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Family connections',
          subtitle: 'Manage linked children',
          icon: Icons.family_restroom_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Notifications',
          subtitle: 'Choose what updates you receive',
          icon: Icons.notifications_rounded,
        ),
      ],
    );
  }
}

// ============================================================
// TEACHER
// ============================================================

class TeacherDashboard extends StatelessWidget {
  final FslmsUser user;

  const TeacherDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Teaching Center • ${user.name}',
      subtitle: 'Your classes, learners and teaching tasks at a glance.',
      icon: Icons.co_present_rounded,
      children: const [
        StatsGrid(
          cards: [
            StatCard(value: '04', label: 'Classes', icon: Icons.class_rounded),
            StatCard(
              value: '126',
              label: 'Students',
              icon: Icons.groups_rounded,
            ),
            StatCard(
              value: '08',
              label: 'Assignments',
              icon: Icons.assignment_rounded,
            ),
            StatCard(value: '12', label: 'Messages', icon: Icons.forum_rounded),
          ],
        ),
        SizedBox(height: 18),
        TeacherScheduleCard(),
        SizedBox(height: 18),
        TeacherTasksCard(),
      ],
    );
  }
}

class TeacherScheduleCard extends StatelessWidget {
  const TeacherScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Today’s teaching schedule',
      child: Column(
        children: [
          MiniRow(
            icon: Icons.class_rounded,
            title: 'Grade 3 Mathematics',
            subtitle: 'Room 201',
            trailing: '08:00',
          ),
          MiniRow(
            icon: Icons.class_rounded,
            title: 'Grade 5 Mathematics',
            subtitle: 'Room 105',
            trailing: '10:00',
          ),
          MiniRow(
            icon: Icons.groups_rounded,
            title: 'Teacher meeting',
            subtitle: 'Staff room',
            trailing: '14:00',
          ),
        ],
      ),
    );
  }
}

class TeacherTasksCard extends StatelessWidget {
  const TeacherTasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Teaching tasks',
      child: Column(
        children: [
          MiniRow(
            icon: Icons.assignment_rounded,
            title: 'Grade 3 assignments',
            subtitle: 'Review submissions',
            trailing: '12',
          ),
          MiniRow(
            icon: Icons.grading_rounded,
            title: 'Assessment results',
            subtitle: 'Publish results',
            trailing: '04',
          ),
          MiniRow(
            icon: Icons.forum_rounded,
            title: 'Messages',
            subtitle: 'Parent questions',
            trailing: '03',
          ),
        ],
      ),
    );
  }
}

class TeacherClassesPage extends StatelessWidget {
  const TeacherClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'My Classes',
      subtitle: 'View your teaching timetable and class information.',
      icon: Icons.class_rounded,
      children: const [
        ActionTile(
          title: 'Grade 3 Mathematics',
          subtitle: '32 students • Room 201',
          icon: Icons.calculate_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Grade 5 Mathematics',
          subtitle: '29 students • Room 105',
          icon: Icons.calculate_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Grade 6 Mathematics',
          subtitle: '34 students • Room 108',
          icon: Icons.calculate_rounded,
        ),
      ],
    );
  }
}

class TeacherStudentsPage extends StatefulWidget {
  final FslmsUser user;

  const TeacherStudentsPage({super.key, required this.user});

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();

    future = FslmsApi.getTeacherStudents(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Students',
      subtitle: 'Monitor learners in your assigned classes.',
      icon: Icons.groups_rounded,
      children: [
        SectionCard(
          title: 'Connected students',
          subtitle: 'Live data from the FSLMS backend',
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Text('Could not load students.');
              }

              final students = snapshot.data ?? [];

              return Column(
                children: students.map((student) {
                  return MiniRow(
                    icon: Icons.person_rounded,
                    title: student['name'].toString(),
                    subtitle:
                        '${student['grade']} • Attendance ${student['attendance']}%',
                    trailing: '${student['average']}%',
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TeacherAssignmentsPage extends StatefulWidget {
  final FslmsUser user;

  const TeacherAssignmentsPage({super.key, required this.user});

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  late Future<List<Map<String, dynamic>>> studentsFuture;

  @override
  void initState() {
    super.initState();
    studentsFuture = FslmsApi.getTeacherStudents(widget.user.id);
  }

  Future<void> sendAssignment() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();

    String? selectedStudentId;

    final students = await studentsFuture;

    if (!mounted) return;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students are available to receive an assignment.'),
        ),
      );
      return;
    }

    selectedStudentId = students.first['id']?.toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Send assignment'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedStudentId,
                        decoration: const InputDecoration(
                          labelText: 'Student',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        items: students.map((student) {
                          final id = student['id'].toString();
                          final name = student['name'].toString();

                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text('$name • $id'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedStudentId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Assignment title',
                          prefixIcon: Icon(Icons.assignment_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.menu_book_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dueDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Due date',
                          hintText: 'Select a date',
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        onTap: () async {
                          final now = DateTime.now();

                          final picked = await showDatePicker(
                            context: context,
                            firstDate: now,
                            lastDate: DateTime(now.year + 2, 12, 31),
                            initialDate: now,
                          );

                          if (picked != null) {
                            final month = picked.month.toString().padLeft(
                              2,
                              '0',
                            );
                            final day = picked.day.toString().padLeft(2, '0');

                            dueDateController.text =
                                '${picked.year}-$month-$day';
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (selectedStudentId == null ||
                        titleController.text.trim().isEmpty ||
                        subjectController.text.trim().isEmpty ||
                        descriptionController.text.trim().isEmpty ||
                        dueDateController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please complete all assignment fields.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await FslmsApi.sendAssignment(
                        teacherId: widget.user.id,
                        studentId: selectedStudentId!,
                        title: titleController.text.trim(),
                        subject: subjectController.text.trim(),
                        description: descriptionController.text.trim(),
                        dueDate: dueDateController.text.trim(),
                      );

                      if (!mounted) return;

                      Navigator.pop(dialogContext, true);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Assignment sent successfully.'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    subjectController.dispose();
    descriptionController.dispose();
    dueDateController.dispose();

    if (result == true && mounted) {
      setState(() {
        studentsFuture = FslmsApi.getTeacherStudents(widget.user.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Assignments',
      subtitle: 'Create and send assignments directly to your students.',
      icon: Icons.assignment_rounded,
      children: [
        SectionCard(
          title: 'Send assignment',
          subtitle: 'Send a new assignment to a connected student.',
          trailing: FilledButton.icon(
            onPressed: sendAssignment,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send assignment'),
          ),
          child: const Text(
            'Choose a student, add the assignment details and send it. '
            'The student will receive it through the FSLMS backend.',
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Connected students',
          subtitle: 'Students available for assignment delivery',
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: studentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Text('Could not load students.');
              }

              final students = snapshot.data ?? [];

              if (students.isEmpty) {
                return const Text('No connected students.');
              }

              return Column(
                children: students.map((student) {
                  return MiniRow(
                    icon: Icons.person_rounded,
                    title: student['name'].toString(),
                    subtitle: '${student['grade']} • ${student['id']}',
                    trailing: '${student['average']}%',
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TeacherMessagesPage extends StatelessWidget {
  const TeacherMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Messages',
      subtitle: 'Respond to parents, students and school staff.',
      icon: Icons.forum_rounded,
      children: const [
        ActionTile(
          title: 'Parent • Child One',
          subtitle: 'Question about mathematics homework.',
          icon: Icons.family_restroom_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Student • Grade 5',
          subtitle: 'Asked about the next assignment.',
          icon: Icons.school_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'School Director',
          subtitle: 'New staff announcement.',
          icon: Icons.admin_panel_settings_rounded,
        ),
      ],
    );
  }
}

class TeacherSettingsPage extends StatelessWidget {
  const TeacherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Teacher Settings',
      subtitle: 'Manage your teaching profile and preferences.',
      icon: Icons.settings_rounded,
      children: const [
        ActionTile(
          title: 'Teacher profile',
          subtitle: 'Name, ID and subjects',
          icon: Icons.person_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Class preferences',
          subtitle: 'Teaching and grading options',
          icon: Icons.tune_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Notifications',
          subtitle: 'Messages and assignment alerts',
          icon: Icons.notifications_rounded,
        ),
      ],
    );
  }
}

// ============================================================
// DIRECTOR
// ============================================================

class DirectorDashboard extends StatefulWidget {
  final FslmsUser user;

  const DirectorDashboard({super.key, required this.user});

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();

    future = FslmsApi.getDirectorDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'School Command Center',
      subtitle: 'A high-level view of school operations and performance.',
      icon: Icons.admin_panel_settings_rounded,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const StatsGrid(
                cards: [
                  StatCard(
                    value: '—',
                    label: 'Students',
                    icon: Icons.school_rounded,
                  ),
                  StatCard(
                    value: '—',
                    label: 'Teachers',
                    icon: Icons.co_present_rounded,
                  ),
                  StatCard(
                    value: '—',
                    label: 'Attendance',
                    icon: Icons.event_available_rounded,
                  ),
                  StatCard(
                    value: '—',
                    label: 'Average Grade',
                    icon: Icons.grade_rounded,
                  ),
                ],
              );
            }

            final data = snapshot.data ?? {};

            return StatsGrid(
              cards: [
                StatCard(
                  value: '${data['totalStudents'] ?? 0}',
                  label: 'Students',
                  icon: Icons.school_rounded,
                ),
                StatCard(
                  value: '${data['totalTeachers'] ?? 0}',
                  label: 'Teachers',
                  icon: Icons.co_present_rounded,
                ),
                StatCard(
                  value: '${data['averageAttendance'] ?? 0}%',
                  label: 'Attendance',
                  icon: Icons.event_available_rounded,
                ),
                StatCard(
                  value: '${data['averageGrade'] ?? 0}%',
                  label: 'Average Grade',
                  icon: Icons.grade_rounded,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const DirectorOperationsCard(),
        const SizedBox(height: 18),
        const DirectorPerformanceCard(),
      ],
    );
  }
}

class DirectorOperationsCard extends StatelessWidget {
  const DirectorOperationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'School operations',
      subtitle: 'Items requiring attention',
      child: Column(
        children: [
          MiniRow(
            icon: Icons.analytics_rounded,
            title: 'Attendance report',
            subtitle: 'Review weekly attendance',
            trailing: 'Open',
          ),
          MiniRow(
            icon: Icons.people_rounded,
            title: 'Student records',
            subtitle: '4 records need review',
            trailing: '04',
          ),
          MiniRow(
            icon: Icons.campaign_rounded,
            title: 'Announcement',
            subtitle: 'Draft school notice',
            trailing: 'Draft',
          ),
        ],
      ),
    );
  }
}

class DirectorPerformanceCard extends StatelessWidget {
  const DirectorPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'School performance',
      child: Column(
        children: [
          ProgressLine(title: 'Attendance', value: .94),
          SizedBox(height: 20),
          ProgressLine(title: 'Assignment completion', value: .87),
          SizedBox(height: 20),
          ProgressLine(title: 'Teacher activity', value: .91),
        ],
      ),
    );
  }
}

class DirectorStudentsPage extends StatelessWidget {
  const DirectorStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Students',
      subtitle: 'Manage school-wide student records and activity.',
      icon: Icons.school_rounded,
      children: const [
        StatsGrid(
          cards: [
            StatCard(
              value: '482',
              label: 'Total students',
              icon: Icons.people_rounded,
            ),
            StatCard(
              value: '16',
              label: 'Grade groups',
              icon: Icons.class_rounded,
            ),
            StatCard(
              value: '94%',
              label: 'Attendance',
              icon: Icons.event_available_rounded,
            ),
            StatCard(
              value: '07',
              label: 'Pending records',
              icon: Icons.pending_actions_rounded,
            ),
          ],
        ),
        SizedBox(height: 18),
        SectionCard(
          title: 'Recent student activity',
          child: Column(
            children: [
              MiniRow(
                icon: Icons.person_add_rounded,
                title: 'New student record',
                subtitle: 'Registration completed',
                trailing: 'Today',
              ),
              MiniRow(
                icon: Icons.edit_rounded,
                title: 'Profile update',
                subtitle: 'Student information changed',
                trailing: '1h',
              ),
              MiniRow(
                icon: Icons.warning_amber_rounded,
                title: 'Record review',
                subtitle: 'Missing information',
                trailing: '3',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DirectorTeachersPage extends StatelessWidget {
  const DirectorTeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Teachers',
      subtitle: 'Monitor staff activity, classes and teaching workload.',
      icon: Icons.co_present_rounded,
      children: const [
        StatsGrid(
          cards: [
            StatCard(
              value: '36',
              label: 'Teachers',
              icon: Icons.people_rounded,
            ),
            StatCard(
              value: '31',
              label: 'Active today',
              icon: Icons.online_prediction_rounded,
            ),
            StatCard(
              value: '04',
              label: 'On leave',
              icon: Icons.event_busy_rounded,
            ),
            StatCard(
              value: '01',
              label: 'Pending review',
              icon: Icons.pending_actions_rounded,
            ),
          ],
        ),
        SizedBox(height: 18),
        SectionCard(
          title: 'Staff activity',
          child: Column(
            children: [
              MiniRow(
                icon: Icons.co_present_rounded,
                title: 'Mathematics department',
                subtitle: 'Assignments updated',
                trailing: 'Active',
              ),
              MiniRow(
                icon: Icons.co_present_rounded,
                title: 'Science department',
                subtitle: 'Results submitted',
                trailing: 'Active',
              ),
              MiniRow(
                icon: Icons.co_present_rounded,
                title: 'English department',
                subtitle: 'Planning in progress',
                trailing: 'Active',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DirectorReportsPage extends StatelessWidget {
  const DirectorReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Reports',
      subtitle: 'Review school-wide performance and operational reports.',
      icon: Icons.analytics_rounded,
      children: const [
        ActionTile(
          title: 'Attendance report',
          subtitle: 'Weekly attendance across the school',
          icon: Icons.event_available_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Academic performance',
          subtitle: 'Grades and assessment trends',
          icon: Icons.bar_chart_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Teacher activity',
          subtitle: 'Teaching and assignment activity',
          icon: Icons.co_present_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'Enrollment report',
          subtitle: 'Student enrollment overview',
          icon: Icons.people_rounded,
        ),
      ],
    );
  }
}

class DirectorAnnouncementsPage extends StatelessWidget {
  const DirectorAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Announcements',
      subtitle: 'Publish important information to the school community.',
      icon: Icons.campaign_rounded,
      children: [
        SectionCard(
          title: 'Recent announcements',
          trailing: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('New'),
          ),
          child: const Column(
            children: [
              MiniRow(
                icon: Icons.campaign_rounded,
                title: 'School activity notice',
                subtitle: 'Visible to students and parents',
                trailing: 'Published',
              ),
              MiniRow(
                icon: Icons.campaign_rounded,
                title: 'Teacher meeting',
                subtitle: 'Visible to teachers',
                trailing: 'Published',
              ),
              MiniRow(
                icon: Icons.edit_note_rounded,
                title: 'Term reminder',
                subtitle: 'Draft announcement',
                trailing: 'Draft',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DirectorSettingsPage extends StatelessWidget {
  const DirectorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FslmsPage(
      title: 'Director Settings',
      subtitle: 'Configure school administration preferences.',
      icon: Icons.settings_rounded,
      children: const [
        ActionTile(
          title: 'School profile',
          subtitle: 'School information and branding',
          icon: Icons.business_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'User management',
          subtitle: 'Students, parents and staff access',
          icon: Icons.manage_accounts_rounded,
        ),
        SizedBox(height: 12),
        ActionTile(
          title: 'System preferences',
          subtitle: 'FSLMS configuration options',
          icon: Icons.tune_rounded,
        ),
      ],
    );
  }
}
