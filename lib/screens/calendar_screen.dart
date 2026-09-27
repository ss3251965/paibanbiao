import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
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

  final Map<String, String> _holidays = {
    '1-1': '元旦', '2-14': '情人节', '3-8': '妇女节', '3-12': '植树节',
    '4-1': '愚人节', '5-1': '劳动节', '5-4': '青年节', '6-1': '儿童节',
    '7-1': '建党节', '8-1': '建军节', '9-10': '教师节', '10-1': '国庆节',
    '12-24': '平安夜', '12-25': '圣诞节',
  };

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

  Future<void> _showYearMonthPicker(BuildContext context) async {
    int selectedYear = _current.year;
    int selectedMonth = _current.month;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('选择年月', style: TextStyle(fontSize: 16)),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(15, (i) => DateTime.now().year - 10 + i)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y年'))).toList(),
                  onChanged: (v) => setSt(() => selectedYear = v!),
                ),
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m月'))).toList(),
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

  // 精简版弹窗
  Future<void> _openPicker(DateTime date) async {
    final k = _key(date);
    final existing = _records[k] ?? DayRecord();
    final noteCtl = TextEditingController(text: existing.note);
    bool isDone = existing.isDone;

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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${date.year}年${date.month}月${date.day}日',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () { Navigator.pop(ctx); _setRecord(date, '', false); },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: noteCtl,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '写点什么...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    CheckboxListTile(
                      value: isDone,
                      onChanged: (v) => setSt(() => isDone = v!),
                      title: const Text('标记为已完成', style: TextStyle(fontSize: 14)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () { Navigator.pop(ctx); _setRecord(date, noteCtl.text, isDone); },
                          child: const Text('保存'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _setRecord(DateTime date, String note, bool isDone) async {
    final k = _key(date);
    setState(() {
      if (note.isEmpty) _records.remove(k);
      else _records[k] = DayRecord(shiftId: '', note: note, isDone: isDone);
    });
    await _storage.saveRecords(_records);
  }

  void _changeMonth(int delta) => setState(() => _current = DateTime(_current.year, _current.month + delta));

  void _goToday() {
    final now = DateTime.now();
    setState(() { _current = DateTime(now.year, now.month); _selectedDate = now; });
  }

  Future<void> _export() async => await ExportService.exportCsv(records: _records, shifts: _shifts);

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
        title: const Text('班表小历'), centerTitle: true,
        actions: [
          IconButton(tooltip: '班次管理', icon: const Icon(Icons.tune), onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftsScreen())); _load();
          }),
          IconButton(tooltip: '周期排班', icon: const Icon(Icons.autorenew), onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => CycleScreen(onApply: _load)));
          }),
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'export') _export(); },
            itemBuilder: (_) => const [PopupMenuItem(value: 'export', child: Text('导出 CSV'))],
          ),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          _monthBar(year, month),
          _weekdayHeader(),
          Expanded(
            // 加入手势滑动
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _changeMonth(-1); // 右滑，上个月
                } else if (details.primaryVelocity! < 0) {
                  _changeMonth(1); // 左滑，下个月
                }
              },
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 2), // 缩小边距
                // 调整比例，让日历撑满屏幕，不再只占一半
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.62, // 高度拉长，撑满剩余空间
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: total,
                itemBuilder: (context, index) {
                  if (index < leading) return const SizedBox.shrink();
                  final day = index - leading + 1;
                  final date = DateTime(year, month, day);
                  final rec = _records[_key(date)];
                  final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                  final isSelected = _selectedDate != null && date.year == _selectedDate!.year && date.month == _selectedDate!.month && date.day == _selectedDate!.day;
                  
                  String lunarText = '';
                  final holiday = _holidays['${date.month}-${date.day}'];
                  final lunar = Lunar.fromDate(date);
                  if (holiday != null) {
                    lunarText = holiday;
                  } else if (lunar.getJieQi().isNotEmpty) {
                    lunarText = lunar.getJieQi();
                  } else if (lunar.getFestivals().isNotEmpty) {
                    lunarText = lunar.getFestivals().first;
                  } else {
                    lunarText = lunar.getDayInChinese();
                  }

                  return _dayCell(date, day, rec, lunarText, isToday, isSelected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthBar(int year, int month) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          Expanded(
            child: InkWell(
              onTap: () => _showYearMonthPicker(context),
              child: Center(child: Text('$year年$month月', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            ),
          ),
          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          TextButton(onPressed: _goToday, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero), child: const Text('今天', style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _weekdayHeader() {
    const days = ['日', '一', '二', '三', '四', '五', '六'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: days.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11))))).toList(),
      ),
    );
  }

  Widget _dayCell(DateTime date, int day, DayRecord? rec, String lunarText, bool isToday, bool isSelected) {
    final theme = Theme.of(context);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    String displayText = (rec != null && rec.note.isNotEmpty) ? rec.note : '';
    bool isDone = rec?.isDone ?? false;

    Color lunarColor = Colors.grey.shade500;
    if (isWeekend || lunarText.contains('节') || lunarText.contains('元旦') || lunarText.contains('国庆')) {
      lunarColor = Colors.red;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _openPicker(date),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: Colors.orange, width: 1.5)
              : (isToday ? Border.all(color: theme.colorScheme.primary, width: 1) : null),
        ),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1), // 极度缩减内边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('$day', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isWeekend ? Colors.red : null)),
            const SizedBox(height: 1),
            Text(
              lunarText,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8, color: lunarColor), // 字号缩小，防止溢出
            ),
            const Spacer(),
            if (displayText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
                decoration: BoxDecoration(
                  color: isDone ? Colors.grey.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                // 使用 FittedBox 让文字自动缩放，尽量显示更多字
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    displayText,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: isDone ? Colors.grey : theme.colorScheme.primary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}