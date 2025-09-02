import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pushReplacementNamed('/signin'));
      return;
    }

    try {
      final doc = await _usersRef.doc(user.uid).get();
      if (!mounted) return;
  final role = doc.data()?['role'];
      setState(() {
        _isAuthorized = role == 'admin' || role == 'superadmin';
        _loading = false;
      });
      if (!_isAuthorized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accès administrateur requis')));
          Navigator.of(context).pushReplacementNamed('/home');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _addAdminByEmail(String email) async {
    try {
      final query = await _usersRef.where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable')));
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrateur ajouté')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
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

    try {
      // Set role to 'user' to demote cleanly
      await _usersRef.doc(uid).set({'role': 'user', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      // Remove admin doc if exists
      await _adminsRef.doc(uid).delete().catchError((_) {});
      await _logAction('remove_admin', target: uid, details: {'email': email});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrateur rétrogradé')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
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
    try {
      await _usersRef.doc(uid).update({'blocked': block});
      await _logAction(block ? 'block_user' : 'unblock_user', target: uid);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(block ? 'Utilisateur bloqué' : 'Utilisateur débloqué')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _addService(String name, double price) async {
    try {
      final doc = await _servicesRef.add({
        'name': name,
        'price': price,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _logAction('add_service', target: doc.id, details: {'name': name, 'price': price});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prestation ajoutée')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _updateService(String id, Map<String, dynamic> data) async {
    try {
      await _servicesRef.doc(id).update(data);
      await _logAction('update_service', target: id, details: data);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prestation mise à jour')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _resolveTicket(String id) async {
    try {
      await _ticketsRef.doc(id).update({'status': 'resolved', 'resolvedAt': FieldValue.serverTimestamp()});
      await _logAction('resolve_ticket', target: id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket résolu')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrateur ajouté')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
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
        content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(itemCount: items.length, itemBuilder: (c, i) => ListTile(title: Text(items[i]['action'] ?? '—'), subtitle: Text(items[i]['timestamp']?.toString() ?? '—')))),
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
      try {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        context.go('/signin');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de déconnexion: $e')));
      }
    }
  }

  Widget _buildServicesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _servicesRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        final docs = snapshot.data?.docs ?? [];
        return RefreshIndicator(
          onRefresh: _handleAdminRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(onPressed: _showAddServiceDialog, icon: const Icon(Icons.add), label: const Text('Ajouter prestation')),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index];
                  final dRaw = d.data();
                  final data = (dRaw is Map<String, dynamic>) ? dRaw : <String, dynamic>{};
                  final name = data['name'] ?? '—';
                  final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
                  final available = data['available'] ?? true;
                  return ListTile(
                    title: Text(name),
                    subtitle: Text('${price.toStringAsFixed(0)} FCFA'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: Icon(available ? Icons.visibility : Icons.visibility_off), onPressed: () => _updateService(d.id, {'available': !available})),
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showEditServiceDialog(d.id, name, price)),
                    ]),
                  );
                },
              ),
            ]),
          ),
        );
      },
    );
  }

  void _showAddServiceDialog() {
    final nameCtl = TextEditingController();
    final priceCtl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter prestation'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Nom')),
          TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Prix'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final name = nameCtl.text.trim();
              final price = double.tryParse(priceCtl.text.trim()) ?? 0.0;
              Navigator.of(context).pop();
              if (name.isNotEmpty) _addService(name, price);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(String id, String name, double price) {
    final nameCtl = TextEditingController(text: name);
    final priceCtl = TextEditingController(text: price.toString());
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier prestation'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Nom')),
          TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Prix'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(onPressed: () {
            final n = nameCtl.text.trim();
            final p = double.tryParse(priceCtl.text.trim()) ?? price;
            Navigator.of(context).pop();
            _updateService(id, {'name': n, 'price': p});
          }, child: const Text('Enregistrer')),
        ],
      ),
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
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Prestations'),
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
        _buildFinancialsTab(),
        _buildConfigTab(),
        _buildSupportTab(),
      ]),
    );
  }
}
