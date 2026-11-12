import 'package:flutter/material.dart';

import 'package:frontend/models/paygame_models.dart';
import 'package:frontend/services/game_service.dart';

class AdminGamesView extends StatefulWidget {
  const AdminGamesView({super.key});

  @override
  State<AdminGamesView> createState() => _AdminGamesViewState();
}

class _AdminGamesViewState extends State<AdminGamesView> {
  static const Color red = Color(0xFFA60C19);

  List<GameModel> games = [];

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadGames();
  }

  // Load all games from Backend
  Future<void> loadGames() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await GameService.getAdminGames();

      if (!mounted) return;

      setState(() {
        games = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // Show message
  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Add or Edit Game Dialog
  Future<void> showGameDialog({GameModel? game}) async {
    final isEditing = game != null;

    final nameController = TextEditingController(text: game?.gameName ?? '');

    final categoryController = TextEditingController(
      text: game?.category ?? '',
    );

    final patternController = TextEditingController(
      text: game?.uidPattern ?? '',
    );

    bool requiresServer = game?.requiresServer ?? false;
    bool isActive = game?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<GameModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Game' : 'Add New Game',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Game Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Game Name',
                          hintText: 'Example: RoV',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter game name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Category
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'Example: Mobile or PC',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter category';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // UID Pattern
                      TextFormField(
                        controller: patternController,
                        decoration: const InputDecoration(
                          labelText: 'UID Pattern',
                          hintText: r'^[0-9]{10,12}$',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter UID pattern';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Requires Server
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Requires Server'),
                        value: requiresServer,
                        activeColor: red,
                        onChanged: (value) {
                          setDialogState(() {
                            requiresServer = value ?? false;
                          });
                        },
                      ),

                      // Active Status
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: isActive,
                        activeColor: red,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final gameName = nameController.text.trim();

                    final newGame = GameModel(
                      gameId: game?.gameId ?? '',
                      gameName: gameName,
                      shortName: game?.shortName ?? gameName,
                      category: categoryController.text.trim(),
                      unit: game?.unit ?? '',
                      uidPattern: patternController.text.trim(),
                      requiresServer: requiresServer,
                      isActive: isActive
                    );

                    Navigator.pop(dialogContext, newGame);
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Game'),
                ),
              ],
            );
          },
        );
      },
    );

    // Don't dispose the controllers here: the dialog is still playing its
    // closing animation and its text fields are still using them.
    // Disposing now triggers the '_dependents.isEmpty' assertion.
    // They are garbage-collected once the dialog is gone.

    if (!mounted || result == null || isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      if (isEditing) {
        await GameService.updateGame(result);
      } else {
        await GameService.addGame(result);
      }

      if (!mounted) return;
      showMessage(
        isEditing ? 'Game updated successfully' : 'Game added successfully',
      );

      await loadGames();
    } catch (e) {
      showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // Soft Delete Game
  Future<void> deleteGame(GameModel game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Game'),
          content: Text(
            'Are you sure you want to deactivate ${game.gameName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true || isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      await GameService.deleteGame(game.gameId);

      if (!mounted) return;

      showMessage('Game deactivated successfully');

      await loadGames();
    } catch (e) {
      showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // Game Status
  Widget buildStatus(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Game Card
  Widget buildGameCard(GameModel game) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF3E7D3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.shortName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.gameName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.category} • ID: ${game.gameId}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                buildStatus(game.isActive),
              ],
            ),

            const Divider(height: 24),

            Text(
              'UID Pattern: ${game.uidPattern}',
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 6),

            Text(
              'Requires Server: ${game.requiresServer ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit Button
                TextButton.icon(
                  onPressed: isSaving
                      ? null
                      : () {
                          showGameDialog(game: game);
                        },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: red),
                ),

                // Deactivate Button
                if (game.isActive)
                  TextButton.icon(
                    onPressed: isSaving
                        ? null
                        : () {
                            deleteGame(game);
                          },
                    icon: const Icon(Icons.block),
                    label: const Text('Deactivate'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Main Build
  @override
  Widget build(BuildContext context) {
    final activeCount = games.where((game) => game.isActive).length;
    final inactiveCount = games.length - activeCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      appBar: AppBar(
        title: const Text(
          'Game Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: isLoading || isSaving ? null : loadGames,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving
            ? null
            : () {
                showGameDialog();
              },
        backgroundColor: red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Game'),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: red))
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load games',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: loadGames,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadGames,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  // Summary
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryCard(
                          'Total Games',
                          games.length.toString(),
                          Icons.sports_esports,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryCard(
                          'Active',
                          activeCount.toString(),
                          Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryCard(
                          'Inactive',
                          inactiveCount.toString(),
                          Icons.block,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'All Games',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  if (games.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('No games found')),
                    )
                  else
                    ...games.map((game) {
                      return buildGameCard(game);
                    }),
                ],
              ),
            ),
    );
  }

  // Summary Card
  Widget buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: red, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
