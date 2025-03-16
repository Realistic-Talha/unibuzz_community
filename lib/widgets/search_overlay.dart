import 'package:flutter/material.dart';
import 'package:unibuzz_community/utils/debouncer.dart';

class SearchOverlay extends StatefulWidget {
  final String hint;
  final List<String> filters;
  final Function(String query, String filter) onSearch;
  final Widget Function(dynamic item) itemBuilder;
  final Stream<List<dynamic>> itemsStream;

  const SearchOverlay({
    super.key,
    required this.hint,
    required this.filters,
    required this.onSearch,
    required this.itemBuilder,
    required this.itemsStream,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _debouncer.run(() {
                          widget.onSearch(value, _selectedFilter);
                        });
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearch('', _selectedFilter);
                      },
                    ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: _selectedFilter == filter,
                    label: Text(filter),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter : 'All';
                      });
                      widget.onSearch(_searchController.text, _selectedFilter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: widget.itemsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No results found',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => widget.itemBuilder(items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
