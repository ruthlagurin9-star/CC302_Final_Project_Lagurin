import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PlanningApp());
}

const primary = Color(0xFF3157D5);
const background = Color(0xFFF5F7FC);
const ink = Color(0xFF202A44);

class Task {
  final int id;
  String title;
  String description;
  String category;
  DateTime dueDate;
  bool completed;
  bool selected;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    required this.dueDate,
    this.completed = false,
    this.selected = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled task',
      completed: json['completed'] as bool? ?? false,
      dueDate: DateTime.now(),
      category: 'General',
    );
  }
}

class TaskApi {
  const TaskApi();

  static const url = 'https://jsonplaceholder.typicode.com/todos';

  Future<List<Task>> fetchTasks() async {
    final response = await http
        .get(Uri.parse('$url?_limit=12'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Unable to load tasks');
    }

    final List data = jsonDecode(response.body);
    return data
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteTask(int id) async {
    final response = await http
        .delete(Uri.parse('$url/$id'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Unable to delete task');
    }
  }
}

class _Account {
  final String name;
  final String email;
  final String password;
  Uint8List? profilePhoto;

  _Account({required this.name, required this.email, required this.password});
}

typedef AuthSubmit =
    Future<String?> Function({
      required bool createAccount,
      required String name,
      required String email,
      required String password,
    });

class AuthPage extends StatefulWidget {
  final AuthSubmit onSubmit;

  const AuthPage({super.key, required this.onSubmit});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool creatingAccount = false;
  bool obscurePassword = true;
  bool submitting = false;
  String? error;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final result = await widget.onSubmit(
        createAccount: creatingAccount,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (mounted) setState(() => error = result);
    } catch (exception) {
      if (mounted) setState(() => error = 'Could not sign in: $exception');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = creatingAccount ? 'Create your account' : 'Welcome back';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFFE5EBFF),
                      child: Icon(Icons.event_note, color: primary, size: 34),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Planora',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ink,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A little planning goes a long way.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      creatingAccount
                          ? 'Create an account to start planning.'
                          : 'Sign in to continue to your planner.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 22),
                    if (creatingAccount) ...[
                      TextFormField(
                        key: const Key('auth-name'),
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            creatingAccount &&
                                (value == null || value.trim().isEmpty)
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      key: const Key('auth-email'),
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (!email.contains('@') ||
                            !email
                                .substring(email.indexOf('@') + 1)
                                .contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('auth-password'),
                      controller: passwordController,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => (value?.length ?? 0) < 6
                          ? 'Use at least 6 characters'
                          : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: submitting ? null : submit,
                        child: submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                creatingAccount ? 'Create account' : 'Sign in',
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: submitting
                          ? null
                          : () => setState(() {
                              creatingAccount = !creatingAccount;
                              error = null;
                            }),
                      child: Text(
                        creatingAccount
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Demo accounts are kept only while the app is open.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlanningApp extends StatelessWidget {
  final TaskApi api;

  const PlanningApp({super.key, this.api = const TaskApi()});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Planora',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
          toolbarHeight: 60,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 70,
          backgroundColor: Colors.white,
          indicatorColor: primary.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
            );
          }),
        ),
      ),
      home: PlannerHome(api: api),
    );
  }
}

class PlannerHome extends StatefulWidget {
  final TaskApi api;

  const PlannerHome({super.key, this.api = const TaskApi()});

  @override
  State<PlannerHome> createState() => _PlannerHomeState();
}

class _PlannerHomeState extends State<PlannerHome> {
  final searchController = TextEditingController();
  final imagePicker = ImagePicker();
  final imageCropper = ImageCropper();

  final Map<String, _Account> accounts = {};
  final List<Task> tasks = [];
  _Account? currentAccount;
  bool loading = true;
  String? error;
  int tab = 0;
  String search = '';
  String filter = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadTasks() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await widget.api.fetchTasks();
      if (!mounted) return;
      setState(() {
        tasks
          ..clear()
          ..addAll(result);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not connect to the task API.';
      });
    }
  }

  Future<String?> authenticate({
    required bool createAccount,
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final preferences = await SharedPreferences.getInstance();
    final savedPhoto = preferences.getString(
      _photoPreferenceKey(normalizedEmail),
    );
    final Uint8List? photo = savedPhoto == null
        ? null
        : base64Decode(savedPhoto);

    if (createAccount) {
      if (accounts.containsKey(normalizedEmail)) {
        return 'An account with this email already exists.';
      }

      final account = _Account(
        name: name.trim(),
        email: normalizedEmail,
        password: password,
      )..profilePhoto = photo;
      accounts[normalizedEmail] = account;
      setState(() => currentAccount = account);
    } else {
      final account = accounts[normalizedEmail];
      if (account == null || account.password != password) {
        return 'Email or password is incorrect.';
      }
      account.profilePhoto = photo ?? account.profilePhoto;
      setState(() => currentAccount = account);
    }

    loadTasks();
    return null;
  }

  Future<void> logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      currentAccount = null;
      tasks.clear();
      loading = false;
      error = null;
      tab = 0;
      search = '';
      filter = 'All';
      searchController.clear();
    });
  }

  Future<void> changeProfilePhoto() async {
    try {
      final pickedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (pickedImage == null || !mounted) return;

      final List<PlatformUiSettings> cropSettings;
      if (kIsWeb) {
        cropSettings = [WebUiSettings(context: context)];
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        cropSettings = [
          AndroidUiSettings(
            toolbarTitle: 'Resize profile photo',
            toolbarColor: primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
        ];
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        cropSettings = [IOSUiSettings(title: 'Resize profile photo')];
      } else {
        message('Photo resizing is available on Android, iOS, and web.');
        return;
      }

      final croppedImage = await imageCropper.cropImage(
        sourcePath: pickedImage.path,
        maxWidth: 512,
        maxHeight: 512,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        uiSettings: cropSettings,
      );
      if (croppedImage == null || !mounted) return;

      final photoBytes = await croppedImage.readAsBytes();
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _photoPreferenceKey(currentAccount!.email),
        base64Encode(photoBytes),
      );
      if (!saved) {
        throw StateError('The photo could not be saved on this device.');
      }
      setState(() => currentAccount?.profilePhoto = photoBytes);
      message('Profile photo saved.');
    } catch (error) {
      if (!mounted) return;
      message('Could not update profile photo: $error');
    }
  }

  Future<void> removeProfilePhoto() async {
    final account = currentAccount;
    if (account == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_photoPreferenceKey(account.email));
      if (!mounted || currentAccount != account) return;

      setState(() => account.profilePhoto = null);
      message('Profile photo removed.');
    } catch (error) {
      if (mounted) message('Could not remove profile photo: $error');
    }
  }

  String _photoPreferenceKey(String email) =>
      'profile_photo_${Uri.encodeComponent(email.toLowerCase())}';

  List<Task> get filteredTasks {
    return tasks.where((task) {
      final matchesSearch =
          task.title.toLowerCase().contains(search.toLowerCase()) ||
          task.category.toLowerCase().contains(search.toLowerCase());

      final matchesFilter =
          filter == 'All' ||
          (filter == 'Completed' && task.completed) ||
          (filter == 'Pending' && !task.completed);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get completedCount => tasks.where((t) => t.completed).length;
  int get pendingCount => tasks.where((t) => !t.completed).length;

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> showTaskForm({Task? task}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(
      text: task?.description ?? '',
    );

    String category = task?.category ?? 'Personal';
    DateTime dueDate = task?.dueDate ?? DateTime.now();

    final result = await showDialog<Task>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? 'Add Task' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a task title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Personal',
                        child: Text('Personal'),
                      ),
                      DropdownMenuItem(value: 'Study', child: Text('Study')),
                      DropdownMenuItem(value: 'Work', child: Text('Work')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(
                  dialogContext,
                  Task(
                    id: task?.id ?? -DateTime.now().millisecondsSinceEpoch,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    category: category,
                    dueDate: dueDate,
                    completed: task?.completed ?? false,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    descriptionController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (task == null) {
        tasks.insert(0, result);
      } else {
        final index = tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) tasks[index] = result;
      }
    });

    message(task == null ? 'Task added.' : 'Task updated.');
  }

  void toggleTask(Task task, bool? value) {
    setState(() => task.completed = value ?? false);
  }

  void selectAll() {
    final visible = filteredTasks;
    if (visible.isEmpty) return;

    final select = !visible.every((task) => task.selected);

    setState(() {
      for (final task in visible) {
        task.selected = select;
      }
    });

    message(select ? 'All visible tasks selected.' : 'Selection cleared.');
  }

  Future<void> deleteTasks(List<Task> selected) async {
    if (selected.isEmpty) {
      message('Select at least one task first.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete tasks?'),
        content: Text(
          'Delete ${selected.length} selected task(s)? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final failures = <Task>[];

    for (final task in selected) {
      if (task.id > 0) {
        try {
          await widget.api.deleteTask(task.id);
        } catch (_) {
          failures.add(task);
        }
      }
    }

    if (!mounted) return;

    setState(() {
      tasks.removeWhere(
        (task) => selected.contains(task) && !failures.contains(task),
      );
    });

    message(
      failures.isEmpty
          ? 'Selected tasks removed from the list.'
          : 'Some API deletions failed. Failed tasks were kept.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentAccount == null) {
      return AuthPage(onSubmit: authenticate);
    }

    final pages = [
      homePage(),
      schedulePage(),
      tasksPage(),
      progressPage(),
      profilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.event_note, color: primary, size: 28),
            SizedBox(width: 8),
            Text('Planora', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh tasks',
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: tab == 2
          ? FloatingActionButton.extended(
              onPressed: () => showTaskForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primary, Color(0xFF6988F0)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR DAY, ORGANIZED',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              const Text(
                'Plan your day.\nAchieve your goals.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                ),
                onPressed: () {
                  setState(() => tab = 2);
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('View My Tasks'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Today at a glance'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Tasks',
                value: '${tasks.length}',
                icon: Icons.task_alt,
                color: primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Pending',
                value: '$pendingCount',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          title: 'Completed Tasks',
          value: '$completedCount',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const SectionTitle('Upcoming tasks'),
        const SizedBox(height: 10),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          ErrorView(message: error!, onRetry: loadTasks)
        else if (tasks.isEmpty)
          const Text('No tasks yet. Add your first task.')
        else
          ...tasks
              .where((t) => !t.completed)
              .take(4)
              .map(
                (task) => TaskTile(
                  task: task,
                  onChanged: (value) => toggleTask(task, value),
                  onEdit: () => showTaskForm(task: task),
                  onDelete: () => deleteTasks([task]),
                ),
              ),
      ],
    );
  }

  Widget schedulePage() {
    final pending = tasks.where((t) => !t.completed).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SectionTitle('My Schedule'),
        const SizedBox(height: 6),
        const Text('Your upcoming tasks and plans.'),
        const SizedBox(height: 18),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          ErrorView(message: error!, onRetry: loadTasks)
        else if (pending.isEmpty)
          const Text('You have no pending tasks.')
        else
          ...pending.map(
            (task) => TaskTile(
              task: task,
              onChanged: (value) => toggleTask(task, value),
              onEdit: () => showTaskForm(task: task),
              onDelete: () => deleteTasks([task]),
            ),
          ),
      ],
    );
  }

  Widget tasksPage() {
    final visible = filteredTasks;
    final allSelected =
        visible.isNotEmpty && visible.every((task) => task.selected);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: (value) => setState(() => search = value),
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() => search = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['All', 'Pending', 'Completed'].map((value) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(value),
                  selected: filter == value,
                  onSelected: (_) => setState(() => filter = value),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text('${visible.length} tasks'),
              const Spacer(),
              TextButton.icon(
                onPressed: selectAll,
                icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
                label: Text(allSelected ? 'Deselect All' : 'Select All'),
              ),
              IconButton(
                tooltip: 'Delete selected tasks',
                onPressed: () =>
                    deleteTasks(tasks.where((t) => t.selected).toList()),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? ErrorView(message: error!, onRetry: loadTasks)
              : visible.isEmpty
              ? const Center(child: Text('No tasks found. Add a new task!'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final task = visible[index];
                    return TaskTile(
                      task: task,
                      onChanged: (value) => toggleTask(task, value),
                      onEdit: () => showTaskForm(task: task),
                      onDelete: () => deleteTasks([task]),
                      showSelection: true,
                      onSelected: (value) =>
                          setState(() => task.selected = value ?? false),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget progressPage() {
    final total = tasks.length;
    final completed = completedCount;
    final ratio = total == 0 ? 0.0 : completed / total;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SectionTitle('Your Progress'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 12,
                      backgroundColor: const Color(0xFFE6EAF4),
                    ),
                    Center(
                      child: Text(
                        '${(ratio * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Tasks completed', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 6),
              Text('$completed out of $total tasks'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StatCard(
          title: 'Pending Tasks',
          value: '$pendingCount',
          icon: Icons.hourglass_bottom,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        StatCard(
          title: 'Completed Tasks',
          value: '$completedCount',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget profilePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 15),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                key: const Key('profile-avatar'),
                radius: 56,
                backgroundColor: const Color(0xFFDDE5FF),
                backgroundImage: currentAccount!.profilePhoto == null
                    ? null
                    : MemoryImage(currentAccount!.profilePhoto!),
                child: currentAccount!.profilePhoto == null
                    ? const Icon(Icons.person, size: 62, color: primary)
                    : null,
              ),
              Material(
                color: primary,
                shape: const CircleBorder(),
                child: IconButton(
                  key: const Key('change-profile-photo'),
                  tooltip: 'Choose and resize profile photo',
                  onPressed: changeProfilePhoto,
                  color: Colors.white,
                  icon: const Icon(Icons.edit),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'Tap the edit icon to change and resize your photo',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        if (currentAccount!.profilePhoto != null)
          Center(
            child: TextButton(
              onPressed: removeProfilePhoto,
              child: const Text('Remove photo'),
            ),
          ),
        Center(
          child: Text(
            currentAccount!.name,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
        ),
        Center(
          child: Text(
            currentAccount!.email,
            style: TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle('Account'),
        const SizedBox(height: 12),
        const ProfileOption(
          icon: Icons.person_outline,
          title: 'Personal Information',
          subtitle: 'Your profile details',
        ),
        const ProfileOption(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Task reminders and updates',
        ),
        const ProfileOption(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Application theme',
        ),
        const ProfileOption(
          icon: Icons.info_outline,
          title: 'About Planora',
          subtitle: 'Planning & Scheduling System',
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => showAboutDialog(
            context: context,
            applicationName: 'Planora',
            applicationVersion: '1.0.0',
            children: const [
              Text('A Flutter Planning & Scheduling System project.'),
            ],
          ),
          icon: const Icon(Icons.info_outline),
          label: const Text('About the application'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: logOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade200),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showSelection;
  final ValueChanged<bool?>? onSelected;

  const TaskTile({
    super.key,
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    this.showSelection = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            if (showSelection)
              Checkbox(value: task.selected, onChanged: onSelected),
            Checkbox(
              value: task.completed,
              onChanged: onChanged,
              activeColor: primary,
            ),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completed ? Colors.grey : ink,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${task.category} • Due ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                        style: const TextStyle(fontSize: 11, color: primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 45, color: Colors.red),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
