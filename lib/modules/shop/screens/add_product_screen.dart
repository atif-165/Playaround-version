import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/cloudinary_service.dart';
import '../models/sports_categories.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  String? _category;
  final List<String> _images = [];

  final _imagePicker = ImagePicker();
  final _cloudinary = CloudinaryService();
  final _productService = ProductService();

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      final url = await _cloudinary.uploadImage(File(picked.path), folder: 'products');
      setState(() => _images.add(url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final product = Product(
      id: '',
      title: _title.text.trim(),
      description: _desc.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      category: _category ?? SportsCategories.all.first,
      ownerId: user.uid,
      shopId: '', // TODO: Get from shop selection
      shopName: '', // TODO: Get from shop selection
      images: _images,
      sizes: [], // TODO: Add size selection
      colors: [], // TODO: Add color selection
      stock: 0, // TODO: Add stock input
      isAvailable: true,
      rating: 0.0,
      reviewCount: 0,
      tags: [], // TODO: Add tag input
      specifications: {}, // TODO: Add specifications
      isFeatured: false,
      isExclusive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _productService.addProduct(product);
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add product: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              initialValue: _category,
              items: SportsCategories.all.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final url in _images)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _images.remove(url)),
                      ),
                    ],
                  ),
                OutlinedButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Add Image'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

