import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistWidget extends StatefulWidget {
  final String eventId;

  const ChecklistWidget({super.key, required this.eventId});

  @override
  State<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  late final Stream<QuerySnapshot> _checklistStream;

  @override
  void initState() {
    super.initState();
    _checklistStream = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('checklist')
        .snapshots();
  }

  Future<void> _updateTaskStatus(String taskId, bool isCompleted) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('checklist')
        .doc(taskId)
        .update({'isCompleted': isCompleted});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Checklist des Tâches', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _checklistStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement de la checklist.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aucune tâche définie pour cet événement.'),
                  ));
                }

                final tasks = snapshot.data!.docs;
                final completedTasks = tasks.where((task) => (task.data() as Map<String, dynamic>)['isCompleted'] == true).length;
                final progress = tasks.isEmpty ? 0.0 : completedTasks / tasks.length;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${(progress * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final taskData = task.data() as Map<String, dynamic>;
                        return CheckboxListTile(
                          title: Text(taskData['title'] ?? 'Tâche sans nom'),
                          value: taskData['isCompleted'] ?? false,
                          onChanged: (bool? value) {
                            if (value != null) {
                              _updateTaskStatus(task.id, value);
                            }
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
