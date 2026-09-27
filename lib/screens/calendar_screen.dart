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
  DateTime? _selectedDate;
  Map<String, DayRecord> _records = {};
  List<Shift> _shifts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
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

  Future<void> _showYearMonthPicker(BuildContext context) async {
    int selectedYear = _current.year;
    int selectedMonth = _current.month;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('选择年月'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(15, (i) => DateTime.now().year - 10 + i)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y年')))
                      .toList(),
                  onChanged: (v) => setSt(() => selectedYear = v!),
                ),
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m月')))
                      .toList(),
                  onChanged: (v) => setSt(() => selectedMonth = v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(
                onPressed: () {
                  setState(() => _current = DateTime(selectedYear, selectedMonth));
                  Navigator.pop(ctx);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPicker(DateTime date) async {
    final k = _key(date);
    final existing = _records[k] ?? DayRecord();
    final noteCtl = TextEditingController(text: existing.note);
    bool isDone = existing.isDone;
    String currentShiftId = existing.shiftId;

    setState(() => _selectedDate = date);

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (ctx, setSt) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${date.year}年${date.month}月${date.day}日',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: '删除此记录',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _setRecord(date, '', '', false);
                            },
                          ),
                        ],
                      ),
                    ),
                    ..._shifts.map((s) => ListTile(
                          leading: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(6)),
                          ),
                          title: Text(s.name),
                          trailing: currentShiftId == s.id ? const Icon(Icons.check, color: Colors.blue) : null,
                          onTap: () => setSt(() => currentShiftId = s.id),
                        )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: TextField(
                        controller: noteCtl,
                        decoration: const InputDecoration(
                          labelText: '自定义记录（如：跑步、会议）',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    CheckboxListTile(
                      value: isDone,
                      onChanged: (v) => setSt(() => isDone = v!),
                      title: const Text('标记为已完成'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _setRecord(date, currentShiftId, noteCtl.text, isDone);
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
            ),
          ),
        );
      },
    );
  }

  Future<void> _setRecord(DateTime date, String shiftId, String note, bool isDone) async {
    final k = _key(date);
    setState(() {
      if (shiftId.isEmpty && note.isEmpty) {
        _records.remove(k);
      } else {
        _records[k] = DayRecord(shiftId: shiftId, note: note, isDone: isDone);
      }
    });
    await _storage.saveRecords(_records);
  }

  void _changeMonth(int delta) {
    setState(() => _current = DateTime(_current.year, _current.month + delta));
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _current = DateTime(now.year, now.month);
      _selectedDate = now;
    });
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
                      final isSelected = _selectedDate != null && date.year == _selectedDate!.year && date.month == _selectedDate!.month && date.day == _selectedDate!.day;
                      
                      return _dayCell(date, day, shift, rec, isToday, isSelected);
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
            child: InkWell(
              onTap: () => _showYearMonthPicker(context),
              child: Center(
                child: Text('$year年$month月', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
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
        children: days.map((d) => Expanded(
          child: Center(
            child: Text(d, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _dayCell(DateTime date, int day, Shift? shift, DayRecord? rec, bool isToday, bool isSelected) {
    final theme = Theme.of(context);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    
    String displayText = '';
    if (rec != null) {
      if (rec.note.isNotEmpty) displayText = rec.note;
      else if (shift != null) displayText = shift.name;
    }
    
    bool isDone = rec?.isDone ?? false;
    Color textColor = isWeekend ? Colors.red : (theme.brightness == Brightness.dark ? Colors.white : Colors.black);
    
    if (isDone) {
      textColor = Colors.grey;
    } else if (theme.brightness == Brightness.dark) {
      textColor = Colors.white;
    } else {
      textColor = Colors.black;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openPicker(date),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: isSelected 
              ? Border.all(color: Colors.orange, width: 2)
              : (isToday ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null),
        ),
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isWeekend ? Colors.red : (theme.brightness == Brightness.dark ? Colors.white : Colors.black),
              ),
            ),
            const Spacer(),
            if (displayText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isDone ? Colors.grey.withOpacity(0.3) : (shift?.color ?? Colors.blueGrey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDone ? Colors.grey : Colors.white,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
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