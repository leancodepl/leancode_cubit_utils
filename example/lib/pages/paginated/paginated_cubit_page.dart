import 'package:example/pages/paginated/api.dart';
import 'package:example/pages/paginated/simple_paginated_cubit.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_cubit_utils/leancode_cubit_utils.dart';

class PaginatedCubitScreen extends StatelessWidget {
  const PaginatedCubitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimplePaginatedCubit(MockedApi())..run(),
      child: const PaginatedCubitPage(),
    );
  }
}

class PaginatedCubitPage extends StatelessWidget {
  const PaginatedCubitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PaginatedCubit Page'),
      ),
      body: Column(
        children: [
          const FiltersRow(),
          TextField(
            onChanged: context.read<SimplePaginatedCubit>().updateSearchQuery,
            decoration: const InputDecoration(
              hintText: 'Search',
            ),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: context.read<SimplePaginatedCubit>().refresh,
              child: PaginatedCubitLayout(
                cubit: context.read<SimplePaginatedCubit>(),
                itemBuilder: (context, additionalData, index, items) {
                  final user = items[index];
                  final selectedUsers = additionalData?.selectedUsers ?? {};
                  return UserTile(
                    user: user,
                    isSelected: selectedUsers.contains(user),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FiltersRow extends StatelessWidget {
  const FiltersRow({super.key});

  @override
  Widget build(BuildContext context) {
    void toggleFilter(Filter filter) {
      context.read<SimplePaginatedCubit>().onFilterPressed(filter);
    }

    return PaginatedCubitBuilder(
      cubit: context.read<SimplePaginatedCubit>(),
      builder: (context, state) {
        final availableFilters = state.data.availableFilters;
        final selectedFilters = state.data.selectedFilters;
        if (availableFilters.isEmpty) {
          return const CircularProgressIndicator();
        } else {
          return Wrap(
            spacing: 8,
            children: [
              ...availableFilters
                  .map(
                    (filter) => FilterChip(
                      label: Text(filter.name),
                      selected: selectedFilters.contains(filter),
                      onSelected: (_) => toggleFilter(filter),
                    ),
                  )
                  .toList(),
            ],
          );
        }
      },
    );
  }
}

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.isSelected,
  });

  final User user;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(user.name),
      subtitle: Text(user.jobTitle),
      value: isSelected,
      onChanged: (_) => context.read<SimplePaginatedCubit>().onTilePressed(
            user,
          ),
    );
  }
}
