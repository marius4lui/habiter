import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/integrations/classly/classly_endpoint.dart';

/// A failure while calling or validating a Classly-compatible endpoint.
class ClasslyApiException implements Exception {
  ClasslyApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ClasslyApiException($statusCode): $message';
}

/// The event fields Habiter consumes from a Classly-compatible service.
class ClasslyEvent {
  ClasslyEvent({
    required this.id,
    required this.type,
    this.subjectName,
    this.title,
    this.date,
    this.createdAt,
  });

  final String id;
  final String type;
  final String? subjectName;
  final String? title;
  final DateTime? date;
  final DateTime? createdAt;

  factory ClasslyEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null) return null;
      return DateTime.tryParse(value);
    }

    return ClasslyEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      subjectName: json['subject_name'] as String?,
      title: json['title'] as String?,
      date: parseDate(json['date'] as String?),
      createdAt: parseDate(json['created_at'] as String?),
    );
  }
}

/// HTTP client for Habiter's minimal Classly-compatible integration contract.
class ClasslyClient {
  ClasslyClient({
    required String baseUrl,
    http.Client? httpClient,
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) : baseUrl = ClasslyEndpoint.parse(baseUrl).origin.toString(),
       _http = httpClient ?? http.Client(),
       _timeout = timeout,
       _token = token;

  final String baseUrl;
  final http.Client _http;
  final Duration _timeout;
  String? _token;

  Map<String, String> _defaultHeaders() {
    if (_token == null) {
      throw ClasslyApiException('No access token is configured.');
    }
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<ClasslyEvent>> fetchEvents({
    DateTime? updatedSince,
    int limit = 200,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (updatedSince != null) {
      params['updated_since'] = updatedSince.toIso8601String();
    }
    final uri = Uri.parse(
      '$baseUrl/api/events',
    ).replace(queryParameters: params);

    final resp = await _http
        .get(uri, headers: _defaultHeaders())
        .timeout(_timeout);
    if (resp.statusCode != 200) {
      throw ClasslyApiException(
        'Fetching events failed.',
        statusCode: resp.statusCode,
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final eventsJson = data['events'] as List<dynamic>? ?? [];
    return eventsJson
        .map((e) => ClasslyEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Exchanges an authorization code for an access token.
  Future<Map<String, dynamic>> exchangeCodeForToken({
    required String code,
    required String redirectUri,
    required String clientId,
    required String codeVerifier,
  }) async {
    final uri = Uri.parse('$baseUrl/api/oauth/token');
    final body = {
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'code_verifier': codeVerifier,
    };

    final resp = await _http
        .post(
          uri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        )
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      throw ClasslyApiException(
        'Token exchange failed.',
        statusCode: resp.statusCode,
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) {
      throw ClasslyApiException('Access token missing in response');
    }

    // Update local token
    _token = accessToken;
    return data;
  }
}
