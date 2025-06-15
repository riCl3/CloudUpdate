// lib/data/news_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/news_model.dart';

class NewsApi {
  static const String _baseUrl = 'https://newsapi.org/v2';

  String get _apiKey => dotenv.env['NEWS_API_KEY'] ?? '';

  // Fetch top headlines with category filtering
  Future<List<NewsModel>> fetchTopHeadlines({
    String? category,
    String? country = 'us',
    int pageSize = 20,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/top-headlines?country=$country&pageSize=$pageSize&page=$page&apiKey=$_apiKey';

      if (category != null && category.isNotEmpty && category != 'general') {
        url += '&category=$category';
      }

      final response = await http.get(Uri.parse(url));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch top headlines: $e');
    }
  }

  // Search articles with various parameters
  Future<List<NewsModel>> searchArticles({
    required String query,
    String? fromDate,
    String? toDate,
    String? sortBy = 'publishedAt',
    String? language = 'en',
    int pageSize = 20,
    int page = 1,
  }) async {
    try {
      if (query.trim().isEmpty) {
        throw Exception('Search query cannot be empty');
      }

      String url = '$_baseUrl/everything?q=${Uri.encodeComponent(query.trim())}&sortBy=$sortBy&language=$language&pageSize=$pageSize&page=$page&apiKey=$_apiKey';

      if (fromDate != null) url += '&from=$fromDate';
      if (toDate != null) url += '&to=$toDate';

      final response = await http.get(Uri.parse(url));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to search articles: $e');
    }
  }

  // Fetch news from specific sources
  Future<List<NewsModel>> fetchFromSources({
    required String sources,
    int pageSize = 20,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/top-headlines?sources=$sources&pageSize=$pageSize&page=$page&apiKey=$_apiKey';
      final response = await http.get(Uri.parse(url));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch from sources: $e');
    }
  }

  // Fetch news from specific domains
  Future<List<NewsModel>> fetchFromDomains({
    required String domains,
    String? sortBy = 'publishedAt',
    int pageSize = 20,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/everything?domains=$domains&sortBy=$sortBy&pageSize=$pageSize&page=$page&apiKey=$_apiKey';
      final response = await http.get(Uri.parse(url));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch from domains: $e');
    }
  }

  // Get available news sources
  Future<List<Map<String, dynamic>>> fetchSources({
    String? category,
    String? language = 'en',
    String? country,
  }) async {
    try {
      String url = '$_baseUrl/sources?language=$language&apiKey=$_apiKey';

      if (category != null) url += '&category=$category';
      if (country != null) url += '&country=$country';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final sources = jsonData['sources'] as List? ?? [];
        return sources.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch sources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch sources: $e');
    }
  }

  // Generic fetch method for backward compatibility
  Future<List<NewsModel>> fetchNews({
    String? query,
    String? fromDate,
    String? toDate,
    String? sortBy,
    String? category,
    String? country,
    String? source,
    String? domain,
  }) async {
    try {
      if (source != null) {
        return fetchFromSources(sources: source);
      } else if (domain != null) {
        return fetchFromDomains(domains: domain, sortBy: sortBy);
      } else if (category != null && country != null) {
        return fetchTopHeadlines(category: category, country: country);
      } else if (query != null && query.trim().isNotEmpty) {
        return searchArticles(
          query: query,
          fromDate: fromDate,
          toDate: toDate,
          sortBy: sortBy,
        );
      } else {
        return fetchTopHeadlines(country: country ?? 'us');
      }
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  List<NewsModel> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      // Check for API errors
      if (jsonData['status'] == 'error') {
        throw Exception('API Error: ${jsonData['message'] ?? 'Unknown error'}');
      }

      final articles = jsonData['articles'] as List? ?? [];

      // Filter out articles with null or empty essential fields
      final validArticles = articles.where((article) {
        return article != null &&
            article['title'] != null &&
            article['title'].toString().trim().isNotEmpty &&
            article['url'] != null &&
            article['url'].toString().trim().isNotEmpty;
      }).toList();

      return validArticles.map((e) => NewsModel.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key. Please check your NEWS_API_KEY in .env file');
    } else if (response.statusCode == 429) {
      throw Exception('API rate limit exceeded. Please try again later');
    } else if (response.statusCode == 426) {
      throw Exception('API upgrade required. Please check your subscription');
    } else {
      throw Exception('Failed to fetch news: ${response.statusCode} - ${response.body}');
    }
  }
}