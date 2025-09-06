import 'package:flutter_test/flutter_test.dart';
import 'package:query_provider/query_provider.dart';

void main() {
  group('QueryOptions', () {
    test('should create with default values', () {
      const options = QueryOptions<String>();
      
      expect(options.staleTime, const Duration(minutes: 5));
      expect(options.cacheTime, const Duration(minutes: 30));
      expect(options.refetchOnMount, true);
      expect(options.refetchOnWindowFocus, false);
      expect(options.refetchOnAppFocus, true);
      expect(options.pauseRefetchInBackground, true);
      expect(options.refetchInterval, null);
      expect(options.retry, 3);
      expect(options.retryDelay, const Duration(seconds: 1));
      expect(options.enabled, true);
      expect(options.keepPreviousData, false);
      expect(options.onSuccess, null);
      expect(options.onError, null);
    });

    test('should create with custom values', () {
      void onSuccess(String data) {}
      void onError(Object error, StackTrace? stackTrace) {}
      
      final options = QueryOptions<String>(
        staleTime: const Duration(minutes: 10),
        cacheTime: const Duration(hours: 1),
        refetchOnMount: false,
        refetchOnWindowFocus: true,
        refetchOnAppFocus: false,
        pauseRefetchInBackground: false,
        refetchInterval: const Duration(seconds: 30),
        retry: 5,
        retryDelay: const Duration(seconds: 2),
        enabled: false,
        keepPreviousData: true,
        onSuccess: onSuccess,
        onError: onError,
      );
      
      expect(options.staleTime, const Duration(minutes: 10));
      expect(options.cacheTime, const Duration(hours: 1));
      expect(options.refetchOnMount, false);
      expect(options.refetchOnWindowFocus, true);
      expect(options.refetchOnAppFocus, false);
      expect(options.pauseRefetchInBackground, false);
      expect(options.refetchInterval, const Duration(seconds: 30));
      expect(options.retry, 5);
      expect(options.retryDelay, const Duration(seconds: 2));
      expect(options.enabled, false);
      expect(options.keepPreviousData, true);
      expect(options.onSuccess, onSuccess);
      expect(options.onError, onError);
    });

    test('copyWith should create new instance with updated values', () {
      const original = QueryOptions<String>(
        staleTime: Duration(minutes: 5),
        retry: 3,
      );
      
      final updated = original.copyWith(
        staleTime: const Duration(minutes: 10),
        enabled: false,
      );
      
      expect(updated.staleTime, const Duration(minutes: 10));
      expect(updated.enabled, false);
      expect(updated.retry, 3); // Should keep original value
      expect(updated.cacheTime, const Duration(minutes: 30)); // Should keep default
    });

    test('copyWith should handle all parameters', () {
      void onSuccess(String data) {}
      void onError(Object error, StackTrace? stackTrace) {}
      
      const original = QueryOptions<String>();
      
      final updated = original.copyWith(
        staleTime: const Duration(minutes: 10),
        cacheTime: const Duration(hours: 1),
        refetchOnMount: false,
        refetchOnWindowFocus: true,
        refetchOnAppFocus: false,
        pauseRefetchInBackground: false,
        refetchInterval: const Duration(seconds: 30),
        retry: 5,
        retryDelay: const Duration(seconds: 2),
        enabled: false,
        keepPreviousData: true,
        onSuccess: onSuccess,
        onError: onError,
      );
      
      expect(updated.staleTime, const Duration(minutes: 10));
      expect(updated.cacheTime, const Duration(hours: 1));
      expect(updated.refetchOnMount, false);
      expect(updated.refetchOnWindowFocus, true);
      expect(updated.refetchOnAppFocus, false);
      expect(updated.pauseRefetchInBackground, false);
      expect(updated.refetchInterval, const Duration(seconds: 30));
      expect(updated.retry, 5);
      expect(updated.retryDelay, const Duration(seconds: 2));
      expect(updated.enabled, false);
      expect(updated.keepPreviousData, true);
      expect(updated.onSuccess, onSuccess);
      expect(updated.onError, onError);
    });

    test('equality should work correctly', () {
      const options1 = QueryOptions<String>(
        staleTime: Duration(minutes: 5),
        retry: 3,
      );
      
      const options2 = QueryOptions<String>(
        staleTime: Duration(minutes: 5),
        retry: 3,
      );
      
      const options3 = QueryOptions<String>(
        staleTime: Duration(minutes: 10),
        retry: 3,
      );
      
      expect(options1, equals(options2));
      expect(options1.hashCode, equals(options2.hashCode));
      expect(options1, isNot(equals(options3)));
    });

    test('toString should include all relevant fields', () {
      const options = QueryOptions<String>(
        staleTime: Duration(minutes: 5),
        cacheTime: Duration(minutes: 30),
        refetchOnMount: true,
        refetchOnWindowFocus: false,
        refetchInterval: Duration(seconds: 30),
        retry: 3,
        retryDelay: Duration(seconds: 1),
        enabled: true,
        keepPreviousData: false,
      );
      
      final string = options.toString();
      expect(string, contains('QueryOptions<String>'));
      expect(string, contains('staleTime: 0:05:00.000000'));
      expect(string, contains('cacheTime: 0:30:00.000000'));
      expect(string, contains('refetchOnMount: true'));
      expect(string, contains('refetchOnWindowFocus: false'));
      expect(string, contains('refetchInterval: 0:00:30.000000'));
      expect(string, contains('retry: 3'));
      expect(string, contains('retryDelay: 0:00:01.000000'));
      expect(string, contains('enabled: true'));
      expect(string, contains('keepPreviousData: false'));
    });
  });

  group('InfiniteQueryOptions', () {
    String? getNextPageParam(String lastPage, List<String> allPages) {
      return allPages.length < 3 ? 'page-${allPages.length + 1}' : null;
    }

    String? getPreviousPageParam(String firstPage, List<String> allPages) {
      return allPages.length > 1 ? 'page-${allPages.length - 1}' : null;
    }

    test('should create with required parameters', () {
      final options = InfiniteQueryOptions<String, String>(
        getNextPageParam: getNextPageParam,
      );
      
      expect(options.getNextPageParam, getNextPageParam);
      expect(options.getPreviousPageParam, null);
      expect(options.staleTime, const Duration(minutes: 5)); // Inherited
      expect(options.cacheTime, const Duration(minutes: 30)); // Inherited
    });

    test('should create with all parameters', () {
      final options = InfiniteQueryOptions<String, String>(
        getNextPageParam: getNextPageParam,
        getPreviousPageParam: getPreviousPageParam,
        staleTime: const Duration(minutes: 10),
        cacheTime: const Duration(hours: 1),
        refetchOnMount: false,
        refetchOnWindowFocus: true,
        refetchInterval: const Duration(seconds: 30),
        retry: 5,
        retryDelay: const Duration(seconds: 2),
        enabled: false,
        keepPreviousData: true,
      );
      
      expect(options.getNextPageParam, getNextPageParam);
      expect(options.getPreviousPageParam, getPreviousPageParam);
      expect(options.staleTime, const Duration(minutes: 10));
      expect(options.cacheTime, const Duration(hours: 1));
      expect(options.refetchOnMount, false);
      expect(options.refetchOnWindowFocus, true);
      expect(options.refetchInterval, const Duration(seconds: 30));
      expect(options.retry, 5);
      expect(options.retryDelay, const Duration(seconds: 2));
      expect(options.enabled, false);
      expect(options.keepPreviousData, true);
    });

    test('copyWith should create new instance with updated values', () {
      final original = InfiniteQueryOptions<String, String>(
        getNextPageParam: getNextPageParam,
        staleTime: const Duration(minutes: 5),
        retry: 3,
      );
      
      final updated = original.copyWith(
        staleTime: const Duration(minutes: 10),
        enabled: false,
        getPreviousPageParam: getPreviousPageParam,
      );
      
      expect(updated.staleTime, const Duration(minutes: 10));
      expect(updated.enabled, false);
      expect(updated.retry, 3); // Should keep original value
      expect(updated.getNextPageParam, getNextPageParam); // Should keep original
      expect(updated.getPreviousPageParam, getPreviousPageParam); // Should be updated
    });

    test('copyWith should handle all parameters', () {
      String? newGetNextPageParam(String lastPage, List<String> allPages) => null;
      String? newGetPreviousPageParam(String firstPage, List<String> allPages) => null;
      
      final original = InfiniteQueryOptions<String, String>(
        getNextPageParam: getNextPageParam,
      );
      
      final updated = original.copyWith(
        staleTime: const Duration(minutes: 10),
        cacheTime: const Duration(hours: 1),
        refetchOnMount: false,
        refetchOnWindowFocus: true,
        refetchOnAppFocus: false,
        pauseRefetchInBackground: false,
        refetchInterval: const Duration(seconds: 30),
        retry: 5,
        retryDelay: const Duration(seconds: 2),
        enabled: false,
        keepPreviousData: true,
        getNextPageParam: newGetNextPageParam,
        getPreviousPageParam: newGetPreviousPageParam,
      );
      
      expect(updated.staleTime, const Duration(minutes: 10));
      expect(updated.cacheTime, const Duration(hours: 1));
      expect(updated.refetchOnMount, false);
      expect(updated.refetchOnWindowFocus, true);
      expect(updated.refetchOnAppFocus, false);
      expect(updated.pauseRefetchInBackground, false);
      expect(updated.refetchInterval, const Duration(seconds: 30));
      expect(updated.retry, 5);
      expect(updated.retryDelay, const Duration(seconds: 2));
      expect(updated.enabled, false);
      expect(updated.keepPreviousData, true);
      expect(updated.getNextPageParam, newGetNextPageParam);
      expect(updated.getPreviousPageParam, newGetPreviousPageParam);
    });

    test('getNextPageParam should work correctly', () {
      final options = InfiniteQueryOptions<String, String>(
        getNextPageParam: getNextPageParam,
      );
      
      expect(options.getNextPageParam('page-1', ['page-1']), 'page-2');
      expect(options.getNextPageParam('page-2', ['page-1', 'page-2']), 'page-3');
      expect(options.getNextPageParam('page-3', ['page-1', 'page-2', 'page-3']), null);
    });

    test('getPreviousPageParam should work correctly', () {
      final options = InfiniteQueryOptions<String, String>(
        getNextPageParam: getNextPageParam,
        getPreviousPageParam: getPreviousPageParam,
      );
      
      expect(options.getPreviousPageParam!('page-1', ['page-1']), 'page-0');
      expect(options.getPreviousPageParam!('page-1', ['page-1', 'page-2']), 'page-1');
    });
  });
}
