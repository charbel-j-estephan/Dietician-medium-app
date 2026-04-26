// This page is the home page for dieticians. It displays a list of clients.

import 'package:calories_tracking/pages/weight_page.dart';
import 'package:calories_tracking/widgets/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'client_diary_page.dart';

// The DieticianHomePage widget is a stateful widget that displays the dietician's home page.
class DieticianHomePage extends StatefulWidget {
  const DieticianHomePage({super.key});

  @override
  _DieticianHomePageState createState() => _DieticianHomePageState();
}

class _DieticianHomePageState extends State<DieticianHomePage> {
  // The search query.
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietician Dashboard'),
        actions: [
          const ThemeToggleButton(),
          // The logout button.
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                // Navigate to the root and remove all previous routes.
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive padding.
          final horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 16.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  // The search bar.
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 20.0,
                    ),
                    child: Material(
                      elevation: 3.0,
                      shadowColor: Theme.of(
                        context,
                      ).shadowColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search clients...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  // The list of clients.
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'client')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No clients found.'));
                        }

                        // Filter the clients based on the search query.
                        final filteredDocs = snapshot.data!.docs.where((doc) {
                          final clientData = doc.data() as Map<String, dynamic>;
                          final clientName =
                              clientData['name'] as String? ?? '';
                          return clientName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                        }).toList();

                        if (filteredDocs.isEmpty) {
                          return const Center(
                            child: Text('No clients found matching search.'),
                          );
                        }

                        return ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 8.0,
                          ),
                          itemCount: filteredDocs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final clientDoc = filteredDocs[index];
                            final clientData =
                                clientDoc.data() as Map<String, dynamic>;
                            final clientUid = clientDoc.id;
                            final clientName =
                                clientData['name'] ?? 'Unnamed Client';

                            return ClientCard(
                              clientName: clientName,
                              clientUid: clientUid,
                              onTap: () {
                                // Navigate to the client's diary page.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClientDiaryPage(
                                      clientUid: clientUid,
                                      clientName: clientName,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/food_management');
        },
        tooltip: 'Manage Foods',
        child: const Icon(Icons.fastfood),
      ),
    );
  }
}

// A card that displays a client's information.
class ClientCard extends StatefulWidget {
  final String clientName;
  final String clientUid;
  final VoidCallback onTap;

  const ClientCard({
    super.key,
    required this.clientName,
    required this.clientUid,
    required this.onTap,
  });

  @override
  _ClientCardState createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard> {
  // A boolean to indicate if the card is hovered.
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(
                  _isHovered
                      ? (isDarkMode ? 0.5 : 0.25)
                      : (isDarkMode ? 0.3 : 0.1),
                ),
                blurRadius: _isHovered ? 14 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 24.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.clientName.toUpperCase(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View Diary & Weight',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // An icon button to navigate to the client's weight page.
                    IconButton(
                      icon: const Icon(Icons.show_chart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WeightPage(
                              clientUid: widget.clientUid,
                              clientName: widget.clientName,
                            ),
                          ),
                        );
                      },
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
