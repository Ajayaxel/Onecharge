class RedeemCodeValidationResponse {
  RedeemCodeValidationResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final RedeemCodeValidationData data;

  factory RedeemCodeValidationResponse.fromJson(Map<String, dynamic> json) {
    return RedeemCodeValidationResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: RedeemCodeValidationData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class RedeemCodeValidationData {
  RedeemCodeValidationData({
    required this.valid,
    required this.baseAmount,
    required this.discountAmount,
    required this.discountedBaseAmount,
    required this.vatAmount,
    required this.totalAmount,
    required this.isFree,
    required this.discountType,
    required this.discountValue,
  });

  final bool valid;
  final double baseAmount;
  final double discountAmount;
  final double discountedBaseAmount;
  final double vatAmount;
  final double totalAmount;
  final bool isFree;
  final String discountType;
  final String discountValue;

  factory RedeemCodeValidationData.fromJson(Map<String, dynamic> json) {
    return RedeemCodeValidationData(
      valid: json['valid'] as bool? ?? false,
      baseAmount: (json['base_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      discountedBaseAmount: (json['discounted_base_amount'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (json['vat_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      isFree: json['is_free'] as bool? ?? false,
      discountType: json['discount_type'] as String? ?? '',
      discountValue: json['discount_value'] as String? ?? '',
    );
  }
}

