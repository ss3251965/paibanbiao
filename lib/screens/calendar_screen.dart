import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../models/day_record.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import 'shifts_screen.dart';
import 'cycle_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _storage = StorageService();
  DateTime _current = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, DayRecord> _records = {};
  List<Shift> _shifts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shifts = await _storage.loadShifts();
    final records = await _storage.loadRecords();
    if (!mounted) return;
    setState(() {
      _shifts = shifts;
      _records = records;
      _loading = false;
    });
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Shift? _shiftById(String? id) {
    if (id == null) return null;
    for (final s in _shifts) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _openPicker(DateTime date) async {
    final k = _key(date);
    final existing = _records[k] ?? DayRecord();
    final shiftId = existing.shiftId;
    final noteCtl = TextEditingController(text: existing.note);

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Text('${date.year}年${date.month}月${date.day}日',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ..._shifts.map((s) => ListTile(
                      leading: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      title: Text(s.name),
                      trailing: shiftId == s.id ? const Icon(Icons.check, color: Colors.blue) : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _setRecord(date, s.id, existing.note);
                      },
                    )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: noteCtl,
                    decoration: const InputDecoration(
                      labelText: '特殊记录（如：开会、请假）',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _setRecord(date, '', noteCtl.text);
                        },
                        child: const Text('只存备注/清除班次'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _setRecord(date, shiftId, noteCtl.text);
                        },
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setRecord(DateTime date, String shiftId, String note) async {
    final k = _key(date);
    setState(() {
      if (shiftId.isEmpty && note.isEmpty) {
        _records.remove(k);
      } else {
        _records[k] = DayRecord(shiftId: shiftId, note: note);
      }
    });
    await _storage.saveRecords(_records);
  }

  void _changeMonth(int delta) {
    setState(() => _current = DateTime(_current.year, _current.month + delta));
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() => _current = DateTime(now.year, now.month));
  }

  Future<void> _export() async {
    await ExportService.exportCsv(records: _records, shifts: _shifts);
  }

  @override
  Widget build(BuildContext context) {
    final year = _current.year;
    final month = _current.month;
    final first = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = first.weekday % 7;
    final total = leading + daysInMonth;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('班表小历'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '班次管理',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftsScreen()));
              _load();
            },
          ),
          IconButton(
            tooltip: '周期排班',
            icon: const Icon(Icons.autorenew),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => CycleScreen(onApply: _load)));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'export') _export();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('导出 CSV')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _monthBar(year, month),
                _weekdayHeader(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                    ),
                    itemCount: total,
                    itemBuilder: (context, index) {
                      if (index < leading) return const SizedBox.shrink();
                      final day = index - leading + 1;
                      final date = DateTime(year, month, day);
                      final rec = _records[_key(date)];
                      final shift = _shiftById(rec?.shiftId);
                      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                      return _dayCell(date, day, shift, rec?.note ?? '', isToday);
                    },
                  ),
                ),
                _legend(),
              ],
            ),
    );
  }

  Widget _monthBar(int year, int month) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Center(
              child: Text('$year年$month月', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
          TextButton(onPressed: _goToday, child: const Text('今天')),
        ],
      ),
    );
  }

  Widget _weekdayHeader() {
    const days = ['日', '一', '二', '三', '四', '五', '六'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: days.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12))))).toList(),
      ),
    );
  }

  Widget _dayCell(DateTime date, int day, Shift? shift, String note, bool isToday) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openPicker(date),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$day', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (shift != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(color: shift.color, borderRadius: BorderRadius.circular(5)),
                child: Text(shift.short, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            if (note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    if (_shifts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: _shifts.map((s) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 4),
            Text(s.name, style: const TextStyle(fontSize: 12)),
          ],
        )).toList(),
      ),
    );
  }
}