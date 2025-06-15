import 'package:flutter/material.dart';
import 'dart:async';
import '../data/news_api.dart';
import '../models/news_model.dart';
import '../widgets/news_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsApi _api = NewsApi();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _bookmarkedArticles = <String>{};

  late Future<List<NewsModel>> _news;
  String _selectedCategory = 'general';
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _news = _api.fetchTopHeadlines(category: _selectedCategory);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        _loadCategoryNews(_selectedCategory);
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
      _news = _api.searchArticles(query: query);
    });
  }

  void _loadCategoryNews(String category) {
    setState(() {
      _selectedCategory = category;
      _isSearching = false;
      _news = _api.fetchTopHeadlines(category: category);
    });
  }

  void _toggleBookmark(NewsModel article) {
    setState(() {
      if (_bookmarkedArticles.contains(article.id)) {
        _bookmarkedArticles.remove(article.id);
      } else {
        _bookmarkedArticles.add(article.id);
      }
    });
  }

  bool _isBookmarked(NewsModel article) {
    return _bookmarkedArticles.contains(article.id);
  }

  void _clearSearch() {
    _searchController.clear();
    _loadCategoryNews(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSearching ? 'Search Results' : 'News'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search articles...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              // Category Filters
              if (!_isSearching)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildCategoryChip('general', 'General'),
                      _buildCategoryChip('business', 'Business'),
                      _buildCategoryChip('technology', 'Tech'),
                      _buildCategoryChip('sports', 'Sports'),
                      _buildCategoryChip('entertainment', 'Entertainment'),
                      _buildCategoryChip('health', 'Health'),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<NewsModel>>(
        future: _news,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Failed to load news",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please check your internet connection and try again",
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _news = _api.fetchTopHeadlines(category: _selectedCategory);
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? "No search results found" : "No news available",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSearching
                        ? "Try searching with different keywords"
                        : "Please try again later",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          } else {
            final newsList = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _news = _isSearching
                      ? _api.searchArticles(query: _searchController.text)
                      : _api.fetchTopHeadlines(category: _selectedCategory);
                });
              },
              child: ListView.builder(
                itemCount: newsList.length,
                itemBuilder: (context, index) => NewsCard(
                  news: newsList[index],
                  isBookmarked: _isBookmarked(newsList[index]),
                  onBookmarkToggle: () => _toggleBookmark(newsList[index]),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _loadCategoryNews(category);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}