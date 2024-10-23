import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/product.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD Skincare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late DatabaseHelper dbHelper;
  late Future<List<Product>> productList;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _refreshProductList();
  }

  void _refreshProductList() {
    setState(() {
      productList = dbHelper.getProducts();
    });
  }

  void _showProductDialog([Product? product]) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toString();
      descriptionController.text = product.description;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nama Produk'),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Deskripsi'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                nameController.clear();
                priceController.clear();
                descriptionController.clear();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Nama dan harga produk harus diisi!'),
                  ));
                  return;
                }

                // Cek validitas harga
                double? parsedPrice;
                try {
                  parsedPrice = double.parse(priceController.text);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Harga tidak valid!'),
                  ));
                  return;
                }

                if (product == null) {
                  // Insert new product
                  await dbHelper.insertProduct(
                    Product(
                      name: nameController.text,
                      price: parsedPrice,
                      description: descriptionController.text,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Berhasil menyimpan produk!'),
                    backgroundColor: const Color.fromARGB(255, 53, 172, 57),
                  ));
                } else {
                  // Update existing product
                  await dbHelper.updateProduct(
                    Product(
                      id: product.id,
                      name: nameController.text,
                      price: parsedPrice,
                      description: descriptionController.text,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Berhasil mengupdate produk!'),
                    backgroundColor: const Color.fromARGB(255, 53, 172, 57),
                  ));
                }
                _refreshProductList();
                nameController.clear();
                priceController.clear();
                descriptionController.clear();
                Navigator.of(context).pop();
              },
              child: Text(product == null ? 'Simpan' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProduct(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Hapus produk dan tampilkan notifikasi
                await dbHelper.deleteProduct(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Berhasil menghapus produk!'),
                    backgroundColor: const Color.fromARGB(255, 229, 53, 40),
                  ),
                );
                _refreshProductList();
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Produk Skincare'),
        backgroundColor: const Color.fromRGBO(192, 242, 255, 1),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: FutureBuilder<List<Product>>(
        future: productList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(child: Text('Tidak ada produk tersedia.'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('Rp ${product.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showProductDialog(product),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteProduct(product.id!),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: const Color.fromARGB(255, 86, 204, 234),
        onPressed: () => _showProductDialog(),
      ),
    );
  }
}
