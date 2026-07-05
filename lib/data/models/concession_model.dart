import '../../domain/entities/concession.dart';

class ConcessionModel extends Concession {
  const ConcessionModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.imageUrl,
    required super.isActive,
  });

  factory ConcessionModel.fromJson(Map<String, dynamic> json) {
    return ConcessionModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] != false,
    );
  }
}
