import 'package:eafind/models/new_products_model.dart';
import 'package:eafind/models/property_model.dart';

// The product or property a chat is about. Shown pinned at the top of the
// chat and sent along with each message (item_* fields), so the person on
// the other end sees what is being discussed too.
class ChatItemRef {
  final String type; // 'product' | 'property'
  final String id;
  final String title;
  final String image;
  final num amount;
  final String priceSuffix;

  const ChatItemRef({
    required this.type,
    required this.id,
    required this.title,
    required this.image,
    required this.amount,
    this.priceSuffix = '',
  });

  static num _num(dynamic v) =>
      num.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0;

  static String _firstImage(List images, {bool isVideo = false}) {
    if (isVideo || images.isEmpty) return '';
    return images.first.toString();
  }

  factory ChatItemRef.fromProduct(NewProductsModel p) => ChatItemRef(
        type: 'product',
        id: p.id.toString(),
        title: p.name,
        image: _firstImage(p.images),
        amount: _num(p.price),
      );

  factory ChatItemRef.fromProperty(PropertyModel p) => ChatItemRef(
        type: 'property',
        id: p.id.toString(),
        title: p.title.isNotEmpty ? p.title : p.category,
        image: _firstImage(p.images, isVideo: p.isVideo == 1),
        amount: _num(p.amount),
        priceSuffix: p.priceSuffix,
      );

  // Reads the item_* fields a message carries; null when it has none.
  static ChatItemRef? fromMessage(Map<String, dynamic> msg) {
    final title = (msg['item_title'] ?? '').toString().trim();
    if (title.isEmpty) return null;
    return ChatItemRef(
      type: (msg['item_type'] ?? '').toString(),
      id: (msg['item_id'] ?? '').toString(),
      title: title,
      image: (msg['item_image'] ?? '').toString(),
      amount: _num(msg['item_amount']),
      priceSuffix: (msg['item_price_suffix'] ?? '').toString(),
    );
  }

  // Form fields for send_message.php (all strings, as http.post needs).
  Map<String, String> toFields() => {
        'item_type': type,
        'item_id': id,
        'item_title': title,
        'item_image': image,
        'item_amount': amount.toString(),
        'item_price_suffix': priceSuffix,
      };
}
