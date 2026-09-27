import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../models/day_record.dart';
import '../services/storage_service.dart';
import '../services/cycle_service.dart';
import 'shifts_screen.dart'; // 引入班次管理

class CycleScreen extends StatefulWidget {
  final VoidCallback onApply;
  const CycleScreen({super.key, required this.onApply});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  final _storage = StorageService();
  List<Shift> _shifts = [];
  List<String?> _cycle = [];
  DateTime _start = DateTime.now();
  int _days = 30;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _storage.loadShifts();
    if (!mounted) return;
    setState(() {
      _shifts = s;
      // 如果周期是空的，默认给几个空位，让用户自己选
      if (_cycle.isEmpty) {
        _cycle = List.generate(4, (_) => s.isNotEmpty ? s[0].id : null);
      }
      _loading = false;
    });
  }

  Future<void> _apply() async {
    // 检查是否已经有排班数据
    if (_shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先点击右上角“管理班次”添加班次！')));
      return;
    }

    final end = _start.add(Duration(days: _days - 1));
    final map = await _storage.loadRecords();
    
    // 生成排班
    final generated = CycleService.generate(start: _start, end: end, cycle: _cycle);
    
    // 合并数据（使用新的DayRecord包裹）
    generated.forEach((key, val) {
      final oldRecord = map[key];
      // 如果之前有自定义备注，保留备注，只更新班次
      map[key] = DayRecord(
        shiftId: val.shiftId, 
        note: oldRecord?.note ?? '', 
        isDone: oldRecord?.isDone ?? false
      );
    });

    await _storage.saveRecords(map);
    widget.onApply(); // 触发日历页面刷新
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('排班应用成功！')));
    }
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _start = picked);
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周期排班'), 
        centerTitle: true,
        actions: [
          // 把班次管理整合到周期排班右上角
          IconButton(
            tooltip: '管理班次',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftsScreen()));
              _load(); // 返回后重新加载班次
            },
          ),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(leading: const Icon(Icons.play_arrow), title: const Text('起始日期'), subtitle: Text(_fmt(_start)), trailing: const Icon(Icons.edit), onTap: _pickStart)),
          const SizedBox(height: 8),
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('排班天数', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(children: [
                Expanded(child: Slider(value: _days.toDouble(), min: 7, max: 90, divisions: 83, label: '$_days 天', onChanged: (v) => setState(() => _days = v.round()))),
                Text('$_days 天'),
              ]),
            ]),
          )),
          const SizedBox(height: 16),
          const Text('排班周期（按顺序循环）', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_cycle.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 64, child: Text('第 ${i + 1} 天')),
                const SizedBox(width: 8),
                Expanded(child: DropdownButton<String?>(
                  value: _cycle[i],
                  isExpanded: true,
                  items: [const DropdownMenuItem(value: null, child: Text('无班次')), ..._shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))],
                  onChanged: (v) => setState(() => _cycle[i] = v),
                )),
                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _cycle.length > 1 ? () => setState(() => _cycle.removeAt(i)) : null),
              ]),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => setState(() => _cycle.add(_shifts.isNotEmpty ? _shifts[0].id : null)), icon: const Icon(Icons.add), label: const Text('添加一天')),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _apply, 
            icon: const Icon(Icons.check), 
            label: const Text('应用排班'),
          ),
          const SizedBox(height: 12),
          Text('说明：从起始日期开始，按上面周期循环往后的 $_days 天。已存在的记录会被覆盖。', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}