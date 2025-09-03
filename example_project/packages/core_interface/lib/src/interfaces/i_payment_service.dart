import '../models/payment.dart';

/// 支付服务接口
/// 
/// 提供支付相关的所有操作
/// 
/// 版本：1.0.0
/// 兼容性：向后兼容
/// 维护者：@team-payment
abstract class IPaymentService {
  /// 处理支付
  /// 
  /// 参数：
  /// - [request] 支付请求
  /// 
  /// 返回值：
  /// - [PaymentResult] 支付结果
  /// 
  /// 异常：
  /// - [PaymentException] 支付失败
  /// - [NetworkException] 网络错误
  /// - [ValidationException] 参数验证失败
  Future<PaymentResult> processPayment(PaymentRequest request);
  
  /// 获取支付历史
  /// 
  /// 参数：
  /// - [userId] 用户ID
  /// - [limit] 限制数量
  /// - [offset] 偏移量
  /// 
  /// 返回值：
  /// - [List<PaymentHistory>] 支付历史列表
  Future<List<PaymentHistory>> getPaymentHistory({
    required String userId,
    int? limit,
    int? offset,
  });
  
  /// 获取支付状态
  /// 
  /// 参数：
  /// - [paymentId] 支付ID
  /// 
  /// 返回值：
  /// - [PaymentStatus] 支付状态
  Future<PaymentStatus> getPaymentStatus(String paymentId);
  
  /// 取消支付
  /// 
  /// 参数：
  /// - [paymentId] 支付ID
  /// 
  /// 异常：
  /// - [PaymentException] 取消失败
  /// - [NetworkException] 网络错误
  Future<void> cancelPayment(String paymentId);
  
  /// 退款
  /// 
  /// 参数：
  /// - [paymentId] 支付ID
  /// - [amount] 退款金额
  /// - [reason] 退款原因
  /// 
  /// 返回值：
  /// - [RefundResult] 退款结果
  Future<RefundResult> refund(String paymentId, double amount, String reason);
  
  /// 支付状态流
  /// 
  /// 监听支付状态变化
  Stream<PaymentStatus> getPaymentStatusStream(String paymentId);
}

/// 支付仓库接口
abstract class IPaymentRepository {
  /// 保存支付记录
  Future<void> savePayment(PaymentHistory payment);
  
  /// 获取支付记录
  Future<PaymentHistory?> getPayment(String paymentId);
  
  /// 更新支付状态
  Future<void> updatePaymentStatus(String paymentId, PaymentStatus status);
  
  /// 获取用户支付历史
  Future<List<PaymentHistory>> getUserPayments(String userId);
}
