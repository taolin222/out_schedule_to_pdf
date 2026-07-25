import 'package:flutter/material.dart';
import '../models/module_keys.dart';
import '../services/persistence_service.dart';

class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  List<String> _modules = [];
  bool _loaded = false;
  bool _saving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final stored = await PersistenceService.getModuleOrder();
      if (!mounted) return;
      setState(() {
        _modules = ModuleKeys.fromStored(stored);
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modules = ModuleKeys.defaultOrder;
        _loaded = true;
      });
    }
  }

  Future<void> _saveOrder() async {
    setState(() => _saving = true);
    try {
      await PersistenceService.saveModuleOrder(ModuleKeys.toStored(_modules));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSave = _isDirty && !_saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('模块排序'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          // 右上角保存按钮
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                height: 34,
                child: TextButton(
                  onPressed: canSave ? _saveOrder : null,
                  style: TextButton.styleFrom(
                    foregroundColor: canSave ? theme.colorScheme.primary : const Color(0xFFD1D5DB),
                    backgroundColor: canSave ? theme.colorScheme.primaryContainer : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: _saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('保存', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loaded
          ? ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.all(16),
              itemCount: _modules.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _modules.removeAt(oldIndex);
                  _modules.insert(newIndex, item);
                  _isDirty = true;
                });
              },
              itemBuilder: (context, index) {
                return Card(
                  key: ValueKey(_modules[index]),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator),
                    ),
                    title: Text(_modules[index], style: const TextStyle(fontSize: 16)),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator),
                    ),
                  ),
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
