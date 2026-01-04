import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/features/sharing/data/sharing_repository.dart';
import 'package:fitta/features/sharing/models/client_link.dart';
import 'package:fitta/features/sharing/views/client_shell.dart';

class TrainerClientsPage extends StatefulWidget {
  const TrainerClientsPage({super.key});

  @override
  State<TrainerClientsPage> createState() => _TrainerClientsPageState();
}

class _TrainerClientsPageState extends State<TrainerClientsPage> {
  final TextEditingController _searchController = TextEditingController();
  final SharingRepository _repository = SharingRepository();
  String _query = '';

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FittaAppBar(title: 'Danışanlarım'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Danışan ara',
                prefixIcon: Icon(CupertinoIcons.search),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ClientLink>>(
              stream: _repository.watchClients(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final clients = snapshot.data ?? [];
                final filtered = _applyFilter(clients, _query);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.person_2, size: 48, color: Colors.grey),
                        AppSpacing.vSm,
                        Text(
                          _query.isEmpty
                              ? 'Henüz danışan eklenmedi.'
                              : 'Arama sonucu bulunamadı.',
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final client = filtered[index];
                    final name = client.ownerDisplayName.isNotEmpty
                        ? client.ownerDisplayName
                        : (client.ownerEmail.isNotEmpty
                            ? client.ownerEmail
                            : client.ownerUserId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FittaCard(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (client.ownerEmail.isNotEmpty)
                                Text(client.ownerEmail),
                              Text('Rol: ${_roleLabel(client.role)}'),
                            ],
                          ),
                          trailing: const Icon(CupertinoIcons.forward),
                          onTap: () => Get.to(() => ClientShell(client: client)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ClientLink> _applyFilter(List<ClientLink> clients, String query) {
    if (query.isEmpty) return clients;
    final lowered = query.toLowerCase();
    return clients.where((client) {
      final name = client.ownerDisplayName.toLowerCase();
      final email = client.ownerEmail.toLowerCase();
      return name.contains(lowered) || email.contains(lowered);
    }).toList(growable: false);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'trainer':
        return 'Antrenör';
      case 'viewer':
        return 'Görüntüleyici';
      default:
        return role;
    }
  }
}
