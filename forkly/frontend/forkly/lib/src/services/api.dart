import 'package:dio/dio.dart';

class Api {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000')}/api/'));
  
  Future<List<dynamic>> nearby(double lat, double lng, {int radius=1500}) async {
    final r = await _dio.get('nearby/', queryParameters: {"lat":lat,"lng":lng,"radius":radius});
    return r.data;
  }
  
  Future<List<dynamic>> search(String q, double lat, double lng, {int radius=1500}) async {
    final r = await _dio.get('search/', queryParameters: {"q":q,"lat":lat,"lng":lng,"radius":radius});
    return r.data;
  }
  
  Future<Map<String,dynamic>> register(String username, String password, {String? referral}) async {
    final r = await _dio.post('auth/register/', data: {"username":username, "password":password, "referral_code":referral});
    return r.data;
  }
  
  Future<void> track(String code, String status) async {
    await _dio.post('referrals/track/', data: {"code":code,"status":status});
  }
}
