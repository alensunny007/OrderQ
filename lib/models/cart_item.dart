class CartItem {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  int quantity;
  final String source;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'source': source,
    };
  }

  static CartItem fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      title: map['title'],
      price: map['price'].toDouble(),
      imageUrl: map['imageUrl'],
      quantity: map['quantity'],
      source: map['source'],
    );
  }
}