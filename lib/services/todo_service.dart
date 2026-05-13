import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo.dart';

class TodoService {
  static const _boxName = 'todos_box';
  static const _key = 'todos_list';

  static late Box<String> _box;

  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  static List<Todo> getTodos() {
    final json = _box.get(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Todo.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveTodos(List<Todo> todos) async {
    final json = jsonEncode(todos.map((e) => e.toMap()).toList());
    await _box.put(_key, json);
  }

  static Future<void> addTodo(Todo todo) async {
    final todos = getTodos();
    todos.insert(0, todo);
    await saveTodos(todos);
  }

  static Future<void> updateTodo(String id, Todo updated) async {
    final todos = getTodos();
    final index = todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      todos[index] = updated;
      await saveTodos(todos);
    }
  }

  static Future<void> deleteTodo(String id) async {
    final todos = getTodos();
    todos.removeWhere((t) => t.id == id);
    await saveTodos(todos);
  }

  static Future<void> toggleTodo(String id) async {
    final todos = getTodos();
    final index = todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      todos[index].isCompleted = !todos[index].isCompleted;
      await saveTodos(todos);
    }
  }
}
