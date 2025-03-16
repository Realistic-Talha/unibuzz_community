class SearchIndex {
  static List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static double calculateRelevance(String query, Map<String, dynamic> item) {
    final queryTokens = tokenize(query);
    if (queryTokens.isEmpty) return 0;

    int matches = 0;
    final content = [
      item['title'] ?? '',
      item['description'] ?? '',
      ...(item['tags'] as List<String>? ?? []),
    ].join(' ').toLowerCase();

    for (final token in queryTokens) {
      if (content.contains(token)) {
        matches++;
      }
    }

    return matches / queryTokens.length;
  }

  static List<T> search<T>({
    required String query,
    required List<T> items,
    required List<String> Function(T item) getSearchableStrings,
  }) {
    if (query.isEmpty) return items;

    final results = items.map((item) {
      final searchableContent = getSearchableStrings(item).join(' ');
      final relevance = calculateRelevance(query, {'description': searchableContent});
      return {'item': item, 'relevance': relevance};
    }).where((result) {
      return ((result['relevance'] as double?) ?? 0) > 0;  // Fixed boolean return
    }).toList();

    results.sort((a, b) => ((b['relevance'] as double?) ?? 0)
        .compareTo((a['relevance'] as double?) ?? 0));

    return results.map((result) => result['item'] as T).toList();
  }
}
