import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:query_provider/query_provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// Query provider for fetching all users
final usersQueryProvider = queryProvider<List<User>>(
  name: 'users',
  queryFn: ApiService.fetchUsers,
  options: const QueryOptions<List<User>>(
    staleTime: Duration(minutes: 5),
    cacheTime: Duration(minutes: 10),
    refetchOnMount: true,
  ),
);

/// Query provider for fetching a single user by ID (using function approach)
StateNotifierProvider<QueryNotifier<User>, QueryState<User>> userQueryProvider(int userId) {
  return queryProvider<User>(
    name: 'user-$userId',
    queryFn: () => ApiService.fetchUser(userId),
    options: const QueryOptions<User>(
      staleTime: Duration(minutes: 3),
      cacheTime: Duration(minutes: 15),
    ),
  );
}

/// Query provider family for fetching users by ID (recommended approach)
final userQueryProviderFamily = queryProviderFamily<User, int>(
  name: 'user',
  queryFn: ApiService.fetchUser,
  options: const QueryOptions<User>(
    staleTime: Duration(minutes: 3),
    cacheTime: Duration(minutes: 15),
  ),
);

/// Query provider family for searching users by name
final userSearchProviderFamily = queryProviderFamily<List<User>, String>(
  name: 'userSearch',
  queryFn: ApiService.searchUsers,
  options: const QueryOptions<List<User>>(
    staleTime: Duration(seconds: 30), // Search results get stale quickly
    cacheTime: Duration(minutes: 5),
  ),
);

/// Alternative: Using queryProviderWithParams (with fixed parameters)
StateNotifierProvider<QueryNotifier<User>, QueryState<User>> userQueryWithParams(int userId) {
  return queryProviderWithParams<User, int>(
    name: 'user',
    params: userId,
    queryFn: ApiService.fetchUser,
    options: const QueryOptions<User>(
      staleTime: Duration(minutes: 3),
      cacheTime: Duration(minutes: 15),
    ),
  );
}

/// Mutation provider for creating a new user
final createUserMutationProvider = mutationProvider<User, Map<String, dynamic>>(
  name: 'create-user',
  mutationFn: ApiService.createUser,
  options: MutationOptions<User, Map<String, dynamic>>(
    onSuccess: (user, variables) {
      print('User created successfully: ${user.name}');
      // In a real app, you might invalidate the users query here
    },
    onError: (error, variables, stackTrace) {
      print('Failed to create user: $error');
    },
  ),
);

/// Mutation provider for updating a user
StateNotifierProvider<MutationNotifier<User, Map<String, dynamic>>, MutationState<User>> updateUserMutationProvider(int userId) {
  return mutationProvider<User, Map<String, dynamic>>(
    name: 'update-user-$userId',
    mutationFn: (variables) => ApiService.updateUser(userId, variables),
    options: MutationOptions<User, Map<String, dynamic>>(
      onSuccess: (user, variables) {
        print('User updated successfully: ${user.name}');
        // In a real app, you might invalidate related queries here
      },
      onError: (error, variables, stackTrace) {
        print('Failed to update user: $error');
      },
    ),
  );
}

/// Mutation provider for deleting a user
StateNotifierProvider<MutationNotifier<void, int>, MutationState<void>> deleteUserMutationProvider(int userId) {
  return mutationProvider<void, int>(
    name: 'delete-user-$userId',
    mutationFn: (id) => ApiService.deleteUser(id),
    options: MutationOptions<void, int>(
      onSuccess: (_, id) {
        print('User $id deleted successfully');
        // In a real app, you might invalidate the users query here
      },
      onError: (error, id, stackTrace) {
        print('Failed to delete user $id: $error');
      },
    ),
  );
}
