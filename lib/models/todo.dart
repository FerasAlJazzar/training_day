class Todo {
  final String id;
  String title;
  String description;
  bool isCompleted;
  String category;
  DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.category = 'General',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        isCompleted: map['isCompleted'] as bool? ?? false,
        category: map['category'] as String? ?? 'General',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Todo copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    String? category,
  }) =>
      Todo(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        category: category ?? this.category,
        createdAt: createdAt,
      );
}
