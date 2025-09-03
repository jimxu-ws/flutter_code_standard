/// 网络服务接口
/// 
/// 提供统一的网络请求功能
abstract class INetworkService {
  /// 发送 GET 请求
  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers});
  
  /// 发送 POST 请求
  Future<Map<String, dynamic>> post(String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });
  
  /// 发送 PUT 请求
  Future<Map<String, dynamic>> put(String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  });
  
  /// 发送 DELETE 请求
  Future<Map<String, dynamic>> delete(String url, {Map<String, String>? headers});
  
  /// 设置基础 URL
  void setBaseUrl(String baseUrl);
  
  /// 设置默认请求头
  void setDefaultHeaders(Map<String, String> headers);
}
