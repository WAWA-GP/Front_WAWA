// lib/api_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // TimeoutException 사용을 위해 import
import 'package:hive_flutter/hive_flutter.dart';
import 'package:learning_app/models/user_profile.dart';
import 'package:learning_app/models/statistics_model.dart';
import 'package:learning_app/main.dart';
import 'package:uuid/uuid.dart' show Uuid;

// API 통신 중 발생하는 예외를 처리하기 위한 클래스
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  // --- Singleton 설정 ---
  ApiService._privateConstructor();
  static final ApiService _instance = ApiService._privateConstructor();
  factory ApiService() {
    return _instance;
  }

  final Box _userSettingsBox = Hive.box('userSettings');

  // --- 기본 설정 ---
  static const String _authPlanStatsBaseUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://10.0.2.2:8001' // 기본값은 에뮬레이터용으로 설정
  );

  static const String _aiBaseUrl = String.fromEnvironment(
      'AI_BACKEND_URL',
      defaultValue: 'http://10.0.2.2:8000' // AI 서버 포트
  );

  static const Duration _timeoutDuration = Duration(seconds: 30);

  // --- 토큰 및 헤더 관리 ---
  Future<String?> getToken() async {
    return _userSettingsBox.get('auth_token');
  }

  Future<void> saveToken(String token) async {
    await _userSettingsBox.put('auth_token', token);
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> saveAutoLoginPreference(bool autoLogin) async {
    await _userSettingsBox.put('auto_login', autoLogin);
  }

  Future<bool> getAutoLoginPreference() async {
    return _userSettingsBox.get('auto_login', defaultValue: false);
  }

  // 👇 [수정] 로그아웃 시 토큰뿐만 아니라 자동 로그인 설정도 함께 삭제합니다.
  Future<void> logout() async {
    await _userSettingsBox.delete('auth_token');
    await _userSettingsBox.delete('auto_login');
  }

  Future<Map<String, dynamic>> analyzeAndSavePronunciation({
    required String audioPath,
    required String targetText,
  }) async {
    final userId = AppState.userId;
    if (userId == null) throw ApiException('사용자 ID가 없습니다. 다시 로그인해주세요.');

    // main.py에 정의된 엔드포인트 주소
    final url = Uri.parse('$_aiBaseUrl/api/pronunciation/analyze');
    final headers = await _getAuthHeaders();

    final file = File(audioPath);
    final audioBytes = await file.readAsBytes();
    final base64Audio = base64Encode(audioBytes);

    final body = jsonEncode({
      'audio_base64': base64Audio,
      'target_text': targetText,
      'user_level': AppState.userLevel ?? 'B1',
      'language': 'en',
      // 👇 DB에 저장하기 위한 필수 정보들을 함께 보냅니다.
      'save_to_database': true,
      'user_id': userId,
      'session_id': const Uuid().v4(), // 고유한 세션 ID 생성
    });

    final response = await http.post(url, headers: headers, body: body).timeout(_timeoutDuration);
    return _processResponse(response);
  }

  Future<StatisticsResponse> getStatistics() async {
    final userId = AppState.userId;
    if (userId == null) {
      throw ApiException('사용자 ID를 찾을 수 없습니다. 다시 로그인해주세요.');
    }

    final url = Uri.parse('$_authPlanStatsBaseUrl/api/statistics/statistics/$userId');
    final headers = await _getAuthHeaders();
    if (!headers.containsKey('Authorization')) throw ApiException('로그인이 필요합니다.');

    final response = await http.get(url, headers: headers).timeout(_timeoutDuration);
    final responseBody = _processResponse(response);

    // JSON 응답을 StatisticsResponse 객체로 변환하여 반환
    return StatisticsResponse.fromJson(responseBody);
  }
  // --- 응답 처리 ---
  dynamic _processResponse(http.Response response) {
    // UTF-8로 디코딩하여 한글 깨짐 방지
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      // FastAPI 오류 응답 형식 ('detail')에 맞춰서 에러 메시지 추출
      final errorMessage = body['detail'] ?? '알 수 없는 오류가 발생했습니다.';
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  // --- API 함수들 ---

  // 회원가입
  Future<Map<String, dynamic>> register({required String email, required String password, required String name}) async {
    final url = Uri.parse('$_authPlanStatsBaseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'password': password, 'name': name, 'is_admin': false}),
    ).timeout(_timeoutDuration);

    final responseBody = _processResponse(response);
    if (responseBody['access_token'] != null) {
      await saveToken(responseBody['access_token']);
    }
    // 👇 [수정] responseBody를 그대로 반환합니다.
    return responseBody;
  }

  Future<void> createProfile() async {
    final url = Uri.parse('$_authPlanStatsBaseUrl/auth/create-profile');
    final headers = await _getAuthHeaders(); // 토큰이 포함된 헤더 가져오기
    if (!headers.containsKey('Authorization')) throw ApiException('로그인이 필요합니다.');

    final response = await http.post(url, headers: headers).timeout(_timeoutDuration);
    _processResponse(response); // 성공 여부만 확인
  }

  // 로그인
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final url = Uri.parse('$_authPlanStatsBaseUrl/auth/login');
    // FastAPI의 OAuth2PasswordRequestForm은 x-www-form-urlencoded 형식을 기대합니다.
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    ).timeout(_timeoutDuration);

    final responseBody = _processResponse(response);
    if (responseBody['access_token'] != null) {
      await saveToken(responseBody['access_token']);
    }
    return responseBody;
  }

  Future<Map<String, dynamic>> attemptAutoLogin() async {
    final token = await getToken();
    if (token == null) {
      // 기기에 토큰이 없으면 바로 실패 처리
      return {'status': 'error', 'message': 'No token found'};
    }

    final url = Uri.parse('$_authPlanStatsBaseUrl/auth/login/auto');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'token': token}),
    ).timeout(_timeoutDuration);

    // _processResponse는 2xx가 아닐 때 오류를 던지므로, try-catch로 감쌉니다.
    try {
      return _processResponse(response);
    } catch(e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // 사용자 프로필 조회
  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('$_authPlanStatsBaseUrl/auth/profile');
    final headers = await _getAuthHeaders();
    if (!headers.containsKey('Authorization')) throw ApiException('로그인이 필요합니다.');

    final response = await http.get(url, headers: headers).timeout(_timeoutDuration);
    return _processResponse(response);
  }

  // (참고) /auth/me 엔드포인트용 함수 (현재는 /profile로 통일하여 사용 중)
  Future<UserProfile> getCurrentUser() async {
    final url = Uri.parse('$_authPlanStatsBaseUrl/auth/me'); // 이 엔드포인트는 현재 사용하지 않을 수 있습니다.
    final headers = await _getAuthHeaders();
    if (!headers.containsKey('Authorization')) throw ApiException('로그인이 필요합니다.');

    final response = await http.get(url, headers: headers).timeout(_timeoutDuration);
    final responseBody = _processResponse(response);
    return UserProfile.fromJson(responseBody);
  }

  // 레벨 테스트 결과 업데이트
  Future<void> updateUserLevel({required String userId, required String assessedLevel}) async {
    final url = Uri.parse('$_authPlanStatsBaseUrl/auth/update-level');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({'email': userId, 'assessed_level': assessedLevel});

    final response = await http.post(url, headers: headers, body: body).timeout(_timeoutDuration);
    _processResponse(response);
  }

  // 최신 학습 계획 조회
  Future<Map<String, dynamic>?> getLatestLearningPlan() async {
    final url = Uri.parse('$_authPlanStatsBaseUrl/api/plans/latest');
    final headers = await _getAuthHeaders();
    if (!headers.containsKey('Authorization')) throw ApiException('로그인이 필요합니다.');

    try {
      final response = await http.get(url, headers: headers).timeout(_timeoutDuration);
      // 404 (계획 없음) 오류는 정상적인 상황이므로 null을 반환하여 처리
      if (response.statusCode == 404) {
        return null;
      }
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      rethrow; // 그 외 다른 오류는 다시 던져서 상위에서 처리하도록 함
    }
  }

  // 학습 목표(계획) 생성
  Future<Map<String, dynamic>> createLearningPlan({
    required String userId,
    required int currentLevel,
    required int goalLevel,
    required String frequencyType,
    required int frequencyValue,
    required int sessionDuration,
    required List<String> preferredStyles,
  }) async {
    final url = Uri.parse('$_authPlanStatsBaseUrl/api/plans/create');
    final headers = await _getAuthHeaders();
    if (!headers.containsKey('Authorization')) throw ApiException('로그인이 필요합니다.');

    final body = jsonEncode({
      'user_id': userId,
      'current_level': currentLevel,
      'goal_level': goalLevel,
      'frequency_type': frequencyType,
      'frequency_value': frequencyValue,
      'session_duration_minutes': sessionDuration,
      'preferred_styles': preferredStyles,
    });

    final response = await http.post(url, headers: headers, body: body).timeout(_timeoutDuration);
    return _processResponse(response);
  }
}