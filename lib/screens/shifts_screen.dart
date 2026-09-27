import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../services/storage_service.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final _storage = StorageService();
  List<Shift> _shifts = [];
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
      _loading = false;
    });
  }

  Future<void> _save() => _storage.saveShifts(_shifts);

  Future<void> _addOrEdit([Shift? existing]) async {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final shortCtl = TextEditingController(text: existing?.short ?? '');
    int colorValue = existing?.colorValue ?? 0xFF4A6CF7;
    const palette = [0xFF4A6CF7, 0xFF34C759, 0xFFFF9500, 0xFF5856D6, 0xFFFF3B30, 0xFF8E8E93, 0xFF00BCD4, 0xFFE91E63];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? '新建班次' : '编辑班次'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: '名称（如：早班）')),
                const SizedBox(height: 8),
                TextField(controller: shortCtl, maxLength: 2, decoration: const InputDecoration(labelText: '简称（1-2 字）')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: palette.map((c) => GestureDetector(
                    onTap: () => setSt(() => colorValue = c),
                    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(c), borderRadius: BorderRadius.circular(8), border: colorValue == c ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null)),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) return;
    final short = shortCtl.text.trim().isEmpty ? name.substring(0, 1) : shortCtl.text.trim();

    setState(() {
      if (existing == null) {
        _shifts.add(Shift(id: 'shift_${DateTime.now().millisecondsSinceEpoch}', name: name, short: short, colorValue: colorValue));
      } else {
        final i = _shifts.indexOf(existing);
        _shifts[i] = Shift(id: existing.id, name: name, short: short, colorValue: colorValue);
      }
    });
    await _save();
  }

  Future<void> _delete(Shift s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除班次？'),
        content: Text('确定要删除“${s.name}”吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _shifts.remove(s));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('班次管理'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addOrEdit(), icon: const Icon(Icons.add), label: const Text('新建班次')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: _shifts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final s = _shifts[i];
          return ListTile(
            leading: Container(width: 26, height: 26, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(8))),
            title: Text(s.name),
            subtitle: Text('简称：${s.short}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEdit(s)),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(s)),
            ]),
          );
        },
      ),
    );
  }
}