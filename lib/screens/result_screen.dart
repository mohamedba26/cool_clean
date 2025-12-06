import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ResultScreen extends StatelessWidget {
  final Product product;
  const ResultScreen({Key? key, required this.product}) : super(key: key);

  // demo constructor
  factory ResultScreen.mock() => ResultScreen(product: Product.demo());

  Widget _badge() {
    final isBoycott = product.boycott;
    final color = isBoycott ? Color(0xFFFF3B30) : Color(0xFF00C9A7);
    final text = isBoycott ? 'BOYCOTT' : 'SAFE';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _imageBox() {
    if (product.imageUrl.isEmpty) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.local_drink, size: 48, color: Colors.grey.shade700),
      );
    }
    return CachedNetworkImage(
      imageUrl: product.imageUrl,
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        width: 96,
        height: 96,
        color: Colors.grey.shade200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => Container(
        width: 96,
        height: 96,
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  _imageBox(),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          product.brand,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        SizedBox(height: 8),
                        _badge(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Text('Details', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          _infoRow('Origin', product.origin),
          _infoRow('NutriScore', product.nutriScore),
          SizedBox(height: 12),
          Text('Ingredients', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            product.ingredients.isEmpty
                ? 'No ingredients data'
                : product.ingredients,
          ),
          SizedBox(height: 18),
          if (product.additives.isNotEmpty) ...[
            Text(
              'Additives / additives tags:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: product.additives
                  .map((a) => Chip(label: Text(a)))
                  .toList(),
            ),
            SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved to history (future)')),
              );
            },
            icon: Icon(Icons.bookmark_add_outlined),
            label: Text('Save to history'),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Show alternatives (future)')),
              );
            },
            icon: Icon(Icons.recommend),
            label: Text('Show alternatives'),
          ),
        ],
      ),
    );
  }
}
