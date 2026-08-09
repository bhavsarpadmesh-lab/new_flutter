import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../services/notification_service.dart';
import '../theme/riso.dart';
import '../utils/category_icons.dart';
import 'home_screen.dart' show BlockButton;

class AddHabitScreen extends StatefulWidget {
  final Habit? habit;
  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late String _category;
  TimeOfDay? _reminderTime;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    _name = widget.habit?.name ?? '';
    _description = widget.habit?.description ?? '';
    _category = widget.habit?.category ?? 'Other';
    final existing = widget.habit?.reminderTime;
    if (existing != null) {
      final parts = existing.split(':');
      _reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = context.read<HabitProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final time = _reminderTime;
    final reminder = time == null
        ? null
        : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}';

    // Ask for notification permission here, where the person has just chosen a
    // reminder, rather than on a cold start where it has no context.
    var remindersBlocked = false;
    if (reminder != null) {
      remindersBlocked = !await NotificationService().ensurePermission();
    }

    if (_isEditing) {
      await provider.editHabit(
        widget.habit!.copyWith(
          name: _name,
          description: _description,
          category: _category,
          reminderTime: reminder,
        ),
      );
    } else {
      await provider.addHabit(_name, _description, _category, reminder);
    }

    if (remindersBlocked) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved. Reminders stay off until you allow notifications for '
            'Habit Ledger in Android settings.',
            style: RisoType.mono(size: 11, letterSpacing: 0.8, color: Riso.paper),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Riso.paper,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _masthead(context),
              const SizedBox(height: 20),
              _field(
                'WHAT WILL YOU DO',
                TextFormField(
                  initialValue: _name,
                  textCapitalization: TextCapitalization.sentences,
                  style: RisoType.display(
                    size: 22,
                    weight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                  cursorColor: Riso.pink,
                  decoration: _inputDecoration('Morning run'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Give the habit a name'
                      : null,
                  onSaved: (v) => _name = v!.trim(),
                ),
              ),
              _field(
                'WHY IT MATTERS',
                TextFormField(
                  initialValue: _description,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  style: RisoType.body(size: 15, height: 1.4, color: Riso.ink),
                  cursorColor: Riso.pink,
                  decoration: _inputDecoration(
                    "One line you'll believe at 6am",
                  ),
                  onSaved: (v) => _description = (v ?? '').trim(),
                ),
              ),
              _field('CATEGORY', _categoryChips()),
              _field('REMIND ME AT', _reminderRow()),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Riso.gutter,
            8,
            Riso.gutter,
            Riso.gutter,
          ),
          child: BlockButton(
            label: _isEditing ? 'Save changes' : 'Save habit',
            onPressed: _save,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- pieces

  Widget _masthead(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 20, Riso.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 40),
              child: Text('← BACK', style: RisoType.mono(letterSpacing: 2.2)),
            ),
          ),
          Text(
            _isEditing ? 'EDIT' : 'START',
            style: RisoType.display(size: 52, height: 0.86, letterSpacing: -1.8),
          ),
          Text(
            _isEditing ? 'THE ENTRY' : 'A RUN',
            style: RisoType.display(
              size: 52,
              height: 0.86,
              letterSpacing: -1.8,
              color: Riso.pink,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    const underline = UnderlineInputBorder(
      borderSide: BorderSide(color: Riso.ink, width: 2.5),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: RisoType.body(size: 15, color: Riso.paper3),
      isDense: true,
      contentPadding: const EdgeInsets.only(bottom: 9),
      enabledBorder: underline,
      border: underline,
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Riso.pink, width: 2.5),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Riso.pink, width: 2.5),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Riso.pink, width: 2.5),
      ),
      errorStyle: RisoType.mono(size: 10, letterSpacing: 1.2, color: Riso.pink),
    );
  }

  Widget _field(String label, Widget child) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Riso.ink, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 18, Riso.gutter, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: RisoType.mono(letterSpacing: 2.4)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _categoryChips() {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: CategoryIcons.all.map((c) {
        final selected = c == _category;
        final ink = CategoryIcons.getColor(c);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _category = c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? ink : Colors.transparent,
              border: Border.all(color: selected ? ink : Riso.ink, width: 2),
            ),
            child: Text(
              c.toUpperCase(),
              style: RisoType.mono(
                letterSpacing: 1.4,
                color: selected ? Colors.white : Riso.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _reminderRow() {
    final time = _reminderTime;
    final label = time == null
        ? 'NONE'
        : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _pickTime,
          child: Text(
            label,
            style: RisoType.display(size: 38, letterSpacing: -1.6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickTime,
            child: Text(
              time == null ? 'TAP TO SET' : 'EVERY DAY',
              style: RisoType.mono(letterSpacing: 1.6),
            ),
          ),
        ),
        if (time != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _reminderTime = null),
            child: Text(
              'REMOVE',
              style: RisoType.mono(letterSpacing: 1.6, color: Riso.pink),
            ),
          ),
      ],
    );
  }
}
