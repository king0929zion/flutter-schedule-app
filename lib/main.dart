import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SchedulePrototypeApp());
}

class SchedulePrototypeApp extends StatelessWidget {
  const SchedulePrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedule App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFE8E8E3),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111111)),
      ),
      home: const ScheduleHomePage(),
    );
  }
}

enum ViewMode { today, calendar }

enum TaskType { timed, allday, todo, note }

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.category,
    required this.theme,
    this.start,
    this.end,
    this.pillText = '',
    this.subtitle = '',
    this.avatars = const [],
    this.images = const [],
    this.completed = false,
  });

  final int id;
  final String title;
  final String date;
  final String? start;
  final String? end;
  final String pillText;
  final String theme;
  final List<int> avatars;
  final String subtitle;
  final String category;
  final TaskType type;
  final List<String> images;
  final bool completed;

  TaskItem copyWith({
    int? id,
    String? title,
    String? date,
    String? start,
    bool clearStart = false,
    String? end,
    bool clearEnd = false,
    String? pillText,
    String? theme,
    List<int>? avatars,
    String? subtitle,
    String? category,
    TaskType? type,
    List<String>? images,
    bool? completed,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      start: clearStart ? null : start ?? this.start,
      end: clearEnd ? null : end ?? this.end,
      pillText: pillText ?? this.pillText,
      theme: theme ?? this.theme,
      avatars: avatars ?? this.avatars,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      type: type ?? this.type,
      images: images ?? this.images,
      completed: completed ?? this.completed,
    );
  }
}

class ThemeSpec {
  const ThemeSpec({required this.bg, required this.fg, required this.pill});

  final Color bg;
  final Color fg;
  final Color pill;
}

class ScheduleHomePage extends StatefulWidget {
  const ScheduleHomePage({super.key});

  @override
  State<ScheduleHomePage> createState() => _ScheduleHomePageState();
}

class _ScheduleHomePageState extends State<ScheduleHomePage> {
  static const String todayDate = '2024-12-13';

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _subtitleCtrl = TextEditingController();
  final TextEditingController _pillCtrl = TextEditingController();
  final TextEditingController _aiPromptCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late final Timer _clockTimer;
  ViewMode _view = ViewMode.today;
  String _nyClock = '1:20 PM';
  String _ukClock = '6:20 PM';

  bool _showContext = false;
  bool _taskModalOpen = false;
  bool _aiModalOpen = false;
  bool _aiLoading = false;
  TaskItem? _aiGenerated;
  int? _editingId;
  String _currentAddKind = 'text';
  String _attachedImageName = '';
  String _toastText = '';
  bool _toastVisible = false;
  Timer? _toastTimer;

  TaskType _formType = TaskType.timed;
  String _formDate = todayDate;
  String _formStart = '10:00';
  String _formEnd = '11:00';
  String _formCategory = 'work';

  final List<TaskItem> _tasks = [
    TaskItem(
      id: 1,
      title: 'Product Sync',
      date: '2024-12-13',
      start: '10:00',
      end: '11:00',
      pillText: '1 Hour',
      theme: 'gold',
      avatars: [68, 32],
      subtitle: 'Weekly team standup',
      category: 'work',
      type: TaskType.timed,
    ),
    TaskItem(
      id: 2,
      title: 'Lunch with Sarah',
      date: '2024-12-13',
      start: '12:00',
      end: '13:30',
      pillText: '90 Min',
      theme: 'sage',
      avatars: [45, 12],
      subtitle: 'Italian restaurant',
      category: 'personal',
      type: TaskType.timed,
    ),
    TaskItem(
      id: 7,
      title: 'Team off-site',
      date: '2024-12-13',
      pillText: 'All Day',
      theme: 'sky',
      avatars: [8, 19, 3],
      subtitle: 'Company retreat at lakeside',
      category: 'work',
      type: TaskType.allday,
    ),
    TaskItem(
      id: 3,
      title: 'Final Exam',
      date: '2024-12-14',
      start: '09:00',
      end: '11:00',
      pillText: '2 Hours',
      theme: 'rose',
      avatars: [15, 22],
      subtitle: 'CS101 - Auditorium A',
      category: 'study',
      type: TaskType.timed,
    ),
    TaskItem(
      id: 4,
      title: 'Dentist',
      date: '2024-12-14',
      start: '14:30',
      end: '15:00',
      pillText: '30 Min',
      theme: 'gold',
      avatars: [41],
      subtitle: 'Dr. Lee Clinic',
      category: 'personal',
      type: TaskType.timed,
    ),
    TaskItem(
      id: 5,
      title: 'Flight CA1834',
      date: '2024-12-15',
      start: '16:20',
      end: '03:45',
      pillText: '13h 25m',
      theme: 'sky',
      avatars: [8, 19],
      subtitle: 'Beijing -> NYC',
      category: 'travel',
      type: TaskType.timed,
    ),
    TaskItem(
      id: 6,
      title: 'Buy Groceries',
      date: '2024-12-15',
      start: '17:00',
      pillText: 'To-do',
      theme: 'sage',
      avatars: [5],
      subtitle: 'Milk, Eggs, Bread',
      category: 'personal',
      type: TaskType.todo,
    ),
    TaskItem(
      id: 8,
      title: 'Book recommendations',
      date: '2024-12-13',
      pillText: 'Note',
      theme: 'rose',
      subtitle: 'Atomic Habits, Deep Work, Building a Second Brain - collect quotes and highlights for next reading list.',
      category: 'personal',
      type: TaskType.note,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateClocks();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClocks());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _toastTimer?.cancel();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _pillCtrl.dispose();
    _aiPromptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E3),
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: LiquidBackdrop()),
          Positioned.fill(child: _buildActiveView()),
          _buildContextOverlay(),
          _buildTaskModal(),
          _buildAiModal(),
          _buildToastBubble(),
        ],
      ),
    );
  }

  Widget _buildActiveView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _view == ViewMode.today ? _todayView(key: const ValueKey('today')) : _calendarView(key: const ValueKey('calendar')),
    );
  }

  Widget _todayView({Key? key}) {
    final todayTasks = _tasks.where((t) => t.date == todayDate).toList()..sort(_sortTasks);
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          _navBar(ViewMode.today),
          const SizedBox(height: 18),
          _hero(),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Todays tasks',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Color(0xFF111111)),
                      ),
                      TapScale(
                        onTap: () => _toast('Reminders (demo)'),
                        child: const LiquidGlassSurface(
                          borderRadius: 999,
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          tint: Color(0x66FFFFFF),
                          borderColor: Color(0x55FFFFFF),
                          child: Text('Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: todayTasks.isEmpty
                        ? const Center(child: Text('Nothing scheduled today.', style: TextStyle(color: Color(0x66000000), fontWeight: FontWeight.w500)))
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            itemCount: todayTasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => FadeUp(
                              delay: Duration(milliseconds: 100 + index * 50),
                              child: _taskCard(todayTasks[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarView({Key? key}) {
    final dates = _tasks.map((t) => t.date).toSet().toList()..sort();
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          _navBar(ViewMode.calendar),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text('NOV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0x33000000), letterSpacing: 1)),
              SizedBox(width: 14),
              Text('DEC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111), letterSpacing: 0.5)),
              SizedBox(width: 14),
              Text('JAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0x33000000), letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: dates.isEmpty
                ? const Center(child: Text('No upcoming events.', style: TextStyle(color: Color(0x66000000), fontWeight: FontWeight.w500)))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 28),
                    physics: const BouncingScrollPhysics(),
                    itemCount: math.min(dates.length, 6),
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final dayTasks = _tasks.where((t) => t.date == date).toList()..sort(_sortCalendarTasks);
                      return FadeUp(
                        delay: Duration(milliseconds: index * 50),
                        child: _calendarDayCard(date, dayTasks),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _navBar(ViewMode active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _chip('Today', active == ViewMode.today, () => _switchView(ViewMode.today)),
              const SizedBox(width: 9),
              _chip('Calendar', active == ViewMode.calendar, () => _switchView(ViewMode.calendar)),
            ],
          ),
          GestureDetector(
            onTap: () => _openAdd('text'),
            onLongPress: _showAddContext,
            child: const TapScale(
              child: LiquidGlassSurface(
                width: 48,
                height: 48,
                borderRadius: 999,
                tint: Color(0x66FFFFFF),
                borderColor: Color(0x66FFFFFF),
                shadow: true,
                child: Icon(Icons.add, size: 22, color: Color(0xFF1A1A1A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: LiquidGlassSurface(
        borderRadius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        tint: active ? const Color(0xE6111111) : const Color(0x22FFFFFF),
        borderColor: active ? const Color(0x33111111) : const Color(0x33000000),
        shadow: active,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: -0.2,
            color: active ? Colors.white : const Color(0xFF111111),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: const [
              Text('Tuesday', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0x66000000), letterSpacing: 1)),
              SizedBox(height: 8),
              Text('13.12', style: TextStyle(fontSize: 54, fontWeight: FontWeight.w800, height: 0.95, letterSpacing: -2, color: Color(0xFF111111))),
              SizedBox(height: 4),
              Text('DEC', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1, letterSpacing: -0.5, color: Color(0xFF111111))),
            ],
          ),
          const SizedBox(width: 32),
          Container(width: 1, height: 90, decoration: BoxDecoration(color: const Color(0x1F000000), borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _clockBlock(_nyClock, 'New York'),
              const SizedBox(height: 16),
              _clockBlock(_ukClock, 'United Kingdom'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clockBlock(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.3, color: Color(0xFF111111))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.5, color: Color(0x61000000))),
      ],
    );
  }

  Widget _taskCard(TaskItem task) {
    final spec = _themeFor(task.theme);
    final cfg = _typeConfig(task.type);
    return TapScale(
      onTap: () => _openEdit(task),
      pressedScale: 0.985,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: spec.bg, borderRadius: BorderRadius.circular(32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          LiquidGlassSurface(
                            width: 26,
                            height: 26,
                            borderRadius: 8,
                            tint: Colors.white.withOpacity(0.16),
                            borderColor: Colors.white.withOpacity(0.18),
                            child: Icon(cfg.icon, size: 17, color: spec.fg),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.4, color: spec.fg),
                            ),
                          ),
                        ],
                      ),
                      if (task.subtitle.isNotEmpty && task.type != TaskType.note) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: spec.fg.withOpacity(0.6)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.avatars.isNotEmpty) _avatars(task.avatars),
              ],
            ),
            const SizedBox(height: 20),
            _cardFooter(task, spec),
          ],
        ),
      ),
    );
  }

  Widget _avatars(List<int> avatars) {
    return SizedBox(
      height: 42,
      width: 38 + math.max(0, avatars.length - 1) * 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < avatars.length; i++)
            Positioned(
              left: i * 28,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 1)],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://i.pravatar.cc/100?img=${avatars[i]}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFDDDDDD)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardFooter(TaskItem task, ThemeSpec spec) {
    switch (task.type) {
      case TaskType.allday:
        return SizedBox(
          width: double.infinity,
          child: Center(child: _pill(task.pillText.isEmpty ? 'All Day' : task.pillText, spec)),
        );
      case TaskType.todo:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _timeColumn(task.start == null ? 'Anytime' : _fmtTime(task.start!), task.start == null ? 'No deadline' : 'Due', spec.fg),
            const Spacer(),
            _pill(task.pillText.isEmpty ? 'To-do' : task.pillText, spec),
            const SizedBox(width: 14),
            TapScale(
              onTap: () => _toggleTodo(task.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? Colors.black.withOpacity(0.18) : Colors.transparent,
                  border: task.completed ? null : Border.all(color: Colors.black.withOpacity(0.25), width: 2.5),
                ),
                child: task.completed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              ),
            ),
          ],
        );
      case TaskType.note:
        return Text(
          task.subtitle.isEmpty ? 'No additional details' : task.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4, color: spec.fg.withOpacity(0.6)),
        );
      case TaskType.timed:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _timeColumn(_fmtTime(task.start ?? '10:00'), 'Start', spec.fg),
            const Spacer(),
            _pill(task.pillText, spec),
            const Spacer(),
            _timeColumn(_fmtTime(task.end ?? '11:00'), 'End', spec.fg, alignEnd: true),
          ],
        );
    }
  }

  Widget _timeColumn(String main, String sub, Color color, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(main, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1, letterSpacing: -0.3, color: color)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withOpacity(0.5))),
      ],
    );
  }

  Widget _pill(String text, ThemeSpec spec) {
    return LiquidGlassSurface(
      borderRadius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      tint: spec.pill.withOpacity(0.82),
      borderColor: Colors.white.withOpacity(0.14),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1, color: Colors.white)),
    );
  }

  Widget _calendarDayCard(String date, List<TaskItem> tasks) {
    final d = DateTime.parse('${date}T00:00:00');
    final dayName = _weekdayName(d.weekday);
    final dayNum = d.day.toString();
    final month = _monthName(d.month).toUpperCase();
    final firstTheme = tasks.isEmpty ? 'gold' : tasks.first.theme;
    final cal = _calendarTheme(firstTheme);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: cal.bg, borderRadius: BorderRadius.circular(32)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cal.fg.withOpacity(0.7), letterSpacing: 1)),
                const SizedBox(height: 1),
                Text(dayNum, style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, height: 0.88, letterSpacing: -1.2, color: cal.fg)),
                Text(month, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: cal.fg.withOpacity(0.9))),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 105,
              child: tasks.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No tasks', style: TextStyle(fontSize: 13, color: cal.fg.withOpacity(0.5), fontWeight: FontWeight.w500)),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => _calendarEvent(tasks[index], cal),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarEvent(TaskItem task, ThemeSpec cal) {
    final label = task.type == TaskType.allday ? 'ALL DAY' : (task.start == null ? 'ANY' : _fmtTime(task.start!));
    return TapScale(
      onTap: () => _openEdit(task),
      pressedScale: 0.96,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cal.fg.withOpacity(0.8), letterSpacing: 0.3)),
            const SizedBox(height: 8),
            Container(width: 1, height: 60, decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(1))),
            const SizedBox(height: 8),
            LiquidGlassSurface(
              width: double.infinity,
              borderRadius: 14,
              padding: const EdgeInsets.all(10),
              tint: Colors.black.withOpacity(0.24),
              borderColor: Colors.white.withOpacity(0.12),
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextOverlay() {
    return IgnorePointer(
      ignoring: !_showContext,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showContext ? 1 : 0,
        child: GestureDetector(
          onTap: _hideContext,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: Colors.black.withOpacity(0.15),
              child: Stack(
                children: [
                  Positioned(
                    top: 72,
                    right: 20,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        scale: _showContext ? 1 : 0.9,
                        child: LiquidGlassSurface(
                          width: 200,
                          borderRadius: 24,
                          padding: const EdgeInsets.all(10),
                          tint: Colors.white.withOpacity(0.72),
                          borderColor: Colors.white.withOpacity(0.50),
                          shadow: true,
                          strong: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _contextItem(Icons.text_fields, '\u6587\u5b57\u65e5\u7a0b', () => _openAdd('text')),
                              _contextItem(Icons.image_outlined, '\u56fe\u7247\u65e5\u7a0b', () => _openAdd('image')),
                              _contextItem(Icons.auto_awesome, 'AI \u667a\u80fd\u521b\u5efa', _openAI),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contextItem(IconData icon, String label, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, size: 17, color: const Color(0xFF111111)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111111))),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskModal() {
    return _BottomOverlay(
      open: _taskModalOpen,
      onTapScrim: _closeTaskModal,
      child: _taskModalContent(),
    );
  }

  Widget _taskModalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_editingId == null ? (_currentAddKind == 'image' ? 'New Photo Task' : 'New Task') : 'Edit Task', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
        const SizedBox(height: 22),
        const _InputLabel('Task Type'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _typeChip(TaskType.timed, 'Schedule'),
              const SizedBox(width: 8),
              _typeChip(TaskType.allday, 'All Day'),
              const SizedBox(width: 8),
              _typeChip(TaskType.todo, 'To-do'),
              const SizedBox(width: 8),
              _typeChip(TaskType.note, 'Note'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _InputLabel('Title'),
        _ModalInput(controller: _titleCtrl, hint: 'e.g. Product Sync'),
        const SizedBox(height: 14),
        const _InputLabel('Description'),
        _ModalInput(controller: _subtitleCtrl, hint: 'e.g. Weekly standup notes', minLines: 1, maxLines: 2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _InputLabel('Date'),
                  _SelectBox(label: _formDate, onTap: _pickDate),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _InputLabel('Category'),
                  _CategorySelect(value: _formCategory, onChanged: (v) => setState(() => _formCategory = v)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _formType == TaskType.timed
              ? Row(
                  key: const ValueKey('time-row'),
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _InputLabel('Start'),
                          _SelectBox(label: _formStart, onTap: () => _pickTime(true)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _InputLabel('End'),
                          _SelectBox(label: _formEnd, onTap: () => _pickTime(false)),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('no-time-row')),
        ),
        if (_formType == TaskType.timed) const SizedBox(height: 14),
        const _InputLabel('Badge / Duration'),
        _ModalInput(controller: _pillCtrl, hint: _pillHintFor(_formType)),
        const SizedBox(height: 16),
        if (_currentAddKind == 'image') _imageUploadBox(_pickPhoto, _attachedImageName.isEmpty ? 'Tap to upload a photo' : _attachedImageName),
        TapScale(onTap: _saveTask, child: const _ModalButton(label: 'Save Task', dark: true)),
        if (_editingId != null) ...[
          const SizedBox(height: 10),
          TapScale(onTap: _deleteTask, child: const _ModalButton(label: 'Delete Task', danger: true)),
        ],
        const SizedBox(height: 10),
        TapScale(onTap: _closeTaskModal, child: const _ModalButton(label: 'Cancel')),
      ],
    );
  }

  Widget _typeChip(TaskType type, String label) {
    final active = _formType == type;
    return TapScale(
      onTap: () => setState(() => _formType = type),
      child: LiquidGlassSurface(
        borderRadius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        tint: active ? const Color(0xE6111111) : const Color(0x4DFFFFFF),
        borderColor: active ? const Color(0x33111111) : const Color(0x66FFFFFF),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF111111))),
      ),
    );
  }

  Widget _buildAiModal() {
    return _BottomOverlay(
      open: _aiModalOpen,
      onTapScrim: _closeAIModal,
      child: _aiModalContent(),
    );
  }

  Widget _aiModalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome, size: 21, color: Color(0xFF111111)),
            SizedBox(width: 10),
            Text('AI Create', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
          ],
        ),
        const SizedBox(height: 22),
        const _InputLabel('Describe your task'),
        _ModalInput(controller: _aiPromptCtrl, hint: '例如：明天下午3点团队会议，大概1小时...', minLines: 2, maxLines: 3),
        const SizedBox(height: 12),
        const Center(child: Text('OR', style: TextStyle(fontSize: 12, color: Color(0x59000000), fontWeight: FontWeight.w500))),
        const SizedBox(height: 12),
        _imageUploadBox(_pickAIPhoto, 'Upload photo / screenshot to generate', compact: true),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _aiGenerated == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _InputLabel('AI Preview'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            _previewRow('Title', _aiGenerated!.title),
                            _previewRow('Date', _aiGenerated!.date),
                            _previewRow('Time', _aiGenerated!.start == null ? (_aiGenerated!.type == TaskType.allday ? 'All Day' : 'Anytime') : '${_aiGenerated!.start} - ${_aiGenerated!.end}'),
                            _previewRow('Type', _typeLabel(_aiGenerated!.type)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        TapScale(
          onTap: _aiLoading ? null : _generateOrConfirmAI,
          child: _ModalButton(label: _aiLoading ? 'Analyzing...' : (_aiGenerated == null ? 'Generate Task' : 'Confirm Add'), dark: true, disabled: _aiLoading),
        ),
        const SizedBox(height: 10),
        TapScale(onTap: _closeAIModal, child: const _ModalButton(label: 'Cancel')),
      ],
    );
  }

  Widget _imageUploadBox(VoidCallback onTap, String label, {bool compact = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TapScale(
        onTap: onTap,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: const Color(0xFFDDDDDD),
            radius: 24,
            strokeWidth: 2,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 18 : 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const Icon(Icons.add_photo_alternate_outlined, size: 26, color: Color(0x66000000)),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0x66000000))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
          Flexible(child: Text(v, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF333333)))),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      setState(() => _attachedImageName = file.name);
      _toast('Image attached: ${file.name}');
    } catch (_) {
      _toast('Image picker unavailable in this environment');
    }
  }

  Future<void> _pickAIPhoto() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      setState(() {
        _aiPromptCtrl.text = 'flight ticket: Beijing to NYC, Dec 15, 16:20 departure';
      });
      _toast('Image recognized: ${file.name}');
    } catch (_) {
      setState(() => _aiPromptCtrl.text = 'flight ticket: Beijing to NYC, Dec 15, 16:20 departure');
      _toast('Image recognition demo loaded');
    }
  }

  void _switchView(ViewMode mode) {
    setState(() => _view = mode);
  }

  void _showAddContext() {
    HapticFeedback.mediumImpact();
    setState(() => _showContext = true);
  }

  void _hideContext() {
    setState(() => _showContext = false);
  }

  void _openAdd(String type) {
    _hideContext();
    setState(() {
      _editingId = null;
      _currentAddKind = type;
      _attachedImageName = '';
      _formType = TaskType.timed;
      _formDate = todayDate;
      _formStart = '10:00';
      _formEnd = '11:00';
      _formCategory = 'work';
      _titleCtrl.clear();
      _subtitleCtrl.clear();
      _pillCtrl.clear();
      _taskModalOpen = true;
    });
  }

  void _openEdit(TaskItem task) {
    setState(() {
      _editingId = task.id;
      _currentAddKind = 'text';
      _attachedImageName = '';
      _formType = task.type;
      _formDate = task.date;
      _formStart = task.start ?? '10:00';
      _formEnd = task.end ?? '11:00';
      _formCategory = task.category;
      _titleCtrl.text = task.title;
      _subtitleCtrl.text = task.subtitle;
      _pillCtrl.text = task.pillText;
      _taskModalOpen = true;
    });
  }

  void _closeTaskModal() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _taskModalOpen = false);
  }

  void _openAI() {
    _hideContext();
    setState(() {
      _aiPromptCtrl.clear();
      _aiGenerated = null;
      _aiLoading = false;
      _aiModalOpen = true;
    });
  }

  void _closeAIModal() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _aiModalOpen = false);
  }

  void _saveTask() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _formDate.isEmpty) {
      _toast('Please fill required fields');
      return;
    }
    final start = _formType == TaskType.timed ? _formStart : null;
    final end = _formType == TaskType.timed ? _formEnd : null;
    final pill = _pillCtrl.text.trim().isEmpty ? _typeLabel(_formType) : _pillCtrl.text.trim();
    final theme = _themeByCategory(_formCategory);

    setState(() {
      if (_editingId != null) {
        final i = _tasks.indexWhere((t) => t.id == _editingId);
        if (i != -1) {
          _tasks[i] = _tasks[i].copyWith(
            title: title,
            subtitle: _subtitleCtrl.text.trim(),
            date: _formDate,
            start: start,
            clearStart: start == null,
            end: end,
            clearEnd: end == null,
            pillText: pill,
            category: _formCategory,
            theme: theme,
            type: _formType,
          );
        }
      } else {
        final avatars = _formType == TaskType.note ? <int>[] : [_randomAvatar(30), _randomAvatar(60)];
        _tasks.add(TaskItem(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          subtitle: _subtitleCtrl.text.trim(),
          date: _formDate,
          start: start,
          end: end,
          pillText: pill,
          category: _formCategory,
          theme: theme,
          type: _formType,
          avatars: avatars,
          images: _attachedImageName.isEmpty ? [] : [_attachedImageName],
        ));
      }
      _taskModalOpen = false;
    });
  }

  void _deleteTask() {
    if (_editingId == null) return;
    setState(() {
      _tasks.removeWhere((t) => t.id == _editingId);
      _taskModalOpen = false;
    });
  }

  void _toggleTodo(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      final i = _tasks.indexWhere((t) => t.id == id);
      if (i != -1) _tasks[i] = _tasks[i].copyWith(completed: !_tasks[i].completed);
    });
  }

  Future<void> _generateOrConfirmAI() async {
    if (_aiGenerated != null) {
      setState(() {
        _tasks.add(_aiGenerated!.copyWith(id: DateTime.now().millisecondsSinceEpoch));
        _aiModalOpen = false;
      });
      return;
    }
    final prompt = _aiPromptCtrl.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _aiLoading = true);
    await Future.delayed(Duration(milliseconds: 1000 + math.Random().nextInt(800)));
    if (!mounted) return;
    setState(() {
      _aiGenerated = _mockAIParse(prompt);
      _aiLoading = false;
    });
  }

  TaskItem _mockAIParse(String text) {
    final lower = text.toLowerCase();
    String title = 'New Task';
    String date = todayDate;
    String? start;
    String? end;
    TaskType type = TaskType.timed;
    String category = 'work';
    String pillText = 'Event';

    if (lower.contains('明天')) date = '2024-12-14';
    if (lower.contains('后天')) date = '2024-12-15';
    if (lower.contains('大后天')) date = '2024-12-16';
    if (lower.contains('dec 15') || lower.contains('12-15')) date = '2024-12-15';

    if (lower.contains('下午3点') || lower.contains('3点') || lower.contains('15:') || lower.contains('15点')) {
      start = '15:00';
      end = '16:00';
      pillText = '1 Hour';
    } else if (lower.contains('16:20')) {
      start = '16:20';
      end = '03:45';
      pillText = '13h 25m';
    } else if (lower.contains('上午') || lower.contains('早上') || lower.contains('10点')) {
      start = '10:00';
      end = '11:00';
      pillText = '1 Hour';
    } else if (lower.contains('下午2点') || lower.contains('14点') || lower.contains('14:')) {
      start = '14:00';
      end = '15:00';
      pillText = '1 Hour';
    } else if (lower.contains('全天') || lower.contains('all day')) {
      type = TaskType.allday;
      pillText = 'All Day';
    } else if (lower.contains('todo') || lower.contains('待办') || lower.contains('记得') || lower.contains('buy')) {
      type = TaskType.todo;
      pillText = 'To-do';
    }

    if (lower.contains('会') || lower.contains('sync') || lower.contains('meeting') || lower.contains('会议')) {
      title = 'Team Meeting';
      category = 'work';
    } else if (lower.contains('饭') || lower.contains('lunch') || lower.contains('dinner') || lower.contains('吃')) {
      title = 'Meal';
      category = 'personal';
    } else if (lower.contains('飞') || lower.contains('flight') || lower.contains('travel') || lower.contains('旅行')) {
      title = 'Travel';
      category = 'travel';
    } else if (lower.contains('买') || lower.contains('shop') || lower.contains('grocery') || lower.contains('超市')) {
      title = 'Shopping';
      category = 'personal';
    } else if (lower.contains('书') || lower.contains('read') || lower.contains('note') || lower.contains('笔记')) {
      title = 'Quick Note';
      type = TaskType.note;
      category = 'personal';
      pillText = 'Note';
      start = null;
      end = null;
    } else if (text.isNotEmpty) {
      title = text.length > 25 ? text.substring(0, 25) : text;
    }

    if (type != TaskType.timed) {
      start = null;
      end = null;
    }

    return TaskItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      date: date,
      start: start,
      end: end,
      type: type,
      category: category,
      subtitle: text.length > 60 ? text.substring(0, 60) : text,
      pillText: pillText,
      theme: _themeByCategory(category),
      avatars: type == TaskType.note ? [] : [_randomAvatar(30)],
    );
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_formDate) ?? DateTime(2024, 12, 13);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF111111))), child: child!),
    );
    if (picked != null) setState(() => _formDate = _dateString(picked));
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _formStart : _formEnd;
    final parts = current.split(':').map(int.parse).toList();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF111111))), child: child!),
    );
    if (picked != null) {
      setState(() {
        final text = '${_pad(picked.hour)}:${_pad(picked.minute)}';
        if (start) {
          _formStart = text;
        } else {
          _formEnd = text;
        }
      });
    }
  }

  void _updateClocks() {
    final utc = DateTime.now().toUtc();
    final ny = utc.subtract(const Duration(hours: 4));
    final uk = utc.add(const Duration(hours: 1));
    if (mounted) {
      setState(() {
        _nyClock = _clockText(ny);
        _ukClock = _clockText(uk);
      });
    }
  }

  int _sortTasks(TaskItem a, TaskItem b) {
    if (a.type == TaskType.allday && b.type != TaskType.allday) return -1;
    if (a.type != TaskType.allday && b.type == TaskType.allday) return 1;
    if (a.start == null && b.start != null) return 1;
    if (a.start != null && b.start == null) return -1;
    return (a.start ?? '').compareTo(b.start ?? '');
  }

  int _sortCalendarTasks(TaskItem a, TaskItem b) {
    if (a.start == null && b.start != null) return 1;
    if (a.start != null && b.start == null) return -1;
    return (a.start ?? '').compareTo(b.start ?? '');
  }

  void _toast(String text) {
    _toastTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _toastText = text;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  Widget _buildToastBubble() {
    return Positioned(
      left: 36,
      right: 36,
      bottom: 28,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _toastVisible ? Offset.zero : const Offset(0, 0.4),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _toastVisible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xEE111111),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Text(
                  _toastText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ThemeSpec _themeFor(String key) {
    switch (key) {
      case 'sage':
        return const ThemeSpec(bg: Color(0xFFA2AEAA), fg: Color(0xFF1E2623), pill: Color(0xFF2A3330));
      case 'rose':
        return const ThemeSpec(bg: Color(0xFFC9A0A0), fg: Color(0xFF3B2020), pill: Color(0xFF5A2E2E));
      case 'sky':
        return const ThemeSpec(bg: Color(0xFFA0B8C9), fg: Color(0xFF1F2E3B), pill: Color(0xFF2A3B4D));
      case 'gold':
      default:
        return const ThemeSpec(bg: Color(0xFFD8B87A), fg: Color(0xFF2C2117), pill: Color(0xFF3E3223));
    }
  }

  ThemeSpec _calendarTheme(String key) {
    switch (key) {
      case 'sage':
        return const ThemeSpec(bg: Color(0xFFBC7C7C), fg: Color(0xFF3E1E1E), pill: Color(0xFF3E1E1E));
      case 'rose':
        return const ThemeSpec(bg: Color(0xFF7CBFB1), fg: Color(0xFF1A3E36), pill: Color(0xFF1A3E36));
      case 'sky':
        return const ThemeSpec(bg: Color(0xFFA3B88C), fg: Color(0xFF25331B), pill: Color(0xFF25331B));
      case 'gold':
      default:
        return const ThemeSpec(bg: Color(0xFF9F92C6), fg: Color(0xFF352D52), pill: Color(0xFF352D52));
    }
  }

  TypeConfig _typeConfig(TaskType type) {
    switch (type) {
      case TaskType.allday:
        return const TypeConfig(icon: Icons.wb_sunny_outlined, label: 'All Day');
      case TaskType.todo:
        return const TypeConfig(icon: Icons.check_circle_outline, label: 'To-do');
      case TaskType.note:
        return const TypeConfig(icon: Icons.sticky_note_2_outlined, label: 'Note');
      case TaskType.timed:
      default:
        return const TypeConfig(icon: Icons.access_time, label: 'Schedule');
    }
  }

  String _themeByCategory(String cat) {
    switch (cat) {
      case 'personal':
        return 'sage';
      case 'study':
        return 'rose';
      case 'travel':
        return 'sky';
      case 'work':
      default:
        return 'gold';
    }
  }

  String _typeLabel(TaskType type) => _typeConfig(type).label;

  static String _pillHintFor(TaskType type) {
    switch (type) {
      case TaskType.allday:
        return 'e.g. Holiday, Off-site';
      case TaskType.todo:
        return 'e.g. Due by evening';
      case TaskType.note:
        return 'e.g. Quick thought';
      case TaskType.timed:
        return 'e.g. 1 Hour, 1 Night';
    }
  }

  String _fmtTime(String value) {
    final parts = value.split(':');
    var hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? parts[1] : '00';
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $suffix';
  }

  String _clockText(DateTime time) {
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    var hour = time.hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:${_pad(time.minute)} $suffix';
  }

  String _dateString(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _weekdayName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  int _randomAvatar(int max) => math.Random().nextInt(max) + 1;
}

class TypeConfig {
  const TypeConfig({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const LiquidGlassSettings kLiquidGlassSettings = LiquidGlassSettings(
  visibility: 0.82,
  glassColor: Color(0x3DFFFFFF),
  thickness: 22,
  blur: 8,
  chromaticAberration: 0.012,
  lightIntensity: 0.66,
  ambientStrength: 0.08,
  refractiveIndex: 1.18,
  saturation: 1.28,
);

const LiquidGlassSettings kStrongLiquidGlassSettings = LiquidGlassSettings(
  visibility: 0.95,
  glassColor: Color(0x55FFFFFF),
  thickness: 30,
  blur: 12,
  chromaticAberration: 0.016,
  lightIntensity: 0.72,
  ambientStrength: 0.12,
  refractiveIndex: 1.22,
  saturation: 1.35,
);

class LiquidBackdrop extends StatelessWidget {
  const LiquidBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE8E8E3)),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -92,
            child: _BackdropOrb(size: 260, color: Color(0x33D8B87A)),
          ),
          Positioned(
            top: 142,
            left: -120,
            child: _BackdropOrb(size: 230, color: Color(0x24A0B8C9)),
          ),
          Positioned(
            bottom: 120,
            right: -95,
            child: _BackdropOrb(size: 240, color: Color(0x22C9A0A0)),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 42, sigmaY: 42),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 24,
    this.tint = const Color(0x29FFFFFF),
    this.borderColor = const Color(0x3DFFFFFF),
    this.borderWidth = 1,
    this.shadow = false,
    this.strong = false,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color tint;
  final Color? borderColor;
  final double borderWidth;
  final bool shadow;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.withOwnLayer(
      settings: strong ? kStrongLiquidGlassSettings : kLiquidGlassSettings,
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderColor == null ? null : Border.all(color: borderColor!, width: borderWidth),
          boxShadow: shadow
              ? const [
                  BoxShadow(color: Color(0x1F000000), blurRadius: 28, offset: Offset(0, 12)),
                  BoxShadow(color: Color(0x33FFFFFF), blurRadius: 12, offset: Offset(0, -2)),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.open, required this.onTapScrim, required this.child});

  final bool open;
  final VoidCallback onTapScrim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: open ? 1 : 0,
        child: GestureDetector(
          onTap: onTapScrim,
          child: Container(
            color: Colors.black.withOpacity(0.45),
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 350),
                curve: Cubic(0.25, 1, 0.5, 1),
                offset: open ? Offset.zero : const Offset(0, 1),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.78),
                  child: LiquidGlassSurface(
                    width: double.infinity,
                    borderRadius: 40,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                    tint: Colors.white.withOpacity(0.86),
                    borderColor: Colors.white.withOpacity(0.62),
                    shadow: true,
                    strong: true,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: child,
                    ),
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

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0x80000000), letterSpacing: 0.5),
      ),
    );
  }
}

class _ModalInput extends StatelessWidget {
  const _ModalInput({required this.controller, required this.hint, this.minLines = 1, this.maxLines = 1});

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      cursorColor: const Color(0xFF111111),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF111111)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x59000000), fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5)),
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: LiquidGlassSurface(
        width: double.infinity,
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        tint: const Color(0x59FFFFFF),
        borderColor: const Color(0x66FFFFFF),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF111111))),
      ),
    );
  }
}

class _CategorySelect extends StatefulWidget {
  const _CategorySelect({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const Map<String, String> labels = {
    'work': 'Work',
    'personal': 'Personal',
    'study': 'Study',
    'travel': 'Travel',
  };

  @override
  State<_CategorySelect> createState() => _CategorySelectState();
}

class _CategorySelectState extends State<_CategorySelect> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final label = _CategorySelect.labels[widget.value] ?? 'Work';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TapScale(
          onTap: () => setState(() => _open = !_open),
          pressedScale: 0.98,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: _open ? Colors.white : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _open ? const Color(0xFF111111) : Colors.transparent, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF111111))),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF999999), size: 18),
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: !_open
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey('category-menu'),
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x0F000000)),
                      boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 10))],
                    ),
                    child: Column(
                      children: _CategorySelect.labels.entries.map((entry) {
                        final selected = entry.key == widget.value;
                        return TapScale(
                          onTap: () {
                            widget.onChanged(entry.key);
                            setState(() => _open = false);
                          },
                          pressedScale: 0.98,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFF5F5F5) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111111))),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}


class _ModalButton extends StatelessWidget {
  const _ModalButton({required this.label, this.dark = false, this.danger = false, this.disabled = false});

  final String label;
  final bool dark;
  final bool danger;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final Color bg = danger ? const Color(0xFFEF4444) : (dark ? const Color(0xFF111111) : const Color(0xFFF5F5F5));
    final Color fg = danger || dark ? Colors.white : const Color(0xFF111111);
    return Opacity(
      opacity: disabled ? 0.7 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}


class DashedRRectPainter extends CustomPainter {
  DashedRRectPainter({required this.color, required this.radius, required this.strokeWidth});

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(strokeWidth / 2), Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const dash = 7.0;
    const gap = 6.0;
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius || strokeWidth != oldDelegate.strokeWidth;
  }
}


class FadeUp extends StatefulWidget {
  const FadeUp({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class TapScale extends StatefulWidget {
  const TapScale({super.key, required this.child, this.onTap, this.pressedScale = 0.92});

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? widget.pressedScale : 1,
        child: widget.child,
      ),
    );
  }
}
