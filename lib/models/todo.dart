enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  static Priority fromString(String s) {
    switch (s) {
      case 'High':
        return Priority.high;
      case 'Medium':
        return Priority.medium;
      default:
        return Priority.low;
    }
  }
}

class Todo {
  final String id;
  String title;
  String description;
  bool isCompleted;
  String category;
  Priority priority;
  DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.category = 'General',
    this.priority = Priority.medium,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'category': category,
        'priority': priority.label,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        isCompleted: map['isCompleted'] as bool? ?? false,
        category: map['category'] as String? ?? 'General',
        priority: PriorityX.fromString(map['priority'] as String? ?? 'Medium'),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Todo copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    String? category,
    Priority? priority,
  }) =>
      Todo(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        createdAt: createdAt,
      );
}
