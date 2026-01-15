import 'dart:convert';

import 'package:http/http.dart' as http;

class ClasslyApiException implements Exception {
  ClasslyApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ClasslyApiException($statusCode): $message';
}

class ClasslyEventTopic {
  ClasslyEventTopic({
    required this.id,
    required this.topicType,
    this.content,
    this.count,
    this.pages,
    this.order,
    this.parentId,
  });

  final String id;
  final String topicType;
  final String? content;
  final int? count;
  final String? pages;
  final int? order;
  final String? parentId;

  factory ClasslyEventTopic.fromJson(Map<String, dynamic> json) {
    return ClasslyEventTopic(
      id: json['id'] as String,
      topicType: json['topic_type'] as String,
      content: json['content'] as String?,
      count: json['count'] as int?,
      pages: json['pages'] as String?,
      order: json['order'] as int?,
      parentId: json['parent_id'] as String?,
    );
  }
}

class ClasslyEventLink {
  ClasslyEventLink({
    required this.id,
    required this.url,
    required this.label,
  });

  final String id;
  final String url;
  final String label;

  factory ClasslyEventLink.fromJson(Map<String, dynamic> json) {
    return ClasslyEventLink(
      id: json['id'] as String,
      url: json['url'] as String,
      label: json['label'] as String,
    );
  }
}

class ClasslyEvent {
  ClasslyEvent({
    required this.id,
    required this.type,
    required this.priority,
    required this.classId,
    this.subjectId,
    this.subjectName,
    this.title,
    this.date,
    this.createdAt,
    this.updatedAt,
    this.authorId,
    this.topics = const [],
    this.links = const [],
  });

  final String id;
  final String type;
  final String priority;
  final String classId;
  final String? subjectId;
  final String? subjectName;
  final String? title;
  final DateTime? date;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? authorId;
  final List<ClasslyEventTopic> topics;
  final List<ClasslyEventLink> links;

  factory ClasslyEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null) return null;
      return DateTime.tryParse(value);
    }

    final topicsJson = json['topics'] as List<dynamic>? ?? [];
    final linksJson = json['links'] as List<dynamic>? ?? [];

    return ClasslyEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      priority: (json['priority'] as String?) ?? 'MEDIUM',
      classId: json['class_id'] as String,
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String?,
      title: json['title'] as String?,
      date: parseDate(json['date'] as String?),
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
      authorId: json['author_id'] as String?,
      topics: topicsJson
          .map((t) => ClasslyEventTopic.fromJson(t as Map<String, dynamic>))
          .toList(),
      links: linksJson
          .map((l) => ClasslyEventLink.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ClasslySubject {
  ClasslySubject({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final String color;

  factory ClasslySubject.fromJson(Map<String, dynamic> json) {
    return ClasslySubject(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }
}

class ClasslyClient {
  ClasslyClient({
    required this.baseUrl,
    http.Client? httpClient,
    String? token,
  })  : _http = httpClient ?? http.Client(),
        _token = token;

  final String baseUrl;
  final http.Client _http;
  String? _token;

  String? get token => _token;

  Map<String, String> _defaultHeaders() {
    if (_token == null) {
      throw ClasslyApiException(
          'No token set. Call issueToken or set token first.');
    }
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }

  Future<String> issueToken({
    String? email,
    String? password,
    int? expiresInDays,
  }) async {
    final uri = Uri.parse('$baseUrl/api/token');
    final body = <String, String>{};
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    if (expiresInDays != null) {
      body['expires_in_days'] = expiresInDays.toString();
    }

    final resp = await _http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (resp.statusCode != 200) {
      throw ClasslyApiException(
        'Token request failed: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) {
      throw ClasslyApiException('Token missing in response');
    }
    _token = accessToken;
    return accessToken;
  }

  Future<List<ClasslyEvent>> fetchEvents({
    DateTime? updatedSince,
    int limit = 200,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (updatedSince != null) {
      params['updated_since'] = updatedSince.toIso8601String();
    }
    final uri =
        Uri.parse('$baseUrl/api/events').replace(queryParameters: params);

    final resp = await _http.get(uri, headers: _defaultHeaders());
    if (resp.statusCode != 200) {
      throw ClasslyApiException(
        'Fetching events failed: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final eventsJson = data['events'] as List<dynamic>? ?? [];
    return eventsJson
        .map((e) => ClasslyEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ClasslySubject>> fetchSubjects() async {
    final uri = Uri.parse('$baseUrl/api/subjects');
    final resp = await _http.get(uri, headers: _defaultHeaders());
    if (resp.statusCode != 200) {
      throw ClasslyApiException(
        'Fetching subjects failed: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final subjectsJson = data['subjects'] as List<dynamic>? ?? [];
    return subjectsJson
        .map((s) => ClasslySubject.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  // --- OAuth 2.0 Integration ---

  /// Exchanges an authorization code for an access token.
  Future<Map<String, dynamic>> exchangeCodeForToken({
    required String code,
    required String redirectUri,
    required String clientId,
    String? clientSecret,
  }) async {
    final uri = Uri.parse('$baseUrl/api/oauth/token');
    final body = {
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'redirect_uri': redirectUri,
      if (clientSecret != null) 'client_secret': clientSecret,
    };

    final resp = await _http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (resp.statusCode != 200) {
      throw ClasslyApiException(
        'Token exchange failed: ${resp.body}',
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

  /// Fetches information about the authenticated user.
  Future<ClasslyUserInfo> getUserInfo() async {
    final uri = Uri.parse('$baseUrl/api/oauth/userinfo');
    final resp = await _http.get(uri, headers: _defaultHeaders());

    if (resp.statusCode != 200) {
      throw ClasslyApiException(
        'Fetching user info failed: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }

    return ClasslyUserInfo.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // --- Push Notifications ---

  /// Registers a device token for push notifications.
  Future<void> registerPushToken({
    required String deviceToken,
    required String platform, // 'fcm' or 'apns'
  }) async {
    final uri = Uri.parse('$baseUrl/api/push/register');
    final body = jsonEncode({
      'device_token': deviceToken,
      'platform': platform,
    });

    final resp = await _http.post(uri, headers: _defaultHeaders(), body: body);

    if (resp.statusCode != 200) {
      // Don't throw if it's just already registered or minor issue? 
      // Docs say 200 OK. Let's strict for now.
      throw ClasslyApiException(
        'Registering push token failed: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
  }

  /// Unregisters a device token (e.g. on logout).
  Future<void> unregisterPushToken(String deviceToken) async {
    final uri = Uri.parse('$baseUrl/api/push/unregister');
    final body = jsonEncode({'device_token': deviceToken});

    final resp = await _http.delete(uri, headers: _defaultHeaders(), body: body);

    if (resp.statusCode != 200) {
      throw ClasslyApiException(
        'Unregistering push token failed: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
  }
}

class ClasslyUserInfo {
  ClasslyUserInfo({
    required this.sub,
    required this.name,
    required this.role,
    required this.classId,
    this.className,
    this.email,
    this.isRegistered = false,
  });

  final String sub;
  final String name;
  final String role;
  final String classId;
  final String? className;
  final String? email;
  final bool isRegistered;

  factory ClasslyUserInfo.fromJson(Map<String, dynamic> json) {
    return ClasslyUserInfo(
      sub: json['sub'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      classId: json['class_id'] as String,
      className: json['class_name'] as String?,
      email: json['email'] as String?,
      isRegistered: json['is_registered'] as bool? ?? false,
    );
  }
}
