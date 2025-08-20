const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'ha-phuong-secret-key';

// Middleware
app.use(cors());
app.use(express.json());

// Demo data
const users = [
  {
    _id: 'admin_1',
    hoTen: 'Admin Hà Phương',
    soDienThoai: '0123456789',
    email: 'admin@haphuong.com',
    matKhau: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
    vaiTro: 'admin'
  },
  {
    _id: 'user_1',
    hoTen: 'Nguyễn Văn A',
    soDienThoai: '0987654321',
    email: 'user@gmail.com',
    matKhau: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
    vaiTro: 'user'
  },
  {
    _id: 'driver_1',
    hoTen: 'Trần Văn Tài',
    soDienThoai: '0111222333',
    email: 'driver@haphuong.com',
    matKhau: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
    vaiTro: 'driver',
    bienSoXe: '51A-12345'
  }
];

const trips = [
  {
    _id: 'trip_1',
    diemDi: 'TP.HCM',
    diemDen: 'Bình Thuận',
    gioKhoiHanh: '2024-01-15T06:00:00Z',
    gioKetThuc: '2024-01-15T10:30:00Z',
    giaVe: 250000,
    soGheTrong: 35,
    tongSoGhe: 45,
    loaiXe: 'ghe_ngoi',
    taiXe: 'Trần Văn Tài',
    bienSoXe: '51A-12345'
  },
  {
    _id: 'trip_2',
    diemDi: 'TP.HCM',
    diemDen: 'Đà Lạt',
    gioKhoiHanh: '2024-01-15T08:00:00Z',
    gioKetThuc: '2024-01-15T14:00:00Z',
    giaVe: 350000,
    soGheTrong: 20,
    tongSoGhe: 22,
    loaiXe: 'limousine',
    taiXe: 'Nguyễn Văn B',
    bienSoXe: '51B-67890'
  }
];

const bookings = [
  {
    _id: 'booking_1',
    userId: 'user_1',
    tripId: 'trip_1',
    hoTen: 'Nguyễn Văn A',
    soDienThoai: '0987654321',
    diemDi: 'TP.HCM',
    diemDen: 'Bình Thuận',
    ngayDi: '2024-01-15',
    gioKhoiHanh: '06:00',
    soGhe: 1,
    tongTien: 250000,
    trangThaiThanhToan: 'da_thanh_toan',
    trangThai: 'da_xac_nhan',
    createdAt: new Date().toISOString()
  }
];

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Hà Phương Bus API Server',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      auth: '/api/auth/login',
      trips: '/api/trips',
      bookings: '/api/bookings',
      users: '/api/users'
    }
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Auth routes
app.post('/api/auth/login', async (req, res) => {
  try {
    const { soDienThoai, matKhau } = req.body;
    
    console.log('Login attempt:', { soDienThoai, matKhau });
    
    if (!soDienThoai || !matKhau) {
      return res.status(400).json({ message: 'Vui lòng nhập đầy đủ thông tin' });
    }

    // Find user
    const user = users.find(u => u.soDienThoai === soDienThoai);
    if (!user) {
      return res.status(401).json({ message: 'Số điện thoại không tồn tại' });
    }

    // Check password (for demo, accept "123456" for all accounts)
    if (matKhau !== '123456') {
      return res.status(401).json({ message: 'Mật khẩu không đúng' });
    }

    // Generate token
    const token = jwt.sign(
      { userId: user._id, vaiTro: user.vaiTro },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      _id: user._id,
      hoTen: user.hoTen,
      soDienThoai: user.soDienThoai,
      email: user.email,
      vaiTro: user.vaiTro,
      token: token
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

app.post('/api/auth/register', async (req, res) => {
  try {
    const { hoTen, soDienThoai, email, matKhau } = req.body;
    
    // Check if user exists
    const existingUser = users.find(u => u.soDienThoai === soDienThoai);
    if (existingUser) {
      return res.status(400).json({ message: 'Số điện thoại đã được sử dụng' });
    }

    // Create new user
    const newUser = {
      _id: 'user_' + Date.now(),
      hoTen,
      soDienThoai,
      email,
      matKhau: await bcrypt.hash(matKhau, 10),
      vaiTro: 'user'
    };

    users.push(newUser);

    // Generate token
    const token = jwt.sign(
      { userId: newUser._id, vaiTro: newUser.vaiTro },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(201).json({
      _id: newUser._id,
      hoTen: newUser.hoTen,
      soDienThoai: newUser.soDienThoai,
      email: newUser.email,
      vaiTro: newUser.vaiTro,
      token: token
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// Trips routes
app.get('/api/trips', (req, res) => {
  res.json({ data: trips });
});

app.get('/api/trips/search', (req, res) => {
  const { diemDi, diemDen, ngayDi } = req.query;
  let filteredTrips = trips;

  if (diemDi) {
    filteredTrips = filteredTrips.filter(trip => 
      trip.diemDi.toLowerCase().includes(diemDi.toLowerCase())
    );
  }

  if (diemDen) {
    filteredTrips = filteredTrips.filter(trip => 
      trip.diemDen.toLowerCase().includes(diemDen.toLowerCase())
    );
  }

  res.json({ data: filteredTrips });
});

// Bookings routes
app.get('/api/bookings', (req, res) => {
  res.json({ data: bookings });
});

app.post('/api/bookings', (req, res) => {
  try {
    const newBooking = {
      _id: 'booking_' + Date.now(),
      ...req.body,
      trangThai: 'da_xac_nhan',
      trangThaiThanhToan: 'chua_thanh_toan',
      createdAt: new Date().toISOString()
    };

    bookings.push(newBooking);
    res.status(201).json({ data: newBooking });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi khi tạo booking' });
  }
});

app.delete('/api/bookings/:id', (req, res) => {
  try {
    const bookingId = req.params.id;
    const bookingIndex = bookings.findIndex(b => b._id === bookingId);
    
    if (bookingIndex === -1) {
      return res.status(404).json({ message: 'Không tìm thấy booking' });
    }

    bookings.splice(bookingIndex, 1);
    res.json({ success: true, message: 'Hủy vé thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi khi hủy booking' });
  }
});

// Users routes
app.get('/api/users', (req, res) => {
  const safeUsers = users.map(user => {
    const { matKhau, ...safeUser } = user;
    return safeUser;
  });
  res.json({ data: safeUsers });
});

// Auth users route (same as /api/users but under /auth path)
app.get('/api/auth/users', (req, res) => {
  const safeUsers = users.map(user => {
    const { matKhau, ...safeUser } = user;
    return safeUser;
  });
  res.json({
    success: true,
    count: safeUsers.length,
    data: safeUsers
  });
});

// Update user profile
app.put('/api/auth/users/:id', (req, res) => {
  try {
    const userId = req.params.id;
    const updateData = req.body;

    const userIndex = users.findIndex(u => u._id === userId);
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy user'
      });
    }

    // Update user data
    users[userIndex] = { ...users[userIndex], ...updateData };
    const { matKhau, ...safeUser } = users[userIndex];

    res.json({
      success: true,
      data: safeUser,
      message: 'Cập nhật thông tin thành công'
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi cập nhật thông tin',
      error: error.message
    });
  }
});

// Chat system - In-memory storage
let chatRooms = [];
let chatMessages = [];

// Chat routes
app.get('/api/chat/rooms/:userId', (req, res) => {
  try {
    const userId = req.params.userId;
    const userRooms = chatRooms.filter(room =>
      room.participants.includes(userId)
    );

    res.json({
      success: true,
      count: userRooms.length,
      data: userRooms
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi lấy danh sách chat',
      error: error.message
    });
  }
});

app.get('/api/chat/messages/:roomId', (req, res) => {
  try {
    const roomId = req.params.roomId;
    const roomMessages = chatMessages.filter(msg =>
      msg.chatRoomId === roomId
    ).sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

    res.json({
      success: true,
      count: roomMessages.length,
      data: roomMessages
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi lấy tin nhắn',
      error: error.message
    });
  }
});

app.post('/api/chat/send', (req, res) => {
  try {
    const messageData = req.body;
    const newMessage = {
      _id: 'msg_' + Date.now(),
      ...messageData,
      timestamp: new Date().toISOString()
    };

    chatMessages.push(newMessage);

    // Update last message in chat room
    const roomIndex = chatRooms.findIndex(room => room._id === messageData.chatRoomId);
    if (roomIndex !== -1) {
      chatRooms[roomIndex].lastMessage = newMessage._id;
      chatRooms[roomIndex].updatedAt = new Date().toISOString();
    }

    res.status(201).json({
      success: true,
      data: newMessage,
      message: 'Gửi tin nhắn thành công'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi gửi tin nhắn',
      error: error.message
    });
  }
});

app.post('/api/chat/room', (req, res) => {
  try {
    const { participants, participantNames, participantRoles, tripId, tripRoute } = req.body;

    // Check if room already exists
    let existingRoom = chatRooms.find(room =>
      room.participants.length === participants.length &&
      participants.every(p => room.participants.includes(p))
    );

    if (existingRoom) {
      return res.json({
        success: true,
        data: existingRoom
      });
    }

    // Create new room
    const newRoom = {
      _id: 'room_' + Date.now(),
      name: tripRoute || `Chat ${participantNames?.join(' - ') || 'Conversation'}`,
      participants,
      participantNames: participantNames || [],
      participantRoles: participantRoles || [],
      tripId,
      tripRoute,
      lastMessage: null,
      unreadCount: 0,
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    chatRooms.push(newRoom);

    res.json({
      success: true,
      data: newRoom
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi tạo chat room',
      error: error.message
    });
  }
});

app.delete('/api/chat/messages/:messageId', (req, res) => {
  try {
    const messageId = req.params.messageId;
    const msgIndex = chatMessages.findIndex(msg => msg._id === messageId);
    if (msgIndex === -1) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy tin nhắn' });
    }
    chatMessages.splice(msgIndex, 1);
    res.json({ success: true, message: 'Thu hồi tin nhắn thành công' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi khi thu hồi tin nhắn', error: error.message });
  }
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

app.listen(PORT, () => {
  console.log(`🚀 Hà Phương Server running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔐 Login endpoint: http://localhost:${PORT}/api/auth/login`);
});