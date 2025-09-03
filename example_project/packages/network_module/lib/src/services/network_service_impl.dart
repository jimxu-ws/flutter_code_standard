import 'package:core_interface/core_interface.dart';

/// 网络服务实现
/// 
/// 基于 Dart 内置 HTTP 客户端的网络服务实现
class NetworkServiceImpl implements INetworkService {
  String? _baseUrl;
  Map<String, String> _defaultHeaders = {};

  @override
  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers}) async {
    try {
      final fullUrl = _buildFullUrl(url);
      _mergeHeaders(headers);
      
      print('[Network] GET: $fullUrl');
      
      // 模拟网络请求
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 这里应该使用真实的 HTTP 客户端
      // 例如：final response = await http.get(Uri.parse(fullUrl), headers: mergedHeaders);
      
      // 模拟响应
      return {
        'success': true,
        'data': {'message': 'GET request successful'},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw NetworkException('GET 请求失败：$e');
    }
  }

  @override
  Future<Map<String, dynamic>> post(String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final fullUrl = _buildFullUrl(url);
      _mergeHeaders(headers);
      
      print('[Network] POST: $fullUrl');
      print('[Network] Body: $body');
      
      // 模拟网络请求
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 这里应该使用真实的 HTTP 客户端
      // 例如：
      // final response = await http.post(
      //   Uri.parse(fullUrl),
      //   headers: mergedHeaders,
      //   body: json.encode(body),
      // );
      
      // 模拟响应
      return {
        'success': true,
        'data': {
          'message': 'POST request successful',
          'receivedData': body,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw NetworkException('POST 请求失败：$e');
    }
  }

  @override
  Future<Map<String, dynamic>> put(String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final fullUrl = _buildFullUrl(url);
      _mergeHeaders(headers);
      
      print('[Network] PUT: $fullUrl');
      print('[Network] Body: $body');
      
      // 模拟网络请求
      await Future.delayed(const Duration(milliseconds: 600));
      
      // 模拟响应
      return {
        'success': true,
        'data': {
          'message': 'PUT request successful',
          'updatedData': body,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw NetworkException('PUT 请求失败：$e');
    }
  }

  @override
  Future<Map<String, dynamic>> delete(String url, {Map<String, String>? headers}) async {
    try {
      final fullUrl = _buildFullUrl(url);
      _mergeHeaders(headers);
      
      print('[Network] DELETE: $fullUrl');
      
      // 模拟网络请求
      await Future.delayed(const Duration(milliseconds: 400));
      
      // 模拟响应
      return {
        'success': true,
        'data': {'message': 'DELETE request successful'},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw NetworkException('DELETE 请求失败：$e');
    }
  }

  @override
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    print('[Network] Base URL set to: $baseUrl');
  }

  @override
  void setDefaultHeaders(Map<String, String> headers) {
    _defaultHeaders = Map.from(headers);
    print('[Network] Default headers set: $headers');
  }

  /// 构建完整的 URL
  String _buildFullUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    if (_baseUrl == null) {
      throw NetworkException('Base URL 未设置，且提供的 URL 不是完整的 URL');
    }
    
    final baseUrl = _baseUrl!.endsWith('/') ? _baseUrl!.substring(0, _baseUrl!.length - 1) : _baseUrl!;
    final path = url.startsWith('/') ? url : '/$url';
    
    return '$baseUrl$path';
  }

  /// 合并请求头
  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    final merged = Map<String, String>.from(_defaultHeaders);
    
    // 添加默认的 Content-Type
    if (!merged.containsKey('Content-Type')) {
      merged['Content-Type'] = 'application/json';
    }
    
    // 添加默认的 Accept
    if (!merged.containsKey('Accept')) {
      merged['Accept'] = 'application/json';
    }
    
    // 合并传入的请求头
    if (headers != null) {
      merged.addAll(headers);
    }
    
    return merged;
  }
}
