class PlanModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final double originalPrice;
  final double discountPrice;
  final int invoicePeriod;
  final String invoiceInterval;
  final int trialPeriod;
  final String trialInterval;
  final String paddlePriceId;
  final String appstoreProductId;
  final bool isActive;
  final bool isBestDeal;
  final DateTime createdAt;

  PlanModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.originalPrice,
    required this.discountPrice,
    required this.invoicePeriod,
    required this.invoiceInterval,
    required this.trialPeriod,
    required this.trialInterval,
    required this.paddlePriceId,
    required this.appstoreProductId,
    required this.isActive,
    required this.isBestDeal,
    required this.createdAt,
  });

  /// Create a PlanModel from JSON
  factory PlanModel.fromJson(Map<String, dynamic> json) {
  double parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  return PlanModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    slug: json['slug'] ?? '',
    description: json['description'] ?? '',
    originalPrice: parseToDouble(json['original_price']),
    discountPrice: parseToDouble(json['discount_price']),
    invoicePeriod: json['invoice_period'] ?? 0,
    invoiceInterval: json['invoice_interval'] ?? '',
    trialPeriod: json['trial_period'] ?? 0,
    trialInterval: json['trial_interval'] ?? '',
    paddlePriceId: json['paddle_price_id'] ?? '',
    appstoreProductId: json['appstore_product_id'] ?? '',
    isActive: json['is_active'] ?? false,
    isBestDeal: json['is_best_deal'] ?? false,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}


  /// Convert PlanModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'original_price': originalPrice,
      'discount_price': discountPrice,
      'invoice_period': invoicePeriod,
      'invoice_interval': invoiceInterval,
      'trial_period': trialPeriod,
      'trial_interval': trialInterval,
      'paddle_price_id': paddlePriceId,
      'appstore_product_id': appstoreProductId,
      'is_active': isActive,
      'is_best_deal': isBestDeal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
