import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart'; // 引入农历库
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

  // 公历节日（弥补农历库无法自动计算的固定公历节日）
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
            title: const Text('选择年月'),
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

  Future<void> _openPicker(DateTime date) async {
    final k = _key(date);
    final existing = _records[k] ?? DayRecord();
    final noteCtl = TextEditingController(text: existing.note);
    bool isDone = existing.isDone;

    setState(() => _selectedDate = date);

    await showModalBottomSheet(
      context: context, showDragHandle: true, isScrollControlled: true,
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
                            onPressed: () { Navigator.pop(ctx); _setRecord(date, '', false); },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: TextField(
                        controller: noteCtl,
                        decoration: const InputDecoration(labelText: '自定义记录', border: OutlineInputBorder()),
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
                            onPressed: () { Navigator.pop(ctx); _setRecord(date, noteCtl.text, isDone); },
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
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
              // 小米日历的比例，让格子略微拉长，能容纳农历和记录条
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.72, 
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: total,
              itemBuilder: (context, index) {
                if (index < leading) return const SizedBox.shrink();
                final day = index - leading + 1;
                final date = DateTime(year, month, day);
                final rec = _records[_key(date)];
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                final isSelected = _selectedDate != null && date.year == _selectedDate!.year && date.month == _selectedDate!.month && date.day == _selectedDate!.day;
                
                // 计算农历显示文本
                String lunarText = '';
                final holiday = _holidays['${date.month}-${date.day}'];
                final lunar = Lunar.fromDate(date);
                if (holiday != null) {
                  lunarText = holiday; // 公历节日优先
                } else if (lunar.getJieQi().isNotEmpty) {
                  lunarText = lunar.getJieQi(); // 节气优先
                } else if (lunar.getFestivals().isNotEmpty) {
                  lunarText = lunar.getFestivals().first; // 农历节日
                } else {
                  lunarText = lunar.getDayInChinese(); // 普通农历日
                }

                return _dayCell(date, day, rec, lunarText, isToday, isSelected);
              },
            ),
          ),
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
              child: Center(child: Text('$year年$month月', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
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

  Widget _dayCell(DateTime date, int day, DayRecord? rec, String lunarText, bool isToday, bool isSelected) {
    final theme = Theme.of(context);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    String displayText = (rec != null && rec.note.isNotEmpty) ? rec.note : '';
    bool isDone = rec?.isDone ?? false;

    // 农历文字的颜色：如果是节日/节气标红，如果是周末标红，否则用浅灰色
    Color lunarColor = Colors.grey.shade500;
    if (isWeekend || lunarText.contains('节') || lunarText.contains('元旦') || lunarText.contains('国庆')) {
      lunarColor = Colors.red;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openPicker(date),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.orange, width: 2)
              : (isToday ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 阳历数字：小米日历字号较大
            Text('$day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isWeekend ? Colors.red : null)),
            const SizedBox(height: 2),
            // 农历/节日：小字
            Text(
              lunarText,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: lunarColor),
            ),
            const Spacer(),
            // 自定义记录：胶囊样式
            if (displayText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isDone ? Colors.grey.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayText,
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: isDone ? Colors.grey : theme.colorScheme.primary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}