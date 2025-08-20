# 🚀 Deployment Guide - Fix 404 Error for RTC Token

## Problem Summary
The Flutter app is getting a 404 error when trying to fetch RTC tokens from `https://garagebooking.onrender.com/rtcToken`.

## Root Cause
There are **two separate backend servers**:
1. **Main backend** (`index.js`) - handles auth, trips, bookings, chats
2. **Agora token server** (`agora_token_server.js`) - handles `/rtcToken` endpoint

The current deployment only runs the main backend, so the `/rtcToken` endpoint doesn't exist.

## Solution Overview
Deploy both servers as separate services on Render.com

## Step-by-Step Deployment

### 1. Deploy Agora Token Server
```bash
# Create a new directory for the token server
mkdir agora-token-server
cd agora-token-server

# Copy the token server file
cp ../HauPhuongGarage/agora_token_server.js .

# Create package.json for token server
npm init -y
npm install express cors agora-access-token
```

### 2. Create Token Server Package.json
```json
{
  "name": "agora-token-server",
  "version": "1.0.0",
  "description": "Agora RTC Token Server",
  "main": "agora_token_server.js",
  "scripts": {
    "start": "node agora_token_server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "agora-access-token": "^2.0.4"
  }
}
```

### 3. Deploy to Render.com
1. **Create new Web Service** on Render.com
2. **Connect GitHub repository** containing `agora_token_server.js`
3. **Set Environment Variables**:
   - `AGORA_APP_ID`: your_agora_app_id
   - `AGORA_APP_CERTIFICATE`: your_agora_app_certificate
4. **Deploy** - This will give you a URL like `https://agora-token-server-xyz.onrender.com`

### 4. Update Flutter App URLs
Update your Flutter app to use the correct token server URL:

```dart
// In your voice call service, replace the token fetching logic:
final token = await RTCTokenService.getToken(
  channelName: channelName,
  uid: uid,
  isLocal: false, // Use production URL
);
```

### 5. Alternative: Single Server Deployment
If you prefer to use a single server, integrate the token endpoint into the main backend:

**Add to HauPhuongGarage/routes/voiceCallRoutes.js:**
```javascript
const express = require('express');
const router = express.Router();
const {RtcTokenBuilder, RtcRole} = require('agora-access-token');

router.get('/rtcToken', (req, res) => {
  const channelName = req.query.channelName;
  if (!channelName) {
    return res.status(400).json({"error": "channelName is required"});
  }
  
  let uid = req.query.uid || 0;
  const role = RtcRole.PUBLISHER;
  const expireTime = 3600;
  const currentTime = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTime + expireTime;
  
  const token = RtcTokenBuilder.buildTokenWithUid(
    process.env.AGORA_APP_ID,
    process.env.AGORA_APP_CERTIFICATE,
    channelName,
    uid,
    role,
    privilegeExpireTime
  );
  
  return res.json({"token": token});
});

module.exports = router;
```

**Update HauPhuongGarage/index.js:**
```javascript
const voiceCallRoutes = require('./routes/voiceCallRoutes');
app.use('/api/voice', voiceCallRoutes);
```

### 6. Environment Variables Setup
Add these to your Render.com environment variables:
- `AGORA_APP_ID`: your_agora_app_id
- `AGORA_APP_CERTIFICATE`: your_agora_app_certificate

### 7. Test the Fix
After deployment, test the token endpoint:
```bash
# Test the token endpoint
curl "https://your-domain.com/rtcToken?channelName=test&uid=123"
```

Expected response:
```json
{"token":"007eJx...your_token_here..."}
```

## Verification Checklist
- [ ] Agora token server is deployed and running
- [ ] Environment variables are set correctly
- [ ] Flutter app uses the correct token server URL
- [ ] Token endpoint returns valid tokens
- [ ] Voice calls work properly

## Troubleshooting
If you still get 404 errors:
1. Check the deployed URL is correct
2. Verify environment variables are set
3. Check server logs for any errors
4. Ensure the endpoint is `/rtcToken` with GET method
5. Confirm channelName and uid parameters are provided

## URLs to Use
- **Production**: `https://agora-token-server-xyz.onrender.com/rtcToken`
- **Local Development**: `http://localhost:3000/rtcToken`
- **Alternative**: `https://garagebooking.onrender.com/api/voice/rtcToken` (if using single server approach)
