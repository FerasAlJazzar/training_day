import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

const categories = [
  'General',
  'Work',
  'Personal',
  'Shopping',
  'Health',
  'Learning',
];

class AddTodoSheet extends StatefulWidget {
  final Todo? todo;

  const AddTodoSheet({super.key, this.todo});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.todo?.title ?? '');
    _descCtrl = TextEditingController(text: widget.todo?.description ?? '');
    _category = widget.todo?.category ?? categories.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Task' : 'New Task',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleCtrl,
              autofocus: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What do you need to do?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.task_alt),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add some details...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? 'Save Changes' : 'Add Task'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    theme.textTheme.labelLarge?.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    if (_isEditing) {
      final updated = widget.todo!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
      );
      TodoService.updateTodo(widget.todo!.id, updated);
    } else {
      final todo = Todo(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        createdAt: now,
      );
      TodoService.addTodo(todo);
    }
    Navigator.of(context).pop();
  }
}
