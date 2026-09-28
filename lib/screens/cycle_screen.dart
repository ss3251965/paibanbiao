import 'package:flutter/material.dart';
import '../models/day_record.dart';
import '../services/storage_service.dart';
import '../services/cycle_service.dart';

class CycleScreen extends StatefulWidget {
  final VoidCallback onApply;

  const CycleScreen({
    super.key,
    required this.onApply,
  });

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  final _storage = StorageService();

  List<String> _cycle = [];

  DateTime _start = DateTime.now();

  int _days = 30;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      // 默认给4个空位，让用户自己输入
      if (_cycle.isEmpty) {
        _cycle = List.generate(4, (_) => '');
      }

      _loading = false;
    });
  }

  Future<void> _apply() async {
    // 过滤掉空白的训练项目
    final validCycle = _cycle
        .where((c) => c.trim().isNotEmpty)
        .toList();

    if (validCycle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少输入一个训练项目！'),
        ),
      );
      return;
    }

    final end =
        _start.add(Duration(days: _days - 1));

    final map =
        await _storage.loadRecords();

    // 生成训练计划
    final generated =
        CycleService.generate(
      start: _start,
      end: end,
      cycle: validCycle,
    );

    // 合并数据
    // 保留原有详细说明和完成状态
    generated.forEach((key, val) {
      final oldRecord = map[key];

      map[key] = DayRecord(
        note: val.note,
        detail: oldRecord?.detail ?? '',
        isDone: oldRecord?.isDone ?? false,
      );
    });

    await _storage.saveRecords(map);

    widget.onApply();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('训练计划应用成功！'),
        ),
      );
    }
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周期训练计划'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.play_arrow),
                    title:
                        const Text('起始日期'),
                    subtitle:
                        Text(_fmt(_start)),
                    trailing:
                        const Icon(Icons.edit),
                    onTap: _pickStart,
                  ),
                ),

                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '计划天数',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value:
                                    _days.toDouble(),
                                min: 7,
                                max: 90,
                                divisions: 83,
                                label:
                                    '$_days 天',
                                onChanged: (v) {
                                  setState(() {
                                    _days =
                                        v.round();
                                  });
                                },
                              ),
                            ),
                            Text('$_days 天'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  '训练周期（输入文字，按顺序循环）',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                ...List.generate(
                  _cycle.length,
                  (i) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text(
                              '第 ${i + 1} 天',
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child:
                                TextFormField(
                              initialValue:
                                  _cycle[i],
                              decoration:
                                  const InputDecoration(
                                hintText:
                                    '如：胸、背、腿、休息',
                                isDense: true,
                                contentPadding:
                                    EdgeInsets
                                        .symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                                border:
                                    OutlineInputBorder(),
                              ),
                              onChanged: (v) =>
                                  _cycle[i] = v,
                            ),
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons
                                  .remove_circle_outline,
                            ),
                            onPressed:
                                _cycle.length > 1
                                    ? () {
                                        setState(() {
                                          _cycle
                                              .removeAt(
                                            i,
                                          );
                                        });
                                      }
                                    : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _cycle.add('');
                    });
                  },
                  icon: const Icon(Icons.add),
                  label:
                      const Text('添加一天'),
                ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _apply,
                  icon:
                      const Icon(Icons.check),
                  label:
                      const Text('应用训练计划'),
                ),

                const SizedBox(height: 12),

                Text(
                  '说明：从起始日期开始，按上面周期循环往后的 $_days 天。已有日期的训练项目会更新，原有详细说明和完成状态会保留。',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Theme.of(context)
                            .hintColor,
                  ),
                ),
              ],
            ),
    );
  }
}