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

  void _showToast(String message) {
    final overlay = Overlay.of(context);
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1200), () => entry?.remove());
  }

  Future<void> _saveOrder() async {
    setState(() => _saving = true);
    try {
      await PersistenceService.saveModuleOrder(ModuleKeys.toStored(_modules));
      if (!mounted) return;
      _showToast('✓ 保存成功');
      await Future.delayed(const Duration(milliseconds: 500));
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canSave ? _saveOrder : null,
        backgroundColor: canSave ? theme.colorScheme.primary : const Color(0xFFD1D5DB),
        foregroundColor: canSave ? Colors.white : const Color(0xFF9CA3AF),
        elevation: canSave ? 4 : 0,
        icon: _saving
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
        label: Text(_saving ? '保存中...' : '保存顺序'),
      ),
    );
  }
}
