import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Master Pro',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Map<String, dynamic>> tasks = [];
  TextEditingController taskController = TextEditingController();

  // Feature variables
  String selectedPriority = 'medium';
  String selectedCategory = 'Personal';
  DateTime? selectedDueDate;

  List<String> priorities = ['high', 'medium', 'low'];
  List<String> categories = ['Personal', 'Work', 'Shopping', 'Health', 'Study'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // ==================== STORAGE FUNCTIONS ====================

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert DateTime objects to strings before saving
      List<Map<String, dynamic>> tasksToSave = tasks.map((task) {
        return {
          'title': task['title'],
          'completed': task['completed'],
          'priority': task['priority'],
          'category': task['category'],
          'createdAt': task['createdAt']?.toIso8601String(),
          'dueDate': task['dueDate']?.toIso8601String(),
        };
      }).toList();

      final String tasksJson = jsonEncode(tasksToSave);
      await prefs.setString('tasks', tasksJson);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJson = prefs.getString('tasks');

      if (tasksJson != null) {
        List<dynamic> decodedTasks = jsonDecode(tasksJson);
        setState(() {
          tasks = decodedTasks.map((task) {
            return {
              'title': task['title'],
              'completed': task['completed'],
              'priority': task['priority'] ?? 'medium',
              'category': task['category'] ?? 'Personal',
              'createdAt': task['createdAt'] != null
                  ? DateTime.parse(task['createdAt'])
                  : DateTime.now(),
              'dueDate': task['dueDate'] != null
                  ? DateTime.parse(task['dueDate'])
                  : null,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  // ==================== TASK FUNCTIONS ====================

  void addTask() {
    if (taskController.text.isNotEmpty) {
      setState(() {
        String emoji = _getEmojiForCategory(selectedCategory);

        tasks.add({
          'title': '$emoji ${taskController.text}',
          'completed': false,
          'priority': selectedPriority,
          'category': selectedCategory,
          'createdAt': DateTime.now(),
          'dueDate': selectedDueDate,
        });

        taskController.clear();
        selectedDueDate = null; // Reset date after adding
      });
      _saveTasks();
    }
  }

  void toggleTask(int index) {
    setState(() {
      tasks[index]['completed'] = !tasks[index]['completed'];
    });
    _saveTasks();
  }

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
    _saveTasks();
  }

  void clearCompleted() {
    setState(() {
      tasks.removeWhere((task) => task['completed'] == true);
    });
    _saveTasks();
  }

  // ==================== HELPER FUNCTIONS ====================

  String _getEmojiForCategory(String category) {
    switch (category) {
      case 'Work':
        return '💼';
      case 'Shopping':
        return '🛒';
      case 'Health':
        return '💪';
      case 'Study':
        return '📚';
      default:
        return '📝';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    final difference = taskDate.difference(today).inDays;

    if (difference < 0) {
      return 'Overdue!';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getCardColor(Map<String, dynamic> task) {
    // Check if overdue
    if (task['dueDate'] != null &&
        DateTime.now().isAfter(task['dueDate']) &&
        !task['completed']) {
      return Colors.red[50]!;
    }

    // Color by priority
    switch (task['priority']) {
      case 'high':
        return Colors.red[50]!;
      case 'medium':
        return Colors.orange[50]!;
      case 'low':
        return Colors.green[50]!;
      default:
        return Colors.white;
    }
  }

  int _getIncompleteCount() {
    return tasks.where((task) => !task['completed']).length;
  }

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📋 My Tasks (${_getIncompleteCount()} left)'),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: clearCompleted,
            tooltip: 'Clear completed tasks',
          ),
        ],
      ),
      body: Column(
        children: [
          // ==================== INPUT SECTION ====================
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and Priority Row
                Row(
                  children: [
                    // Category Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text('${_getEmojiForCategory(category)} $category'),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    // Priority Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: priorities.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(priority),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(priority.toUpperCase()),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedPriority = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Task Input and Date Picker
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: taskController,
                        decoration: InputDecoration(
                          hintText: 'Enter a task...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        onSubmitted: (_) => addTask(),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Date Picker Button
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: Icon(
                          selectedDueDate != null ? Icons.event : Icons.event_outlined,
                          color: selectedDueDate != null ? Colors.purple : Colors.grey,
                        ),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDueDate = picked;
                            });
                          }
                        },
                        tooltip: selectedDueDate != null
                            ? DateFormat('MMM dd').format(selectedDueDate!)
                            : 'Pick due date',
                      ),
                    ),
                    SizedBox(width: 8),
                    // Add Button
                    ElevatedButton(
                      onPressed: addTask,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: Text('Add'),
                    ),
                  ],
                ),

                // Show selected due date
                if (selectedDueDate != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.event, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat('EEEE, MMM dd').format(selectedDueDate!)}',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedDueDate = null;
                            });
                          },
                          child: Text('Clear'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ==================== TASK LIST ====================
          Expanded(
            child: tasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'No tasks yet!',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add one above to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isOverdue = task['dueDate'] != null &&
                    DateTime.now().isAfter(task['dueDate']) &&
                    !task['completed'];

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: _getCardColor(task),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: Checkbox(
                      value: task['completed'],
                      onChanged: (bool? value) {
                        toggleTask(index);
                      },
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task title
                        Text(
                          task['title'],
                          style: TextStyle(
                            decoration: task['completed']
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Tags row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Category chip
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                task['category'],
                                style: TextStyle(fontSize: 10, color: Colors.blue[900]),
                              ),
                            ),
                            // Priority indicator
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(task['priority']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(task['priority']),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    task['priority'].toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getPriorityColor(task['priority']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Created timestamp
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                'Created ${_formatDate(task['createdAt'])}',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          // Due date
                          if (task['dueDate'] != null)
                            Row(
                              children: [
                                Icon(
                                  isOverdue ? Icons.warning : Icons.event,
                                  size: 12,
                                  color: isOverdue ? Colors.red : Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Due: ${_formatDueDate(task['dueDate'])}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOverdue ? Colors.red : Colors.grey,
                                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => deleteTask(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}