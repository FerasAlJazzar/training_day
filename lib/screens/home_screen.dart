import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/todo_tile.dart';

enum SortBy { newest, oldest, name, activeFirst }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _todos = [];
  List<Todo> _filtered = [];
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  SortBy _sortBy = SortBy.newest;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadTodos() {
    setState(() {
      _todos = TodoService.getTodos();
      _applyFilters();
    });
  }

  void _applyFilters() {
    var list = List<Todo>.from(_todos);

    if (_searchCtrl.text.trim().isNotEmpty) {
      final q = _searchCtrl.text.trim().toLowerCase();
      list = list.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q);
      }).toList();
    }

    switch (_sortBy) {
      case SortBy.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortBy.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortBy.name:
        list.sort((a, b) => a.title.compareTo(b.title));
      case SortBy.activeFirst:
        list.sort((a, b) {
          if (a.isCompleted == b.isCompleted) return 0;
          return a.isCompleted ? 1 : -1;
        });
    }

    _filtered = list;
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTodoSheet(),
    ).then((_) => _loadTodos());
  }

  int get _completedCount => _todos.where((t) => t.isCompleted).length;
  int get _activeCount => _todos.length - _completedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noResults = _searchCtrl.text.isNotEmpty && _filtered.isEmpty;
    final showEmptyState = _todos.isEmpty;

    return Scaffold(
      appBar: _isSearching ? _searchAppBar(theme) : _normalAppBar(theme),
      body: showEmptyState ? _emptyState(theme) : _listView(theme, noResults),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton(
              onPressed: _openAddSheet,
              child: const Icon(Icons.add),
            ),
    );
  }

  AppBar _normalAppBar(ThemeData theme) => AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Taskify',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              '$_activeCount active  ·  $_completedCount done',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = true),
          ),
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() {
              _sortBy = v;
              _applyFilters();
            }),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: SortBy.newest,
                child: Text('Newest',
                    style: _sortBy == SortBy.newest
                        ? TextStyle(color: theme.colorScheme.primary)
                        : null),
              ),
              PopupMenuItem(
                value: SortBy.oldest,
                child: Text('Oldest',
                    style: _sortBy == SortBy.oldest
                        ? TextStyle(color: theme.colorScheme.primary)
                        : null),
              ),
              PopupMenuItem(
                value: SortBy.name,
                child: Text('Name',
                    style: _sortBy == SortBy.name
                        ? TextStyle(color: theme.colorScheme.primary)
                        : null),
              ),
              PopupMenuItem(
                value: SortBy.activeFirst,
                child: Text('Active first',
                    style: _sortBy == SortBy.activeFirst
                        ? TextStyle(color: theme.colorScheme.primary)
                        : null),
              ),
            ],
          ),
        ],
      );

  AppBar _searchAppBar(ThemeData theme) => AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchCtrl.clear();
              _applyFilters();
            });
          },
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks...',
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(_applyFilters),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                setState(_applyFilters);
              },
            ),
        ],
      );

  Widget _emptyState(ThemeData theme) {
    final now = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_rounded,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Text(now, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'No tasks yet',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first task',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listView(ThemeData theme, bool noResults) {
    if (noResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No tasks match your search',
                style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadTodos(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => TodoTile(
          todo: _filtered[i],
          onChanged: _loadTodos,
        ),
      ),
    );
  }
}
