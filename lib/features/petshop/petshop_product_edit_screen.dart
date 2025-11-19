import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api.dart';

const _coral = Color(0xFFF36C6C);

class PetshopProductEditScreen extends ConsumerStatefulWidget {
  final String? productId;
  const PetshopProductEditScreen({super.key, this.productId});

  @override
  ConsumerState<PetshopProductEditScreen> createState() =>
      _PetshopProductEditScreenState();
}

class _PetshopProductEditScreenState
    extends ConsumerState<PetshopProductEditScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _loading = false;
  bool _active = true;
  List<String> _imageUrls = [];
  List<File> _localImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    if (widget.productId == null) return;
    setState(() => _loading = true);
    try {
      final products = await ref.read(apiProvider).myProducts();
      final product = products.firstWhere(
        (p) => (p['id'] ?? '').toString() == widget.productId,
      );
      _titleController.text = (product['title'] ?? '').toString();
      _descriptionController.text = (product['description'] ?? '').toString();
      _priceController.text = (product['priceDa'] ?? product['price'] ?? 0).toString();
      _stockController.text = (product['stock'] ?? 0).toString();
      _categoryController.text = (product['category'] ?? '').toString();
      _active = product['active'] != false;
      final urls = product['imageUrls'] as List?;
      if (urls != null) {
        _imageUrls = urls.map((e) => e.toString()).where((e) => e.startsWith('http')).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _localImages.add(File(image.path)));
    }
  }

  Future<void> _uploadImages() async {
    if (_localImages.isEmpty) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiProvider);
      for (final file in _localImages) {
        final url = await api.uploadLocalFile(file);
        _imageUrls.add(url);
      }
      _localImages.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est requis')),
      );
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prix est requis')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _uploadImages();

      final api = ref.read(apiProvider);
      final price = int.tryParse(_priceController.text.trim()) ?? 0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;

      if (widget.productId == null) {
        await api.createProduct(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priceDa: price,
          stock: stock,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          imageUrls: _imageUrls.isEmpty ? null : _imageUrls,
          active: _active,
        );
      } else {
        await api.updateProduct(
          widget.productId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priceDa: price,
          stock: stock,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          imageUrls: _imageUrls.isEmpty ? null : _imageUrls,
          active: _active,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.productId == null
              ? 'Produit créé'
              : 'Produit mis à jour'),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Nouveau produit' : 'Modifier'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Enregistrer'),
            ),
        ],
      ),
      body: _loading && widget.productId != null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Images
                  const Text('Images',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length + _localImages.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _imageUrls.length + _localImages.length) {
                          return InkWell(
                            onTap: _pickImage,
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate),
                                  SizedBox(height: 4),
                                  Text('Ajouter', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }
                        if (i < _imageUrls.length) {
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(_imageUrls[i]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() => _imageUrls.removeAt(i));
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        final localIdx = i - _imageUrls.length;
                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_localImages[localIdx]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() => _localImages.removeAt(localIdx));
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  const Text('Titre *',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Nom du produit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text('Description',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Description du produit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prix et Stock
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Prix (DA) *',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Stock',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Catégorie
                  const Text('Catégorie',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Nourriture, Accessoires...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actif
                  SwitchListTile(
                    title: const Text('Produit actif'),
                    subtitle: const Text('Visible pour les clients'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),

                  const SizedBox(height: 24),

                  // Bouton supprimer si édition
                  if (widget.productId != null) ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Supprimer le produit ?'),
                            content: const Text(
                                'Cette action est irréversible. Confirmez-vous la suppression ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        setState(() => _loading = true);
                        try {
                          await ref.read(apiProvider).deleteProduct(widget.productId!);
                          if (!mounted) return;
                          context.pop(true);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Supprimer',
                          style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bouton enregistrer
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _coral,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Enregistrer',
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}

