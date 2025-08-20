# 🔧 **Debug Voice Call - Sửa lỗi kết nối**

## ❌ **Vấn đề: "Lỗi kết nối"**

### 🔍 **Các nguyên nhân có thể:**

1. **❌ Permissions chưa được cấp**
2. **❌ Internet connection yếu**
3. **❌ Agora SDK chưa được cấu hình đúng**
4. **❌ App ID không hợp lệ**
5. **❌ Device không hỗ trợ**

## 🛠️ **Giải pháp từng bước:**

### **Bước 1: Test Connection**
1. Vào **Profile** → **Test Voice Call**
2. Nhấn **"Test Connection"**
3. Xem kết quả và logs

### **Bước 2: Kiểm tra Permissions**

**Android:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CALL_PHONE" />
```

**iOS:**
```xml
<!-- ios/Runner/Info.plist -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone for voice calls</string>
```

### **Bước 3: Kiểm tra Internet**
- Đảm bảo có kết nối internet tốt
- Test trên WiFi và 4G/5G
- Tắt VPN nếu có

### **Bước 4: Kiểm tra App ID**
```dart
// lib/services/voice_call_service_improved.dart
static const String appId = "aec4d4a14d994fb1904ce07a17cd4c2c";
```

### **Bước 5: Debug Logs**

Xem logs trong console:
```
🔧 Initializing Agora SDK...
🎤 Microphone permission status: granted
🔊 Audio configuration completed
✅ Voice call service initialized successfully
🚀 Attempting to join call: test_channel_123
📞 Join call request sent for channel: test_channel_123
✅ Voice call joined successfully: test_channel_123
```

## 🧪 **Test trên 2 thiết bị:**

### **Thiết bị 1:**
1. Vào **Test Voice Call**
2. Nhập channel: `test123`
3. Nhấn **"Join Call"**
4. Chờ status: "Đã kết nối"

### **Thiết bị 2:**
1. Vào **Test Voice Call**
2. Nhập channel: `test123` (cùng tên)
3. Nhấn **"Join Call"**
4. Sẽ thấy: "Người khác đã tham gia"

## 🔍 **Debug Commands:**

### **1. Clean & Rebuild:**
```bash
flutter clean
flutter pub get
flutter run
```

### **2. Check Permissions:**
```bash
# Android
adb shell dumpsys package com.example.ha_phuong_app | grep permission

# iOS - Check in Settings > Privacy > Microphone
```

### **3. Network Test:**
```bash
# Test internet connection
ping google.com
```

## ⚠️ **Common Issues:**

### **Issue 1: "Cần cấp quyền microphone"**
**Solution:** Vào Settings → Apps → Ha Phuong App → Permissions → Enable Microphone

### **Issue 2: "Cấu hình App ID không hợp lệ"**
**Solution:** Kiểm tra App ID trong code có đúng không

### **Issue 3: "Lỗi khởi tạo"**
**Solution:** 
- Restart app
- Check internet connection
- Try on different device

### **Issue 4: "Không thể tham gia"**
**Solution:**
- Use different channel name
- Check if other user is in same channel
- Restart both apps

## 📱 **Device Requirements:**

### **Android:**
- Android 5.0+ (API 21+)
- ARM64 hoặc ARMv7
- Microphone permission

### **iOS:**
- iOS 9.0+
- Microphone permission
- Real device (không phải simulator)

## 🎯 **Expected Behavior:**

### **Successful Connection:**
```
Status: "Đã kết nối"
Remote User: > 0
Mute/Speaker buttons: Active
Timer: Running
```

### **Failed Connection:**
```
Status: "Lỗi kết nối" / "Không thể kết nối"
Remote User: 0
No audio controls
```

## 🔧 **Advanced Debug:**

### **Enable Verbose Logging:**
```dart
// In voice_call_service_improved.dart
await _engine!.setLogLevel(LogLevel.logLevelInfo);
await _engine!.setLogFile('/path/to/agora.log');
```

### **Check Network Quality:**
```dart
// Monitor network quality in logs
onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
  print('📶 Network quality - TX: $txQuality, RX: $rxQuality');
}
```

## 🚀 **Quick Fix Checklist:**

- [ ] ✅ App ID đúng: `aec4d4a14d994fb1904ce07a17cd4c2c`
- [ ] ✅ Permissions được cấp
- [ ] ✅ Internet connection tốt
- [ ] ✅ Test trên real device
- [ ] ✅ Same channel name trên 2 devices
- [ ] ✅ Flutter clean & rebuild
- [ ] ✅ Check console logs

## 📞 **Test Steps:**

1. **Profile** → **Test Voice Call**
2. **Test Connection** → Should show "successful"
3. **Enter channel name:** `test123`
4. **Join Call** → Status: "Đã kết nối"
5. **On 2nd device:** Same steps with same channel
6. **Should hear each other!** 🎉

---

**Nếu vẫn lỗi, hãy gửi console logs để debug chi tiết hơn! 🔍**