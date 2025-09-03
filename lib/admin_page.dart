import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:beh/widgets/service_detail_modal.dart';
import 'package:beh/models/service.dart';
import 'package:beh/models/event.dart';
import 'package:beh/event_details_page.dart';
import 'package:beh/event_creation_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  final _usersRef = FirebaseFirestore.instance.collection('users');
  final _adminsRef = FirebaseFirestore.instance.collection('admins');
  final _servicesRef = FirebaseFirestore.instance.collection('services');
  final _ticketsRef = FirebaseFirestore.instance.collection('tickets');
  final _transactionsRef = FirebaseFirestore.instance.collection('transactions');
  final _configRef = FirebaseFirestore.instance.collection('config');

  bool _isAuthorized = false;
  bool _loading = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _checkAuthorization();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logAction(String action, {String? target, Map<String, dynamic>? details}) async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('admin_logs').add({
        'action': action,
        'target': target ?? '',
        'details': details ?? {},
        'adminId': current?.uid ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Swallow logging errors to avoid blocking admin actions
    }
  }

  Future<void> _checkAuthorization() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        context.go('/signin');
      }
      return;
    }

    try {
      // Do Firestore reads with a timeout to avoid hanging the UI indefinitely.
      final doc = await _usersRef.doc(user.uid).get().timeout(const Duration(seconds: 10));
      if (!mounted) return;

      // Primary role source is users doc. If missing, fall back to admins collection.
      var role = doc.data()?['role'];
      if (role == null) {
        final adminDoc = await _adminsRef.doc(user.uid).get().timeout(const Duration(seconds: 5));
        if (adminDoc.exists) role = 'admin';
      }

      setState(() {
        _isAuthorized = role == 'admin' || role == 'superadmin';
        _loading = false;
      });

      if (!_isAuthorized) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accès administrateur requis')));
        // Use GoRouter navigation to avoid mixing navigation systems which may cause loops.
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _addAdminByEmail(String email) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final query = await _usersRef.where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isEmpty) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Utilisateur introuvable')));
        return;
      }
      final userDoc = query.docs.first;
      final uid = userDoc.id;
      final current = FirebaseAuth.instance.currentUser;
      // Set role on users document
      await _usersRef.doc(uid).set({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': current?.uid ?? 'unknown',
      }, SetOptions(merge: true));

      // Create corresponding admins doc for quick admin listing / metadata
      await _adminsRef.doc(uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': current?.uid ?? uid,
      });

      await _logAction('add_admin', target: uid, details: {'email': email});

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Administrateur ajouté')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _removeAdmin(String uid, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Retirer $email des administrateurs ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Set role to 'user' to demote cleanly
      await _usersRef.doc(uid).set({'role': 'user', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      // Remove admin doc if exists
      await _adminsRef.doc(uid).delete().catchError((_) {});
      await _logAction('remove_admin', target: uid, details: {'email': email});
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Administrateur rétrogradé')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  void _showAddAdminDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un administrateur'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final email = controller.text.trim();
              Navigator.of(context).pop();
              if (email.isNotEmpty) _addAdminByEmail(email);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlockUser(String uid, bool block) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _usersRef.doc(uid).update({'blocked': block});
      await _logAction(block ? 'block_user' : 'unblock_user', target: uid);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(block ? 'Utilisateur bloqué' : 'Utilisateur débloqué')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _addService(Map<String, dynamic> serviceData) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final doc = await _servicesRef.add({
        ...serviceData,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _logAction('add_service', target: doc.id, details: serviceData);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Prestation ajoutée')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _updateService(String id, Map<String, dynamic> data) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
  await _servicesRef.doc(id).update(data);
  await _logAction('update_service', target: id, details: data);
  scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Prestation mise à jour')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _resolveTicket(String id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _ticketsRef.doc(id).update({'status': 'resolved', 'resolvedAt': FieldValue.serverTimestamp()});
      await _logAction('resolve_ticket', target: id);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Ticket résolu')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Widget _buildDashboard() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('events').get().then((q) => q.size),
        FirebaseFirestore.instance.collection('users').get().then((q) => q.size),
        _transactionsRef.get().then((q) => q.docs),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));

        final eventsCount = snapshot.data?[0] ?? 0;
        final usersCount = snapshot.data?[1] ?? 0;
        final transactions = snapshot.data?[2] as List<QueryDocumentSnapshot>? ?? [];
        double totalRevenue = 0;
        for (final t in transactions) {
          final tRaw = t.data();
          final val = (tRaw is Map<String, dynamic>) ? tRaw['amount'] : null;
          if (val is num) totalRevenue += val.toDouble();
        }

        return RefreshIndicator(
          onRefresh: _handleAdminRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tableau de bord', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _infoCard('Événements', eventsCount.toString()),
                      _infoCard('Utilisateurs', usersCount.toString()),
                      _infoCard('Revenu total', '${totalRevenue.toStringAsFixed(0)} FCFA'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(String title, String value) => Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
      );

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Aucun utilisateur.'));
        return RefreshIndicator(
          onRefresh: _handleAdminRefresh,
          child: ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              final dRaw = d.data();
              final data = (dRaw is Map<String, dynamic>) ? dRaw : <String, dynamic>{};
              final email = data['email'] ?? '—';
              final blocked = data['blocked'] ?? false;
              final role = (data['role'] ?? '').toString().toLowerCase();
              final isAdmin = role == 'admin' || role == 'superadmin' || role.contains('admin');
              final createdAt = data['createdAt'] ?? data['updatedAt'];
              return ListTile(
                title: Text(email),
                subtitle: Text('UID: ${d.id} • Créé: ${_formatTimestamp(createdAt)}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  // Promote / Demote admin
                  IconButton(
                    icon: Icon(isAdmin ? Icons.person_remove : Icons.admin_panel_settings, color: isAdmin ? Colors.red : Colors.blue),
                    tooltip: isAdmin ? 'Démouvoir' : 'Promouvoir',
                    onPressed: () => isAdmin ? _removeAdmin(d.id, email) : _promoteUser(d.id, email),
                  ),
                  IconButton(
                    icon: Icon(blocked ? Icons.lock : Icons.lock_open, color: blocked ? Colors.red : Colors.green),
                    onPressed: () => _toggleBlockUser(d.id, !blocked),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_outlined),
                    onPressed: () => _showUserActivity(d.id),
                  ),
                ]),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _promoteUser(String uid, String email) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final current = FirebaseAuth.instance.currentUser;
      await _usersRef.doc(uid).set({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': current?.uid ?? 'unknown',
      }, SetOptions(merge: true));
      // Ensure admins collection is in sync
      await _adminsRef.doc(uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': current?.uid ?? 'unknown',
      });
      await _logAction('add_admin', target: uid, details: {'email': email});
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Administrateur ajouté')));
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  // Allow admins to pull-to-refresh their tabs
  Future<void> _handleAdminRefresh() async {
    // Trigger rebuild / refetch where applicable
    setState(() {});
    // Small delay so indicator is visible
    await Future.delayed(const Duration(milliseconds: 300));
  }

  String _formatTimestamp(dynamic t) {
    try {
      if (t == null) return '—';
      if (t is Timestamp) return t.toDate().toLocal().toString().split(' ')[0];
      if (t is DateTime) return t.toLocal().toString().split(' ')[0];
      if (t is int) return DateTime.fromMillisecondsSinceEpoch(t).toLocal().toString().split(' ')[0];
      return t.toString();
    } catch (_) {
      return t.toString();
    }
  }

  Future<void> _showUserActivity(String uid) async {
    final q = await FirebaseFirestore.instance.collection('activity_logs').where('userId', isEqualTo: uid).orderBy('timestamp', descending: true).limit(50).get();
    final items = q.docs.map((d) {
      final raw = d.data();
      try {
        return Map<String, dynamic>.from(raw as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).toList();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique activité'),
        content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(itemCount: items.length, itemBuilder: (c, i) => ListTile(title: Text(items[i]['action'] ?? '—'), subtitle: Text(_formatTimestamp(items[i]['timestamp']))))),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> _signOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Se déconnecter', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );

    if (confirm == true) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        await FirebaseAuth.instance.signOut();
        goRouter.go('/signin');
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur de déconnexion: $e')));
      }
    }
  }

  Widget _buildServicesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _servicesRef.orderBy('main_category').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        final docs = snapshot.data?.docs ?? [];

        // Group services
        final Map<String, List<QueryDocumentSnapshot>> groupedServices = {};
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final category = data?['main_category'] as String? ?? 'Non classé';
          (groupedServices[category] ??= []).add(doc);
        }

        final sortedKeys = groupedServices.keys.toList()..sort();

        return RefreshIndicator(
          onRefresh: _handleAdminRefresh,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showServiceDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter prestation'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final category = sortedKeys[index];
                    final services = groupedServices[category]!;
                    return ExpansionTile(
                      title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      initiallyExpanded: true,
                      children: services.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? '—';
                        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                        final available = data['available'] ?? true;

                        String subtitle = '';
                        if (category == 'Décoration') {
                          subtitle = data['deco_type'] ?? '';
                        } else if (category == 'Nourriture') {
                          subtitle = '${data['food_cuisine']} - ${data['food_course']}';
                        }

                        return ListTile(
                          title: Text(name),
                          subtitle: Text('$subtitle - ${price.toStringAsFixed(0)} FCFA'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(available ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => _updateService(doc.id, {'available': !available}),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showServiceDialog(docId: doc.id, initialData: data),
                              ),
                            ],
                          ),
                          onTap: () {
                            final service = Service.fromFirestore(doc);
                            showDialog(
                              context: context,
                              builder: (context) => ServiceDetailModal(service: service, isAdminView: true),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showServiceDialog({String? docId, Map<String, dynamic>? initialData}) {
    final isEditing = docId != null && initialData != null;
    final nameCtl = TextEditingController(text: isEditing ? initialData['name'] : '');
    final priceCtl = TextEditingController(text: isEditing ? initialData['price'].toString() : '');
    final descCtl = TextEditingController(text: isEditing ? initialData['description'] : '');
    final imgCtl = TextEditingController(text: isEditing ? initialData['imageUrl'] : '');

    String? mainCategory = isEditing ? initialData['main_category'] : null;
    String? decoType = isEditing ? initialData['deco_type'] : null;
    String? foodCuisine = isEditing ? initialData['food_cuisine'] : null;
    String? foodCourse = isEditing ? initialData['food_course'] : null;

    final mainCategories = ['Décoration', 'Nourriture'];
    final decoTypes = ['Simple', 'Moderne', 'Luxueuse'];
    final foodCuisines = ['Africaine', 'Européenne'];
    final foodCourses = ['Entrée', 'Plat', 'Dessert'];

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              title: Text(isEditing ? 'Modifier prestation' : 'Ajouter prestation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: mainCategory,
                      hint: const Text('Catégorie principale'),
                      items: mainCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (value) => setState(() => mainCategory = value),
                      decoration: const InputDecoration(labelText: 'Catégorie principale'),
                    ),
                    if (mainCategory == 'Décoration') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: decoType,
                        hint: const Text('Type de décoration'),
                        items: decoTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (value) => setState(() => decoType = value),
                        decoration: const InputDecoration(labelText: 'Type de décoration'),
                      ),
                    ],
                    if (mainCategory == 'Nourriture') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: foodCuisine,
                        hint: const Text('Type de cuisine'),
                        items: foodCuisines.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (value) => setState(() => foodCuisine = value),
                        decoration: const InputDecoration(labelText: 'Cuisine'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: foodCourse,
                        hint: const Text('Type de plat'),
                        items: foodCourses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (value) => setState(() => foodCourse = value),
                        decoration: const InputDecoration(labelText: 'Plat'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Nom')),
                    TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Prix'), keyboardType: TextInputType.number),
                    TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Description')),
                    TextField(controller: imgCtl, decoration: const InputDecoration(labelText: 'URL de l\'image'))
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
                TextButton(
                  onPressed: () {
                    final name = nameCtl.text.trim();
                    final price = double.tryParse(priceCtl.text.trim()) ?? 0.0;
                    final description = descCtl.text.trim();
                    final imageUrl = imgCtl.text.trim();

                    if (name.isEmpty || mainCategory == null) return;

                    Map<String, dynamic> serviceData = {
                      'name': name,
                      'price': price,
                      'description': description,
                      'imageUrl': imageUrl,
                      'main_category': mainCategory,
                    };

                    if (mainCategory == 'Décoration') {
                      if (decoType == null) return;
                      serviceData['deco_type'] = decoType;
                    } else if (mainCategory == 'Nourriture') {
                      if (foodCuisine == null || foodCourse == null) return;
                      serviceData['food_cuisine'] = foodCuisine;
                      serviceData['food_course'] = foodCourse;
                    }

                    Navigator.of(context).pop();
                    if (isEditing) {
                      final oldPrice = (initialData['price'] as num?)?.toDouble() ?? 0.0;
                      _updateService(docId, serviceData);
                      // If price changed, propagate to user events
                      final newPrice = price;
                      if (newPrice != oldPrice) {
                        _propagatePriceToEvents(docId, newPrice);
                      }
                    } else {
                      _addService(serviceData);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFinancialsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _transactionsRef.orderBy('timestamp', descending: true).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Aucune transaction disponible.'));
        double total = 0;
        for (final d in docs) {
          final dRaw = d.data();
          final v = (dRaw is Map<String, dynamic>) ? dRaw['amount'] : null;
          if (v is num) total += v.toDouble();
        }
        return RefreshIndicator(
          onRefresh: _handleAdminRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(16.0), child: Text('Total (dernières 50): ${total.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold))),
              ListView.builder(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, itemCount: docs.length, itemBuilder: (c, i) {
                final d = docs[i];
                final dRaw = d.data();
                final data = (dRaw is Map<String, dynamic>) ? dRaw : <String, dynamic>{};
                return ListTile(title: Text(data['description'] ?? 'Transaction'), subtitle: Text('${(data['amount'] ?? 0).toString()} FCFA'));
              }),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildConfigTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: _configRef.doc('app').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        final raw = snapshot.data?.data();
        final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
        final themeName = data['themeName'] ?? 'Default';
        return RefreshIndicator(
          onRefresh: _handleAdminRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Configuration globale', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                const SizedBox(height: 12),
                ListTile(title: const Text('Theme'), subtitle: Text(themeName), trailing: TextButton(onPressed: _editConfig, child: const Text('Modifier'))),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _editConfig() async {
    final doc = await _configRef.doc('app').get();
    if (!mounted) return;
    final raw = doc.data();
    final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
    final themeCtl = TextEditingController(text: data['themeName'] ?? 'Default');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier configuration'),
        content: TextField(controller: themeCtl, decoration: const InputDecoration(labelText: 'Theme Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(onPressed: () async {
            final val = themeCtl.text.trim();
            await _configRef.doc('app').set({'themeName': val});
            await _logAction('update_config', details: {'themeName': val});
            if (!mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuration mise à jour')));
          }, child: const Text('Enregistrer')),
        ],
      ),
    );
  }

  Widget _buildSupportTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ticketsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Aucun ticket.'));
        return RefreshIndicator(
          onRefresh: _handleAdminRefresh,
          child: ListView.builder(itemCount: docs.length, itemBuilder: (c, i) {
            final d = docs[i];
            final dRaw = d.data();
            final data = (dRaw is Map<String, dynamic>) ? dRaw : <String, dynamic>{};
            final subj = data['subject'] ?? '—';
            final status = data['status'] ?? 'open';
            final userEmail = data['email'] ?? '—';
            return ListTile(title: Text(subj), subtitle: Text('Utilisateur: $userEmail — Statut: $status'), trailing: status == 'open' ? TextButton(child: const Text('Résoudre'), onPressed: () => _resolveTicket(d.id)) : null);
          }),
        );
      },
    );
  }

  /// Propagate a service price change to all events that have selected this service.
  /// Only updates `price` and `totalPrice` fields inside `events/{eventId}/selected_prestations/{serviceId}`.
  Future<void> _propagatePriceToEvents(String serviceId, double newPrice) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // Fetch all events that have a selected_prestations doc for this service
      final eventsQuery = await FirebaseFirestore.instance.collection('events').get();
      final batch = FirebaseFirestore.instance.batch();
      int updates = 0;

      for (final eventDoc in eventsQuery.docs) {
        final selRef = eventDoc.reference.collection('selected_prestations').doc(serviceId);
        final selSnap = await selRef.get();
        if (!selSnap.exists) continue;
  final selData = selSnap.data() ?? <String, dynamic>{};
  final quantity = (selData['quantity'] as num?)?.toInt() ?? 0;
        final updated = {
          'price': newPrice,
          'totalPrice': newPrice * quantity,
        };
        batch.update(selRef, updated);
        updates += 1;
      }

      if (updates > 0) {
        await batch.commit();
      }

      await _logAction('propagate_price', target: serviceId, details: {'newPrice': newPrice, 'updatedEntries': updates});
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('Prix propagé vers $updates prestations sélectionnées')));
    } catch (e) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur propagation prix: ${e.toString()}')));
    }
  }

  Future<void> _showRegistrantsForEventType(String eventType) async {
    final parentContext = context;
    // Avoid a composite index requirement by not ordering here; keep it simple for the admin list.
    final q = await FirebaseFirestore.instance.collection('events').where('eventType', isEqualTo: eventType).limit(200).get();
    final docs = q.docs;
    if (!mounted) return;

    showDialog<void>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Inscrits — ${eventType[0].toUpperCase()}${eventType.substring(1)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: docs.isEmpty
              ? const Text('Aucun inscrit pour ce type d\'événement.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>? ?? {};
                    final name = data['name'] ?? data['eventName'] ?? 'Événement';
                    final createdBy = data['createdBy'] ?? data['userId'] ?? '—';
                    final date = data['date'] ?? data['createdAt'];
          return ListTile(
                      title: Text('$name'),
                      subtitle: Text('UID: $createdBy • ${_formatTimestamp(date)}'),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
            // Show a lightweight details dialog for admins instead of navigating into the full user screen
            if (d.id.isNotEmpty) _showEventDetailsDialog(d.id, parentContext);
                      },
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> _showSetBasePriceDialog(String eventType) async {
  final parentContext = context;
  final configDoc = await _configRef.doc('base_prices').get();
    final raw = configDoc.data();
    final existing = (raw is Map<String, dynamic>) ? (raw[eventType] as num?)?.toDouble() : null;
    final priceCtl = TextEditingController(text: existing != null ? existing.toStringAsFixed(0) : '');
    bool propagate = false;

    await showDialog<void>(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setState) {
        // dialogContext is the dialog's BuildContext; use parentContext for navigation and SnackBars
        final rootContext = parentContext;
        return AlertDialog(
          title: Text('Fixer le prix de base — ${eventType[0].toUpperCase()}${eventType.substring(1)}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Prix (FCFA)'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            CheckboxListTile(value: propagate, onChanged: (v) => setState(() => propagate = v ?? false), title: const Text('Propager aux événements existants')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
            TextButton(onPressed: () async {
              final val = double.tryParse(priceCtl.text.trim());
              Navigator.of(dialogContext).pop();
              if (val == null) return;
              // Save to config/base_prices
              await _configRef.doc('base_prices').set({eventType: val}, SetOptions(merge: true));
              await _logAction('set_base_price', target: eventType, details: {'price': val, 'propagate': propagate});
              if (propagate) {
                // Update matching events with a 'basePrice' field
                final q = await FirebaseFirestore.instance.collection('events').where('eventType', isEqualTo: eventType).get();
                final batch = FirebaseFirestore.instance.batch();
                int updated = 0;
                for (final doc in q.docs) {
                  batch.update(doc.reference, {'basePrice': val});
                  updated += 1;
                }
                if (updated > 0) await batch.commit();
                if (mounted) ScaffoldMessenger.of(rootContext).showSnackBar(SnackBar(content: Text('Prix fixé et propagé à $updated événements')));
              } else {
                if (mounted) ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Prix de base enregistré')));
              }
            }, child: const Text('Enregistrer')),
          ],
        );
      }),
    );
  }

  /// Show a compact event details dialog for admin so they can inspect an event without navigating
  Future<void> _showEventDetailsDialog(String eventId, BuildContext parentContext) async {
    try {
      final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        if (mounted) ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Événement introuvable')));
        return;
      }

      final eventData = eventDoc.data() as Map<String, dynamic>? ?? {};
      final event = Event.fromFirestore(eventDoc);

      final prestationsSnap = await eventDoc.reference.collection('selected_prestations').get();
      final prestations = prestationsSnap.docs.map((d) => d.data()).toList();
      final spentBudget = prestations.fold<double>(0.0, (sum, p) => sum + ((p['totalPrice'] as num?)?.toDouble() ?? 0.0));

      if (!mounted) return;

      showDialog<void>(
        context: parentContext,
        builder: (context) {
          return AlertDialog(
            title: Text(event.eventName),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Type: ${event.eventType}'),
                  const SizedBox(height: 8),
                  Text('Date: ${_formatTimestamp(eventData['date'] ?? eventData['createdAt'])}'),
                  const SizedBox(height: 8),
                  Text('Budget: ${event.budget.toStringAsFixed(0)} FCFA'),
                  const SizedBox(height: 8),
                  Text('Dépensé: ${spentBudget.toStringAsFixed(0)} FCFA'),
                  const SizedBox(height: 12),
                  const Text('Prestations sélectionnées:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (prestations.isEmpty) const Text('Aucune prestation sélectionnée.'),
                  if (prestations.isNotEmpty)
                    ...prestations.map((p) {
                      final name = p['name'] ?? p['serviceName'] ?? 'Prestation';
                      final qty = (p['quantity'] as num?)?.toInt() ?? 0;
                      final price = (p['price'] as num?)?.toDouble() ?? 0.0;
                      final total = (p['totalPrice'] as num?)?.toDouble() ?? (price * qty);
                      return ListTile(title: Text('$name'), subtitle: Text('x$qty • ${price.toStringAsFixed(0)} FCFA'), trailing: Text('${total.toStringAsFixed(0)} FCFA'));
                    }).toList(),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
              TextButton(onPressed: () {
                Navigator.of(context).pop();
                // Open EventDetailsPage directly via Navigator to avoid switching the app shell
                Navigator.of(parentContext).push(MaterialPageRoute(
                  builder: (c) => EventDetailsPage(eventId: eventId),
                  fullscreenDialog: true,
                ));
              }, child: const Text('Ouvrir')),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Widget _buildMyServicesTab() {
    // Reuse the same 4 default service tiles shown to users in ServiceCatalogPage.
    final defaultServices = [
      {
        'title': 'MARIAGES',
        'description': 'Organisation complète',
        'price': 'À partir de 500,000 FCFA',
        'icon': Icons.favorite_border,
        'image': 'assets/images/wedding.jpg',
        'eventType': 'mariage',
      },
      {
        'title': 'ANNIVERSAIRES',
        'description': 'Fêtes personnalisées',
        'price': 'À partir de 150,000 FCFA',
        'icon': Icons.cake_outlined,
        'image': 'assets/images/birthday.jpg',
        'eventType': 'anniversaire',
      },
      {
        'title': 'CONFÉRENCES',
        'description': 'Événements professionnels',
        'price': 'Sur devis',
        'icon': Icons.business_center_outlined,
        'image': 'assets/images/conference.jpg',
        'eventType': 'conference',
      },
      {
        'title': 'CÉRÉMONIES FUNÉRAIRES',
        'description': 'Hommages et organisation',
        'price': 'Sur devis',
        'icon': Icons.church_outlined,
        'image': 'assets/images/funeral.jpg',
        'eventType': 'funerailles',
      },
    ];

    final basePricesStream = _configRef.doc('base_prices').snapshots();
    return StreamBuilder<DocumentSnapshot>(
      stream: basePricesStream,
      builder: (context, snap) {
        final baseData = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        return RefreshIndicator(
          onRefresh: _handleAdminRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: defaultServices.length,
            itemBuilder: (context, index) {
              final service = defaultServices[index];
              final eventType = service['eventType'] as String;
              final baseVal = baseData[eventType];
              final originalPrice = service['price'] as String;
              final prefixMatch = RegExp(r'^\D*').firstMatch(originalPrice);
              final prefix = prefixMatch?.group(0) ?? '';
              final priceText = (baseVal is num) ? '$prefix${baseVal.toDouble().toStringAsFixed(0)} FCFA' : originalPrice;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 150,
                      color: Theme.of(context).colorScheme.secondary.withAlpha(51),
                      child: Center(
                        child: Icon(
                          service['icon'] as IconData,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(service['title'] as String, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(service['description'] as String, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text(priceText, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => _showRegistrantsForEventType(service['eventType'] as String), child: const Text('Inscrits')),
                          const SizedBox(width: 8),
                          TextButton(onPressed: () => _showSetBasePriceDialog(service['eventType'] as String), child: const Text('Fixer prix')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final eventType = service['eventType'] as String;
                              // Open EventCreationPage via Navigator so admin doesn't switch the main shell
                              Navigator.of(context).push(MaterialPageRoute(builder: (c) => EventCreationPage(eventType: eventType)));
                            },
                            child: const Text('Réserver maintenant'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthorized) {
      return const Scaffold(body: Center(child: Text('Accès non autorisé')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withAlpha(217),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Prestations'),
            Tab(text: 'Mes Services'), // New tab
            Tab(text: 'Finances'),
            Tab(text: 'Configuration'),
            Tab(text: 'Support'),
          ],
        ),
        actions: [
          IconButton(onPressed: () => context.push('/profile'), icon: const Icon(Icons.person)),
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
          IconButton(onPressed: _showAddAdminDialog, icon: const Icon(Icons.person_add)),
        ],
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildDashboard(),
        _buildUsersTab(),
        _buildServicesTab(),
        _buildMyServicesTab(), // New tab content
        _buildFinancialsTab(),
        _buildConfigTab(),
        _buildSupportTab(),
      ]),
    );
  }
}
