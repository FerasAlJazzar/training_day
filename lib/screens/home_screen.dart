import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/todo_tile.dart';

enum SortBy { newest, oldest, name, activeFirst }
enum FilterBy { all, active, done }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _allTodos = [];
  List<Todo> _filtered = [];
  bool _isSearching = false;
  bool _loaded = false;
  final _searchCtrl = TextEditingController();
  SortBy _sortBy = SortBy.newest;
  FilterBy _filterBy = FilterBy.all;

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
      _allTodos = TodoService.getTodos();
      _applyFilters();
      _loaded = true;
    });
  }

  void _applyFilters() {
    var list = List<Todo>.from(_allTodos);

    switch (_filterBy) {
      case FilterBy.active:
        list = list.where((t) => !t.isCompleted).toList();
      case FilterBy.done:
        list = list.where((t) => t.isCompleted).toList();
      case FilterBy.all:
        break;
    }

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

  void _deleteTodo(Todo todo) {
    TodoService.deleteTodo(todo.id);
    _loadTodos();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${todo.title}" deleted'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            TodoService.addTodo(todo);
            _loadTodos();
          },
        ),
      ),
    );
  }

  int get _completedCount => _allTodos.where((t) => t.isCompleted).length;
  int get _activeCount => _allTodos.length - _completedCount;
  double get _progress =>
      _allTodos.isEmpty ? 0 : _completedCount / _allTodos.length;

  // ─────────────────────────────── date grouping ───────────────────────────────

  Map<String, List<Todo>> _groupByDate(List<Todo> todos) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<Todo>>{};
    for (final t in todos) {
      final day = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else if (day.isAfter(weekAgo) || day == weekAgo) {
        label = 'This Week';
      } else {
        label = DateFormat('MMMM yyyy').format(t.createdAt);
      }
      groups.putIfAbsent(label, () => []);
      groups[label]!.add(t);
    }
    final order = ['Today', 'Yesterday', 'This Week'];
    final sorted = groups.entries.toList()
      ..sort((a, b) {
        final ai = order.indexOf(a.key);
        final bi = order.indexOf(b.key);
        if (ai != -1 && bi != -1) return ai.compareTo(bi);
        if (ai != -1) return -1;
        if (bi != -1) return 1;
        return -a.key.compareTo(b.key);
      });
    return {for (final e in sorted) e.key: e.value};
  }

  // ────────────────────────────────── build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noResults = _searchCtrl.text.isNotEmpty && _filtered.isEmpty;
    final showEmptyState = _allTodos.isEmpty;

    if (!_loaded) {
      return Scaffold(
        appBar: _normalAppBar(theme),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _isSearching ? _searchAppBar() : _normalAppBar(theme),
      body: Column(
        children: [
          if (!_isSearching) _buildFilterBar(theme),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showEmptyState
                  ? _emptyState(theme)
                  : _buildBody(theme, noResults),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton(
              onPressed: _openAddSheet,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildBody(ThemeData theme, bool noResults) {
    if (noResults) {
      return Center(
        key: const ValueKey('no_results'),
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

    final groups = _groupByDate(_filtered);

    return RefreshIndicator(
      onRefresh: () async => _loadTodos(),
      child: ListView(
        key: const ValueKey('list'),
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          _buildProgressSection(theme),
          for (final entry in groups.entries) ...[
            _buildSectionHeader(theme, entry.key, entry.value.length),
            for (final todo in entry.value)
              TodoTile(
                todo: todo,
                onChanged: _loadTodos,
                onDelete: () => _deleteTodo(todo),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$_activeCount active',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6))),
              const SizedBox(width: 4),
              Text('·',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.3))),
              const SizedBox(width: 4),
              Text('$_completedCount done',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6))),
              const Spacer(),
              Text('${(_progress * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String label, int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, label == 'Today' || label == 'Yesterday' ? 16 : 24, 20, 4),
      child: Row(
        children: [
          Text(label,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── app bar ────────────────────────────

  AppBar _normalAppBar(ThemeData theme) => AppBar(
        title: Text('Taskify',
            style:
                theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true)),
        ],
      );

  AppBar _searchAppBar() => AppBar(
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
              hintText: 'Search tasks...', border: InputBorder.none),
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

  // ──────────────────────────── filter bar ────────────────────────────

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _filterChip(theme, 'All', FilterBy.all),
          const SizedBox(width: 8),
          _filterChip(theme, 'Active', FilterBy.active),
          const SizedBox(width: 8),
          _filterChip(theme, 'Done', FilterBy.done),
          const Spacer(),
          PopupMenuButton<SortBy>(
            icon: Icon(Icons.sort_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            onSelected: (v) => setState(() {
              _sortBy = v;
              _applyFilters();
            }),
            itemBuilder: (_) => [
              for (final s in SortBy.values)
                PopupMenuItem(
                  value: s,
                  child: Text(_sortLabel(s),
                      style: _sortBy == s
                          ? TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)
                          : null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(ThemeData theme, String label, FilterBy value) {
    final selected = _filterBy == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filterBy = value;
        _applyFilters();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _sortLabel(SortBy s) {
    switch (s) {
      case SortBy.newest:
        return 'Newest';
      case SortBy.oldest:
        return 'Oldest';
      case SortBy.name:
        return 'Name';
      case SortBy.activeFirst:
        return 'Active first';
    }
  }



  Widget _emptyState(ThemeData theme) {
    final now = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Center(
      key: const ValueKey('empty'),
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
            Text('No tasks yet',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tap the + button to add your first task',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}
