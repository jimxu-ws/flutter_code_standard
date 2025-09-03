

/// 支付状态枚举
enum PaymentStatus {
  pending,      // 待支付
  processing,   // 处理中
  completed,    // 已完成
  failed,       // 失败
  cancelled,    // 已取消
  refunded,     // 已退款
}

/// 支付方式枚举
enum PaymentMethod {
  alipay,       // 支付宝
  wechat,       // 微信支付
  card,         // 银行卡
  wallet,       // 钱包
}

/// 支付请求模型
class PaymentRequest {
  final String userId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final String orderId;
  final String? description;
  final Map<String, dynamic>? metadata;

  const PaymentRequest({
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.orderId,
    this.description,
    this.metadata,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      userId: json['userId'] as String,
      amount: json['amount'] as double,
      currency: json['currency'] as String,
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.card,
      ),
      orderId: json['orderId'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method.name,
      'orderId': orderId,
      'description': description,
      'metadata': metadata,
    };
  }
}

/// 支付结果模型
class PaymentResult {
  final String paymentId;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final String orderId;
  final DateTime createdAt;
  final String? transactionId;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const PaymentResult({
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.createdAt,
    this.transactionId,
    this.errorMessage,
    this.metadata,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      paymentId: json['paymentId'] as String,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      amount: json['amount'] as double,
      currency: json['currency'] as String,
      orderId: json['orderId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      transactionId: json['transactionId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'orderId': orderId,
      'createdAt': createdAt.toIso8601String(),
      'transactionId': transactionId,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }
}

/// 支付历史模型
class PaymentHistory {
  final String paymentId;
  final String userId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String orderId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? transactionId;
  final String? description;
  final Map<String, dynamic>? metadata;

  const PaymentHistory({
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.orderId,
    required this.createdAt,
    this.updatedAt,
    this.transactionId,
    this.description,
    this.metadata,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      paymentId: json['paymentId'] as String,
      userId: json['userId'] as String,
      amount: json['amount'] as double,
      currency: json['currency'] as String,
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.card,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      orderId: json['orderId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      transactionId: json['transactionId'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method.name,
      'status': status.name,
      'orderId': orderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'transactionId': transactionId,
      'description': description,
      'metadata': metadata,
    };
  }
}

/// 退款结果模型
class RefundResult {
  final String refundId;
  final String paymentId;
  final double amount;
  final String reason;
  final DateTime createdAt;
  final String? transactionId;
  final String? status;

  const RefundResult({
    required this.refundId,
    required this.paymentId,
    required this.amount,
    required this.reason,
    required this.createdAt,
    this.transactionId,
    this.status,
  });

  factory RefundResult.fromJson(Map<String, dynamic> json) {
    return RefundResult(
      refundId: json['refundId'] as String,
      paymentId: json['paymentId'] as String,
      amount: json['amount'] as double,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      transactionId: json['transactionId'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refundId': refundId,
      'paymentId': paymentId,
      'amount': amount,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'transactionId': transactionId,
      'status': status,
    };
  }
}
