// lib/pages/home_screen/services/alert_api.dart
import 'package:dio/dio.dart';
import 'package:APP/pages/home_screen/model/alert.dart';

class AlertApi {
  static const String _baseUrl = 'BASE_URL'; // 환경변수에서 가져올 예정
  
  static Future<AlertResponse> getAlerts({
    required int petId,
    required String accessToken,
    String? baseUrl,
    bool? isRead,
  }) async {
    final dio = Dio();
    
    // BASE_URL 검증
    final finalBaseUrl = baseUrl ?? _baseUrl;
    if (finalBaseUrl.isEmpty) {
      throw Exception('서버 설정이 올바르지 않습니다. 앱을 다시 시작해주세요.');
    }
    
    // 헤더 설정
    dio.options.headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    
    // 쿼리 파라미터 설정
    final queryParams = <String, dynamic>{};
    if (isRead != null) {
      queryParams['isRead'] = isRead;
    }
    
    final url = '$finalBaseUrl/api/v1/pets/$petId/alerts';
    
    try {
      // 디버깅을 위한 로그
      print('🔔 AlertApi.getAlerts - URL: $url');
      print('🔔 AlertApi.getAlerts - QueryParams: $queryParams');
      
      final response = await dio.get(url, queryParameters: queryParams);
      
      print('🔔 AlertApi.getAlerts - StatusCode: ${response.statusCode}');
      print('🔔 AlertApi.getAlerts - Response: ${response.data}');
      
      if (response.statusCode == 200) {
        // 응답 데이터 검증
        if (response.data == null) {
          throw Exception('서버에서 빈 응답을 받았습니다.');
        }
        
        // JSON 파싱 시도
        try {
          final result = AlertResponse.fromJson(response.data);
          print('🔔 AlertApi.getAlerts - Parsed alerts count: ${result.alerts.length}');
          return result;
        } catch (parseError) {
          print('🔔 AlertApi.getAlerts - Parse error: $parseError');
          throw Exception('서버 응답 형식이 올바르지 않습니다. 개발자에게 문의해주세요.');
        }
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode!;
        final errorData = e.response!.data;
        String message = '알림 조회 중 오류가 발생했습니다.';
        
        // 서버에서 제공하는 에러 메시지 추출
        if (errorData is Map<String, dynamic>) {
          message = errorData['message'] as String? ?? 
                   errorData['errorMessage'] as String? ?? 
                   errorData['error'] as String? ?? 
                   message;
        }
        
        switch (statusCode) {
          case 401:
            throw Exception('로그인이 필요합니다. 앱을 다시 시작하거나 다시 로그인해주세요.');
          case 403:
            throw Exception('해당 반려동물에 대한 접근 권한이 없습니다. 다른 반려동물을 선택해보세요.');
          case 404:
            throw Exception('요청한 반려동물을 찾을 수 없습니다. 반려동물 정보를 확인해주세요.');
          case 400:
            throw Exception('잘못된 요청입니다. $message');
          case 500:
            throw Exception('서버에서 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
          case 502:
          case 503:
          case 504:
            throw Exception('서버가 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해주세요.');
          default:
            throw Exception('서버 오류 ($statusCode): $message');
        }
      } else {
        // 네트워크 관련 오류
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('서버 연결 시간이 초과되었습니다. 네트워크 상태를 확인해주세요.');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception('서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception('인터넷 연결을 확인해주세요. Wi-Fi 또는 모바일 데이터를 켜주세요.');
        } else {
          throw Exception('네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow; // 이미 처리된 Exception은 그대로 전달
      } else {
        throw Exception('예상치 못한 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }
  
  static Future<void> markAsRead({
    required int petId,
    required int alertId,
    required String accessToken,
    String? baseUrl,
  }) async {
    final dio = Dio();
    
    // BASE_URL 검증
    final finalBaseUrl = baseUrl ?? _baseUrl;
    if (finalBaseUrl.isEmpty) {
      throw Exception('서버 설정이 올바르지 않습니다. 앱을 다시 시작해주세요.');
    }
    
    // 헤더 설정
    dio.options.headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    
    final url = '$finalBaseUrl/api/v1/pets/$petId/alerts/$alertId/read';
    
    try {
      final response = await dio.patch(url);
      
      if (response.statusCode == 200) {
        return; // 성공
      } else {
        throw Exception('읽음 처리 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode!;
        final errorData = e.response!.data;
        String message = '읽음 처리 중 오류가 발생했습니다.';
        
        // 서버에서 제공하는 에러 메시지 추출
        if (errorData is Map<String, dynamic>) {
          message = errorData['message'] as String? ?? 
                   errorData['errorMessage'] as String? ?? 
                   errorData['error'] as String? ?? 
                   message;
        }
        
        switch (statusCode) {
          case 401:
            throw Exception('로그인이 필요합니다. 앱을 다시 시작하거나 다시 로그인해주세요.');
          case 403:
            throw Exception('해당 알림에 대한 접근 권한이 없습니다.');
          case 404:
            throw Exception('요청한 알림을 찾을 수 없습니다. 이미 삭제되었을 수 있습니다.');
          case 400:
            throw Exception('잘못된 요청입니다. $message');
          case 500:
            throw Exception('서버에서 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
          case 502:
          case 503:
          case 504:
            throw Exception('서버가 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해주세요.');
          default:
            throw Exception('서버 오류 ($statusCode): $message');
        }
      } else {
        // 네트워크 관련 오류
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('서버 연결 시간이 초과되었습니다. 네트워크 상태를 확인해주세요.');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception('서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception('인터넷 연결을 확인해주세요. Wi-Fi 또는 모바일 데이터를 켜주세요.');
        } else {
          throw Exception('네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow; // 이미 처리된 Exception은 그대로 전달
      } else {
        throw Exception('예상치 못한 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }
}
