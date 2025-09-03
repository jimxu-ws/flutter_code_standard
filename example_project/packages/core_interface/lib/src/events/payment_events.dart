import '../models/payment.dart';

/// 支付事件基类
abstract class PaymentEvent {
  final DateTime timestamp;
  final String eventId;
  
  PaymentEvent()
      : timestamp = DateTime.now(),
        eventId = DateTime.now().millisecondsSinceEpoch.toString();
}

/// 支付开始事件
class PaymentStartedEvent extends PaymentEvent {
  final PaymentRequest request;
  
  PaymentStartedEvent(this.request);
  
  @override
  String toString() => 'PaymentStartedEvent(orderId: ${request.orderId}, timestamp: $timestamp)';
}

/// 支付成功事件
class PaymentCompletedEvent extends PaymentEvent {
  final PaymentResult result;
  
  PaymentCompletedEvent(this.result);
  
  @override
  String toString() => 'PaymentCompletedEvent(paymentId: ${result.paymentId}, timestamp: $timestamp)';
}

/// 支付失败事件
class PaymentFailedEvent extends PaymentEvent {
  final String paymentId;
  final String errorMessage;
  
  PaymentFailedEvent(this.paymentId, this.errorMessage);
  
  @override
  String toString() => 'PaymentFailedEvent(paymentId: $paymentId, error: $errorMessage, timestamp: $timestamp)';
}

/// 支付取消事件
class PaymentCancelledEvent extends PaymentEvent {
  final String paymentId;
  final String reason;
  
  PaymentCancelledEvent(this.paymentId, this.reason);
  
  @override
  String toString() => 'PaymentCancelledEvent(paymentId: $paymentId, reason: $reason, timestamp: $timestamp)';
}

/// 退款事件
class RefundProcessedEvent extends PaymentEvent {
  final RefundResult result;
  
  RefundProcessedEvent(this.result);
  
  @override
  String toString() => 'RefundProcessedEvent(refundId: ${result.refundId}, timestamp: $timestamp)';
}
