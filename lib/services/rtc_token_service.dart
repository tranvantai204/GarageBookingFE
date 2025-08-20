import 'dart:convert';
import 'package:http/http.dart' as http;

class RTCTokenService {
  // Production URL - points to main backend voice API
  static const String baseUrl = "https://garagebooking.onrender.com/api/voice";

  // Local development URL
  static const String localUrl = "http://localhost:3000";

  static Future<String?> getToken({
    required String channelName,
    required int uid,
    bool isLocal = false,
  }) async {
    try {
      final url = isLocal
          ? '$localUrl/rtcToken?channelName=$channelName&uid=$uid'
          : '$baseUrl/rtcToken?channelName=$channelName&uid=$uid';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        print(
          '❌ Error getting token: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Exception getting token: $e');
      return null;
    }
  }
}
