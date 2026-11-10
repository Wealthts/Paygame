import 'package:flutter/material.dart';

import 'package:frontend/models/paygame_models.dart';
import 'package:frontend/services/game_service.dart';
import 'package:frontend/services/package_service.dart';

class AdminPackagesView extends StatefulWidget {
  const AdminPackagesView({super.key});

  @override
  State<AdminPackagesView> createState() => _AdminPackagesViewState();
}

class _AdminPackagesViewState extends State<AdminPackagesView> {
  List<GameModel> games = [];
  List<PackageModel> packages = [];

  String? selectedGameId;

  bool isLoadingGames = true;
  bool isLoadingPackages = false;
  bool isSaving = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadGames();
  }

  // ==========================================
  // Load games
  // ==========================================
  Future<void> loadGames() async {
    setState(() {
      isLoadingGames = true;
      errorMessage = null;
    });

    try {
      final result = await GameService.getAdminGames();

      if (!mounted) return;

      setState(() {
        games = result;

        if (games.isNotEmpty) {
          selectedGameId = games[0].gameId;
        } else {
          selectedGameId = null;
          packages = [];
        }
      });

      if (selectedGameId != null) {
        await loadPackages(selectedGameId!);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    }

    if (!mounted) return;

    setState(() {
      isLoadingGames = false;
    });
  }

  // ==========================================
  // Load packages
  // ==========================================
  Future<void> loadPackages(String gameId) async {
    setState(() {
      isLoadingPackages = true;
      errorMessage = null;
    });

    try {
      final result = await PackageService.getAdminPackages(gameId);

      if (!mounted) return;

      setState(() {
        packages = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        packages = [];
        errorMessage = e.toString();
      });
    }

    if (!mounted) return;

    setState(() {
      isLoadingPackages = false;
    });
  }

  // ==========================================
  // Show add / edit dialog
  // ==========================================
  Future<PackageModel?> showPackageDialog({PackageModel? package}) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: package?.packageName ?? '',
    );

    final priceController = TextEditingController(
      text: package == null ? '' : package.price.toString(),
    );

    final result = await showDialog<PackageModel>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(package == null ? 'Add Package' : 'Edit Package'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Package Name',
                    hintText: 'Example: 100 Diamonds',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter package name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price (THB)',
                    hintText: 'Example: 35.00',
                    border: OutlineInputBorder(),
                    prefixText: '฿ ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter price';
                    }

                    final price = double.tryParse(value);

                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }

                    return null;
                  },
                ),
              ],
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
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final newPackage = PackageModel(
                  packageId: package?.packageId ?? 0,
                  gameId: package?.gameId ?? selectedGameId!,
                  packageName: nameController.text.trim(),
                  price: double.parse(priceController.text.trim()),
                  isActive: package?.isActive ?? true,
                );

                Navigator.pop(dialogContext, newPackage);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    priceController.dispose();

    return result;
  }

  // ==========================================
  // Add package
  // ==========================================
  Future<void> addPackage() async {
    if (selectedGameId == null) return;

    final package = await showPackageDialog();

    if (package == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await PackageService.addPackage(package);

      await loadPackages(selectedGameId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add package failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
  }

  // ==========================================
  // Edit package
  // ==========================================
  Future<void> editPackage(PackageModel package) async {
    final updatedPackage = await showPackageDialog(package: package);

    if (updatedPackage == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await PackageService.updatePackage(updatedPackage);

      await loadPackages(selectedGameId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update package failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
  }

  // ==========================================
  // Activate / Deactivate package
  // ==========================================
  Future<void> togglePackageStatus(PackageModel package) async {
    final action = package.isActive ? 'deactivate' : 'activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            package.isActive ? 'Deactivate Package' : 'Activate Package',
          ),
          content: Text('Do you want to $action "${package.packageName}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(package.isActive ? 'Deactivate' : 'Activate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isSaving = true;
    });

    try {
      if (package.isActive) {
        await PackageService.deletePackage(package.packageId);
      } else {
        final updatedPackage = PackageModel(
          packageId: package.packageId,
          gameId: package.gameId,
          packageName: package.packageName,
          price: package.price,
          isActive: true,
        );

        await PackageService.updatePackage(updatedPackage);
      }

      await loadPackages(selectedGameId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            package.isActive
                ? 'Package deactivated successfully'
                : 'Package activated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
  }

  // ==========================================
  // Build package card
  // ==========================================
  Widget buildPackageCard(PackageModel package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: package.isActive
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.12),
              child: Icon(
                Icons.inventory_2_outlined,
                color: package.isActive ? Colors.green : Colors.grey,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.packageName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '฿ ${package.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    package.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: package.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Edit package',
              onPressed: isSaving ? null : () => editPackage(package),
              icon: const Icon(Icons.edit_outlined),
            ),

            IconButton(
              tooltip: package.isActive
                  ? 'Deactivate package'
                  : 'Activate package',
              onPressed: isSaving ? null : () => togglePackageStatus(package),
              icon: Icon(
                package.isActive ? Icons.block : Icons.check_circle_outline,
                color: package.isActive ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Build page
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoadingGames || isLoadingPackages ? null : loadGames,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoadingGames
          ? const Center(child: CircularProgressIndicator())
          : games.isEmpty
          ? Center(child: Text(errorMessage ?? 'No games available'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game selection
                  DropdownButtonFormField<String>(
                    value: selectedGameId,
                    decoration: const InputDecoration(
                      labelText: 'Select Game',
                      border: OutlineInputBorder(),
                    ),
                    items: games.map((game) {
                      return DropdownMenuItem<String>(
                        value: game.gameId,
                        child: Text(game.gameName),
                      );
                    }).toList(),
                    onChanged: isSaving
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              selectedGameId = value;
                              packages = [];
                            });

                            loadPackages(value);
                          },
                  ),

                  const SizedBox(height: 16),

                  // Package header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Packages',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: isSaving || selectedGameId == null
                            ? null
                            : addPackage,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Package'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Package list
                  Expanded(
                    child: isLoadingPackages
                        ? const Center(child: CircularProgressIndicator())
                        : packages.isEmpty
                        ? const Center(child: Text('No packages found'))
                        : ListView.builder(
                            itemCount: packages.length,
                            itemBuilder: (context, index) {
                              return buildPackageCard(packages[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
