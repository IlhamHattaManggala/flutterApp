class Product {
  int? id;
  String name;
  double price;
  String description;

  Product(
      {this.id,
      required this.name,
      required this.price,
      required this.description});

  // Convert a Product into a Map. The keys must correspond to the column names in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
    };
  }
}
