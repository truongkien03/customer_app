# 📱 User App API Documentation

## 🔗 Base URL
```
http://your-domain.com/api
```

## 🔐 Authentication
Sử dụng **Laravel Passport Bearer Token** trong header:
```
Authorization: Bearer {access_token}
```

---

## � **KHI NÀO SỬ DỤNG TỪNG API**

### **📱 Authentication Flow:**
1. **Người dùng mới**: `register/otp` → `register` → `set-password` (optional)
2. **Đăng nhập**: `login/otp` → `login` HOẶC `login/password` (direct)
3. **Quên mật khẩu**: `password/forgot` → `password/reset`

### **👤 Profile Management:**
- **Lần đầu vào app**: `GET /profile` để kiểm tra thông tin
- **Cập nhật thông tin**: `POST /profile` khi user thay đổi name/address
- **Đổi avatar**: `POST /profile/avatar` khi user chọn ảnh mới
- **Thiết lập/đổi mật khẩu**: `POST /set-password` (lần đầu) hoặc `POST /password` (đổi)

### **🚚 Order Flow:**
1. **Trước khi đặt**: `POST /shipping-fee` để tính giá
2. **Tạo đơn hàng**: `POST /orders` sau khi user confirm
3. **Theo dõi đơn hàng**: `GET /orders/inproccess` để xem đơn đang giao
4. **Lịch sử**: `GET /orders/completed` để xem đơn đã xong
5. **Chi tiết đơn**: `GET /orders/{orderId}` khi user tap vào đơn hàng
6. **Chọn tài xế**: `GET /orders/{orderId}/drivers/recommended` → `POST /orders/{orderId}/drivers`
7. **Sau khi giao xong**: `POST /orders/{orderId}/review` để đánh giá

## 🔔 **FCM v1 API Integration**

Hệ thống sử dụng **Firebase Cloud Messaging HTTP v1 API** với OAuth 2.0 authentication để gửi push notifications.

### **Đặc điểm chính:**
- ✅ **Bảo mật cao**: OAuth 2.0 Access Token thay vì Server Key cố định
- ✅ **Hiệu suất tốt**: HTTP/2 protocol với connection pooling
- ✅ **Error handling**: Chi tiết và chính xác với FCM error codes
- ✅ **Token validation**: Built-in validation trước khi gửi
- ✅ **Multi-platform**: Consistent behavior trên Android/iOS

### **🔔 Notification Management:**
- **Đăng ký FCM**: `POST /fcm/token` khi app khởi động
- **Xem thông báo**: `GET /notifications` trong notification tab
- **Xóa FCM**: `DELETE /fcm/token` khi logout
- **Auto validation**: Hệ thống tự động validate token trước khi lưu

---

## �📋 API Endpoints Overview

### 🔓 **PUBLIC ENDPOINTS** (Không cần authentication)
1. [POST /register/otp](#1-post-registerotp) - Gửi OTP đăng ký
2. [POST /register](#2-post-register) - Đăng ký tài khoản
3. [POST /login/otp](#3-post-loginotp) - Gửi OTP đăng nhập
4. [POST /login](#4-post-login) - Đăng nhập với OTP
5. [POST /login/password](#5-post-loginpassword) - Đăng nhập với mật khẩu
6. [POST /password/forgot](#6-post-passwordforgot) - Quên mật khẩu
7. [POST /password/reset](#7-post-passwordreset) - Đặt lại mật khẩu

### 🔒 **PROTECTED ENDPOINTS** (Cần authentication)

#### 👤 **Profile Management**
8. [GET /profile](#8-get-profile) - Lấy thông tin profile
9. [POST /profile](#9-post-profile) - Cập nhật profile
10. [POST /profile/avatar](#10-post-profileavatar) - Cập nhật avatar
11. [POST /password](#11-post-password) - Đổi mật khẩu
12. [POST /set-password](#12-post-set-password) - Thiết lập mật khẩu lần đầu

#### 🔔 **Notifications & FCM**
13. [GET /notifications](#13-get-notifications) - Lấy danh sách thông báo
14. [POST /fcm/token](#14-post-fcmtoken) - Đăng ký FCM token
15. [DELETE /fcm/token](#15-delete-fcmtoken) - Xóa FCM token

#### 🚚 **Order Management**
16. [POST /shipping-fee](#16-post-shipping-fee) - Tính phí vận chuyển
17. [POST /orders](#17-post-orders) - Tạo đơn hàng mới  
18. [GET /orders/inproccess](#18-get-ordersinproccess) - Đơn hàng đang xử lý
19. [GET /orders/completed](#19-get-orderscompleted) - Đơn hàng đã hoàn thành
20. [GET /orders/{orderId}](#20-get-ordersorderid) - Chi tiết đơn hàng
21. [GET /orders/{orderId}/drivers/recommended](#21-get-ordersorderiddrivers-recommended) - Tài xế được đề xuất
22. [POST /orders/{orderId}/drivers](#22-post-ordersorderiddrivers) - Chỉ định tài xế
23. [POST /orders/{orderId}/drivers/random](#23-post-ordersorderiddrivers-random) - Chọn tài xế ngẫu nhiên
24. [POST /orders/{orderId}/review](#24-post-ordersorderidreview) - Đánh giá tài xế
25. [GET /route](#25-get-route) - Lấy tuyến đường

---

## 📖 Detailed API Documentation

### 1. POST /register/otp
**Gửi mã OTP để đăng ký tài khoản mới**

#### Request
```http
POST /api/register/otp
Content-Type: application/json

{
    "phone_number": "+84987654321"
}
```

#### Response Success (204)
```http
HTTP/1.1 204 No Content
```

#### Response Error (422)
```json
{
    "error": true,
    "errorCode": {
        "phone_number": ["Số điện thoại đã được sử dụng"]
    }
}
```

---

### 2. POST /register
**Đăng ký tài khoản mới với OTP**

#### Request
```http
POST /api/register
Content-Type: application/json

{
    "phone_number": "+84987654321",
    "otp": "1234"
}
```

#### Response Success (200)
```json
{
    "data": {
        "token_type": "Bearer",
        "expires_at": "2025-07-06 07:00:00",
        "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
        "refresh_token": "def50200..."
    }
}
```

#### Response Error (422)
```json
{
    "error": true,
    "errorCode": {
        "otp": ["OTP đã hết hạn hoặc không đúng"]
    }
}
```

---

### 3. POST /login/otp
**Gửi mã OTP để đăng nhập**

#### Request
```http
POST /api/login/otp
Content-Type: application/json

{
    "phone_number": "+84987654321"
}
```

#### Response Success (204)
```http
HTTP/1.1 204 No Content
```

#### Response Error (422)
```json
{
    "error": true,
    "errorCode": {
        "phone_number": ["Số điện thoại không tồn tại"]
    }
}
```

---

### 4. POST /login
**Đăng nhập với OTP hoặc mật khẩu**

#### Request (với OTP)
```http
POST /api/login
Content-Type: application/json

{
    "phone_number": "+84987654321",
    "otp": "1234"
}
```

#### Request (với Password)
```http
POST /api/login
Content-Type: application/json

{
    "phone_number": "+84987654321",
    "password": "123456"
}
```

#### Response Success (200)
```json
{
    "data": {
        "token_type": "Bearer",
        "expires_at": "2025-07-06 07:00:00",
        "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
        "refresh_token": "def50200..."
    }
}
```

---

### 5. POST /login/password
**Đăng nhập bằng số điện thoại và mật khẩu**

#### Request
```http
POST /api/login/password
Content-Type: application/json

{
    "phone_number": "+84987654321",
    "password": "123456"
}
```

#### Response Success (200)
```json
{
    "data": {
        "token_type": "Bearer",
        "expires_at": "2025-07-06 07:00:00",
        "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
        "refresh_token": "def50200..."
    }
}
```

---

### 6. POST /password/forgot
**Gửi OTP để reset mật khẩu**

#### Request
```http
POST /api/password/forgot
Content-Type: application/json

{
    "phone_number": "+84987654321"
}
```

#### Response Success (204)
```http
HTTP/1.1 204 No Content
```

---

### 7. POST /password/reset
**Đặt lại mật khẩu với OTP**

#### Request
```http
POST /api/password/reset
Content-Type: application/json

{
    "phone_number": "+84987654321",
    "otp": "1234",
    "password": "new_password123",
    "password_confirmation": "new_password123"
}
```

#### Response Success (200)
```json
{
    "data": {
        "token_type": "Bearer",
        "expires_at": "2025-07-06 07:00:00",
        "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
        "refresh_token": "def50200..."
    }
}
```

---

### 8. GET /profile
**Lấy thông tin profile người dùng**

#### Request
```http
GET /api/profile
Authorization: Bearer {access_token}
```

#### Response Success (200)
```json
{
    "id": 1,
    "name": "Nguyễn Văn A",
    "email": "user@example.com",
    "phone_number": "+84987654321",
    "address": {
        "street": "123 Đường ABC",
        "city": "Hồ Chí Minh",
        "district": "Quận 1"
    },
    "avatar": "https://domain.com/storage/avatars/avatar.jpg",
    "fcm_token": ["token1", "token2"],
    "hasCredential": true,
    "created_at": "2025-01-01T00:00:00.000000Z",
    "updated_at": "2025-01-02T00:00:00.000000Z"
}
```

---

### 9. POST /profile
**Cập nhật thông tin profile**

**🔸 Khi nào sử dụng:** User muốn cập nhật tên hoặc địa chỉ mặc định

#### Request
```http
POST /api/profile
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "name": "Nguyễn Văn B",
    "address": {
        "lat": 10.7769,
        "lon": 106.7009,
        "desc": "456 Đường XYZ, Quận Ba Đình, Hà Nội"
    }
}
```

#### Response Success (200)
```json
{
    "data": {
        "id": 1,
        "name": "Nguyễn Văn B",
        "email": "user@example.com",
        "phone_number": "+84987654321",
        "address": {
            "lat": 10.7769,
            "lon": 106.7009,
            "desc": "456 Đường XYZ, Quận Ba Đình, Hà Nội"
        },
        "avatar": "https://domain.com/storage/avatars/avatar.jpg",
        "hasCredential": true,
        "created_at": "2025-01-01T00:00:00.000000Z",
        "updated_at": "2025-01-02T00:00:00.000000Z"
    }
}
```

---

### 10. POST /profile/avatar
**Cập nhật avatar người dùng**

#### Request
```http
POST /api/profile/avatar
Authorization: Bearer {access_token}
Content-Type: multipart/form-data

avatar: (file) - Image file (jpg, png, gif, max 2MB)
```

#### Response Success (200)
```json
{
    "avatar": "https://domain.com/storage/avatars/uuid.jpg"
}
```

---

### 11. POST /password
**Đổi mật khẩu**

#### Request
```http
POST /api/password
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "password": "new_password123",
    "password_confirmation": "new_password123"
}
```

#### Response Success (204)
```http
HTTP/1.1 204 No Content
```

---

### 12. POST /set-password
**Thiết lập mật khẩu lần đầu (cho user chưa có password)**

#### Request
```http
POST /api/set-password
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "password": "new_password123",
    "password_confirmation": "new_password123"
}
```

#### Response Success (200)
```json
{
    "message": "Password set successfully"
}
```

#### Response Error (400)
```json
{
    "error": true,
    "message": "User already has a password. Use change password API instead."
}
```

---

### 13. GET /notifications
**Lấy danh sách thông báo**

#### Request
```http
GET /api/notifications
Authorization: Bearer {access_token}
```

#### Response Success (200)
```json
{
    "data": [
        {
            "id": "uuid-1",
            "type": "App\\Notifications\\DriverAcceptedOrder",
            "notifiable_type": "App\\Models\\User",
            "notifiable_id": 1,
            "data": {
                "key": "AcceptOder",
                "link": "customer://Notification",
                "oderId": "123"
            },
            "read_at": null,
            "created_at": "2025-01-01T00:00:00.000000Z",
            "updated_at": "2025-01-01T00:00:00.000000Z"
        }
    ]
}
```

---

### 14. POST /fcm/token
**Đăng ký FCM token cho push notification (FCM v1 API)**

**🔸 Khi nào sử dụng:** Khi app khởi động, sau khi user đăng nhập thành công, hoặc khi FCM token được refresh.

#### Request
```http
POST /api/fcm/token
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "fcm_token": "fcm_registration_token_string_here"
}
```

**📝 Lưu ý FCM v1:**
- Token có thể được refresh bởi Firebase SDK
- Hệ thống tự động validate token trước khi lưu
- Hỗ trợ multiple tokens cho một user (multi-device)

#### Response Success (204)
```http
HTTP/1.1 204 No Content
```

#### Response Error (422)
```json
{
    "error": true,
    "message": {
        "fcm_token": ["FCM token không hợp lệ"]
    }
}
```

---

### 15. DELETE /fcm/token
**Xóa FCM token (FCM v1 API)**

**🔸 Khi nào sử dụng:** Khi user logout, khi token expire, hoặc khi app được uninstall.

#### Request
```http
DELETE /api/fcm/token
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "fcm_token": "fcm_registration_token_to_remove"
}
```

**📝 Lưu ý:** Token sẽ được xóa khỏi danh sách FCM tokens của user trong database.

#### Response Success (204)
```http
HTTP/1.1 204 No Content
```

#### Response Error (422)
```json
{
    "error": true,
    "message": {
        "fcm_token": ["Token không tồn tại"]
    }
}
```

---

### 16. POST /shipping-fee
**Tính phí vận chuyển**

**🔸 Khi nào sử dụng:** Trước khi tạo đơn hàng, khi user nhập địa chỉ gửi và nhận để hiển thị chi phí ước tính.

**🔸 Khi nào sử dụng:** Trước khi user tạo đơn hàng, để hiển thị chi phí và thời gian dự kiến

#### Request
```http
POST /api/shipping-fee
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "from_address": {
        "lat": 10.7769,
        "lon": 106.7009,
        "desc": "Số 1 Nguyễn Huệ, Quận 1, TP.HCM"
    },
    "to_address": {
        "lat": 10.7829,
        "lon": 106.6934,
        "desc": "Số 100 Lê Lai, Quận 1, TP.HCM"
    }
}
```

#### Response Success (200)
```json
{
    "data": {
        "distance": 1.25,
        "shipping_fee": 16250,
        "estimated_time": "10-15 phút",
        "from_address": {
            "lat": 10.7769,
            "lon": 106.7009,
            "desc": "Số 1 Nguyễn Huệ, Quận 1, TP.HCM"
        },
        "to_address": {
            "lat": 10.7829,
            "lon": 106.6934,
            "desc": "Số 100 Lê Lai, Quận 1, TP.HCM"
        },
        "calculated_at": "2025-07-05T10:30:00.000000Z"
    }
}
```

#### Response Error (422)
```json
{
    "error": true,
    "message": {
        "distance": [
            "Hệ thống tạm thời không hỗ trợ đơn hàng xa hơn 100km"
        ]
    }
}
```

---

### 17. POST /orders
**Tạo đơn hàng mới**

**🔸 Khi nào sử dụng:** Sau khi user đã tính phí shipping bằng `/shipping-fee`, xác nhận thông tin đơn hàng và tap nút "Đặt hàng".

**🔸 Khi nào sử dụng:** Sau khi user đã tính phí và confirm tạo đơn hàng

#### Request
```http
POST /api/orders
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "from_address": {
        "lat": 10.7769,
        "lon": 106.7009,
        "desc": "Số 1 Nguyễn Huệ, Quận 1, TP.HCM"
    },
    "to_address": {
        "lat": 10.7829,
        "lon": 106.6934,
        "desc": "Số 100 Lê Lai, Quận 1, TP.HCM"
    },
    "items": [
        {
            "name": "Túi quần áo",
            "quantity": 1,
            "price": 50000,
            "note": "Hàng dễ vỡ"
        }
    ],
    "receiver": {
        "name": "Nguyễn Văn B",
        "phone": "+84912345678",
        "note": "Gọi trước khi đến"
    },
    "user_note": "Gọi trước khi đến",
    "discount": 0
}
```

**📝 Lưu ý:** API sẽ tự động tính `shipping_cost` và `distance` dựa trên `from_address` và `to_address`

#### Response Success (200)
```json
{
    "data": {
        "id": 123,
        "user_id": 1,
        "driver_id": null,
        "from_address": {
            "lat": 10.7769,
            "lon": 106.7009,
            "desc": "Số 1 Nguyễn Huệ, Quận 1, TP.HCM"
        },
        "to_address": {
            "lat": 10.7829,
            "lon": 106.6934,
            "desc": "Số 100 Lê Lai, Quận 1, TP.HCM"
        },
        "items": [
            {
                "name": "Túi quần áo",
                "quantity": 1,
                "price": 50000,
                "note": "Hàng dễ vỡ"
            }
        ],
        "shipping_cost": 16250,
        "distance": 1.25,
        "discount": 0,
        "status_code": 1,
        "completed_at": null,
        "driver_accept_at": null,
        "user_note": "Gọi trước khi đến",
        "driver_note": null,
        "driver_rate": null,
        "receiver": {
            "name": "Nguyễn Văn B",
            "phone": "+84912345678",
            "note": "Gọi trước khi đến"
        },
        "is_sharable": 0,
        "except_drivers": [],
        "created_at": "2025-07-05T10:30:00.000000Z",
        "updated_at": "2025-07-05T10:30:00.000000Z",
        "customerAvatar": "https://domain.com/storage/avatars/avatar.jpg",
        "customerName": "Nguyễn Văn A"
    }
}
```

---

### 18. GET /orders/inproccess
**Lấy danh sách đơn hàng đang xử lý**

**🔸 Khi nào sử dụng:** Trong tab "Đang giao" của app để hiển thị các đơn hàng có status_code = 2 (inprocess).

**🔸 Khi nào sử dụng:** Trong tab "Đơn hàng hiện tại" hoặc màn hình theo dõi đơn hàng

#### Request
```http
GET /api/orders/inproccess?page=1
Authorization: Bearer {access_token}
```

#### Response Success (200)
```json
{
    "current_page": 1,
    "data": [
        {
            "id": 123,
            "user_id": 1,
            "driver_id": 5,
            "from_address": {
                "lat": 10.7769,
                "lon": 106.7009,
                "desc": "Số 1 Nguyễn Huệ, Quận 1, TP.HCM"
            },
            "to_address": {
                "lat": 10.7829,
                "lon": 106.6934,
                "desc": "Số 100 Lê Lai, Quận 1, TP.HCM"
            },
            "shipping_cost": 16250,
            "distance": 1.25,
            "status_code": 2,
            "driver_accept_at": "2025-07-05T10:35:00.000000Z",
            "created_at": "2025-07-05T10:30:00.000000Z",
            "driver": {
                "id": 5,
                "name": "Nguyễn Văn Tài Xế",
                "phone_number": "+84901234567",
                "avatar": "https://domain.com/storage/avatars/driver.jpg",
                "review_rate": 4.8,
                "current_location": {
                    "lat": 10.7770,
                    "lon": 106.7010
                }
            }
        }
    ],
    "first_page_url": "http://domain.com/api/orders/inproccess?page=1",
    "from": 1,
    "last_page": 1,
    "last_page_url": "http://domain.com/api/orders/inproccess?page=1",
    "links": [...],
    "next_page_url": null,
    "path": "http://domain.com/api/orders/inproccess",
    "per_page": 15,
    "prev_page_url": null,
    "to": 1,
    "total": 1
}
```

---

### 19. GET /orders/completed
**Lấy danh sách đơn hàng đã hoàn thành**

**🔸 Khi nào sử dụng:** Trong tab "Lịch sử" của app để hiển thị các đơn hàng có status_code = 3 (completed).

**🔸 Khi nào sử dụng:** Trong tab "Lịch sử" để xem các đơn hàng đã hoàn thành

#### Request
```http
GET /api/orders/completed?page=1
Authorization: Bearer {access_token}
```

#### Response Success (200)
```json
{
    "current_page": 1,
    "data": [
        {
            "id": 122,
            "user_id": 1,
            "driver_id": 5,
            "from_address": {
                "lat": 10.7769,
                "lon": 106.7009,
                "desc": "Số 1 Nguyễn Huệ, Quận 1, TP.HCM"
            },
            "to_address": {
                "lat": 10.7829,
                "lon": 106.6934,
                "desc": "Số 100 Lê Lai, Quận 1, TP.HCM"
            },
            "shipping_cost": 16250,
            "distance": 1.25,
            "status_code": 3,
            "completed_at": "2025-07-05T11:00:00.000000Z",
            "driver_accept_at": "2025-07-05T10:35:00.000000Z",
            "driver_rate": 5,
            "created_at": "2025-07-05T10:30:00.000000Z",
            "driver": {
                "id": 5,
                "name": "Nguyễn Văn Tài Xế",
                "phone_number": "+84901234567",
                "avatar": "https://domain.com/storage/avatars/driver.jpg",
                "review_rate": 4.8
            }
        }
    ],
    "first_page_url": "http://domain.com/api/orders/completed?page=1",
    "from": 1,
    "last_page": 1,
    "per_page": 15,
    "to": 1,
    "total": 1
}
```

---

### 20. GET /orders/{orderId}
**Chi tiết đơn hàng**

**🔸 Khi nào sử dụng:** Khi user tap vào một đơn hàng cụ thể để xem chi tiết đầy đủ.

**🔸 Khi nào sử dụng:** Khi user tap vào một đơn hàng để xem chi tiết đầy đủ

#### Request
```http
GET /api/orders/123
Authorization: Bearer {access_token}
```

#### Response Success (200)
```json
{
    "id": 123,
    "user_id": 1,
    "driver_id": 5,
    "from_address": {
        "lat": 10.7769,
        "lon": 106.7009,
        "desc": "Số 1 Nguyễn Huệ, Quận 1, TP.HCM"
    },
    "to_address": {
        "lat": 10.7829,
        "lon": 106.6934,
        "desc": "Số 100 Lê Lai, Quận 1, TP.HCM"
    },
    "items": [
        {
            "name": "Túi quần áo",
            "quantity": 1,
            "price": 50000,
            "note": "Hàng dễ vỡ"
        }
    ],
    "shipping_cost": 16250,
    "distance": 1.25,
    "discount": 0,
    "status_code": 2,
    "completed_at": null,
    "driver_accept_at": "2025-07-05T10:35:00.000000Z",
    "user_note": "Gọi trước khi đến",
    "driver_note": null,
    "driver_rate": null,
    "receiver": {
        "name": "Nguyễn Văn B",
        "phone": "+84912345678",
        "note": "Gọi trước khi đến"
    },
    "is_sharable": 0,
    "except_drivers": [],
    "created_at": "2025-07-05T10:30:00.000000Z",
    "updated_at": "2025-07-05T10:35:00.000000Z",
    "customerAvatar": "https://domain.com/storage/avatars/avatar.jpg",
    "customerName": "Nguyễn Văn A",
    "driver": {
        "id": 5,
        "name": "Nguyễn Văn Tài Xế",
        "phone_number": "+84901234567",
        "email": "driver@example.com",
        "avatar": "https://domain.com/storage/avatars/driver.jpg",
        "review_rate": 4.8,
        "current_location": {
            "lat": 10.7770,
            "lon": 106.7010
        },
        "status": 3
    }
}
```

---

### 23. GET /orders/{orderId}/drivers/recommended
**Lấy danh sách tài xế được đề xuất**

**🔸 Khi nào sử dụng:** Khi đơn hàng chưa có tài xế và user muốn chọn tài xế cụ thể

#### Request
```http
GET /api/orders/123/drivers/recommended?page=1
Authorization: Bearer {access_token}
```

#### Response Success (200)
```json
{
    "current_page": 1,
    "data": [
        {
            "id": 5,
            "name": "Nguyễn Văn Tài Xế",
            "phone_number": "+84901234567",
            "email": "driver@example.com",
            "avatar": "https://domain.com/storage/avatars/driver.jpg",
            "review_rate": 4.8,
            "current_location": {
                "lat": 10.7770,
                "lon": 106.7010
            },
            "status": 1,
            "distance": 0.12
        },
        {
            "id": 6,
            "name": "Trần Văn Driver",
            "phone_number": "+84902345678",
            "avatar": "https://domain.com/storage/avatars/driver2.jpg",
            "review_rate": 4.5,
            "current_location": {
                "lat": 10.7800,
                "lon": 106.7020
            },
            "status": 1,
            "distance": 0.35
        }
    ],
    "per_page": 15,
    "total": 2
}
```

---

### 24. POST /orders/{orderId}/drivers
**Chỉ định tài xế cho đơn hàng**

**🔸 Khi nào sử dụng:** Sau khi user chọn tài xế từ danh sách recommended drivers

#### Request
```http
POST /api/orders/123/drivers
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "driver_id": 5
}
```

#### Response Success (200)
```json
{
    "data": {
        "id": 123,
        "user_id": 1,
        "driver_id": 5,
        "status_code": 1,
        "updated_at": "2025-07-05T10:40:00.000000Z"
    }
}
```

#### Response Error (422)
```json
{
    "error": true,
    "message": {
        "driver_id": ["Tài xế hiện đang không sẵn sàng"]
    }
}
```

---

### 25. POST /orders/{orderId}/drivers/random
**Chọn tài xế ngẫu nhiên**

**🔸 Khi nào sử dụng:** Khi user không muốn chọn tài xế cụ thể và để hệ thống tự động tìm

#### Request
```http
POST /api/orders/123/drivers/random
Authorization: Bearer {access_token}
```

#### Response Success (200)
```json
{
    "data": {
        "id": 123,
        "user_id": 1,
        "driver_id": 7,
        "status_code": 1,
        "updated_at": "2025-07-05T10:45:00.000000Z"
    }
}
```

#### Response Error (422)
```json
{
    "error": true,
    "message": [
        "Không có tài xế nào sẵn sàng trong khu vực"
    ]
}
```

---

### 26. POST /orders/{orderId}/review
**Đánh giá tài xế sau khi hoàn thành đơn hàng**

**🔸 Khi nào sử dụng:** Sau khi đơn hàng hoàn thành (status_code = 3), user có thể đánh giá tài xế

#### Request
```http
POST /api/orders/123/review
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "driver_rate": 5
}
```

**📝 Lưu ý:** `driver_rate` từ 1-5 sao, `driver_note` là optional

#### Response Success (200)
```json
{
    "data": {
        "id": 123,
        "driver_rate": 5,
        "updated_at": "2025-07-05T11:05:00.000000Z"
    }
}
```

#### Response Error (422)
```json
{
    "error": true,
    "message": [
        "Không thể đánh giá đơn hàng này"
    ]
}
```

---

## 📊 Order Status Codes

| Code | Status | Mô tả |
|------|--------|-------|
| 1 | pending | Chờ tài xế chấp nhận |
| 2 | inprocess | Đang giao hàng |
| 3 | completed | Đã hoàn thành |
| 4 | cancelled_by_user | Người dùng hủy |
| 5 | cancelled_by_driver | Tài xế hủy |
| 6 | cancelled_by_system | Hệ thống hủy |

## 📊 Driver Status Codes

| Code | Status | Mô tả |
|------|--------|-------|
| 1 | free | Sẵn sàng nhận đơn |
| 2 | offline | Offline |
| 3 | busy | Đang giao hàng |

## 💰 Shipping Fee Calculation

### Công thức tính phí:
- **Km đầu tiên**: 10,000 VND
- **Từ km thứ 2**: 5,000 VND/km
- **Giờ cao điểm** (11h-13h, 17h-19h): +20%

### Ví dụ:
- Quãng đường: 2.5km
- Phí cơ bản: 10,000 + (1.5 × 5,000) = 17,500 VND
- Nếu giờ cao điểm: 17,500 × 1.2 = 21,000 VND

## 🔔 Push Notification Types (FCM v1 API)

### **Cấu trúc Notification mới:**
```json
{
    "message": {
        "token": "user_fcm_token",
        "notification": {
            "title": "Tiêu đề thông báo",
            "body": "Nội dung thông báo"
        },
        "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "app_type": "user",
            "order_id": "123",
            "action_type": "order_accepted"
        },
        "android": {
            "notification": {
                "channel_id": "user_notifications",
                "priority": "high",
                "sound": "default"
            }
        },
        "apns": {
            "payload": {
                "aps": {
                    "alert": {
                        "title": "Tiêu đề",
                        "body": "Nội dung"
                    },
                    "sound": "default",
                    "badge": 1
                }
            }
        }
    }
}
```

### **User sẽ nhận các loại notification:**
1. **DriverAcceptedOrder**: Tài xế đã chấp nhận đơn hàng
   - `data.action_type`: "driver_accepted"
   - `data.order_id`: ID đơn hàng
   
2. **DriverDeclinedOrder**: Tài xế từ chối đơn hàng
   - `data.action_type`: "driver_declined"
   - `data.order_id`: ID đơn hàng
   
3. **OrderHasBeenComplete**: Đơn hàng đã hoàn thành
   - `data.action_type`: "order_completed"
   - `data.order_id`: ID đơn hàng
   
4. **NoAvailableDriver**: Không có tài xế trong khu vực
   - `data.action_type`: "no_driver_available"
   - `data.order_id`: ID đơn hàng

### **Xử lý Notification trong Flutter:**
```dart
// FCM v1 API setup
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Xử lý notification khi app đang active
    final data = message.data;
    final actionType = data['action_type'];
    final orderId = data['order_id'];
    
    switch (actionType) {
        case 'driver_accepted':
            showDriverAcceptedDialog(orderId);
            break;
        case 'driver_declined':
            showDriverDeclinedDialog(orderId);
            break;
        case 'order_completed':
            showOrderCompletedDialog(orderId);
            break;
        case 'no_driver_available':
            showNoDriverDialog(orderId);
            break;
    }
});

// Khi user tap vào notification
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final orderId = message.data['order_id'];
    if (orderId != null) {
        navigateToOrderDetail(orderId);
    }
});
```

## ❌ Common Error Codes

### HTTP Status Codes:
- **200**: Success
- **204**: Success (No Content)
- **401**: Unauthorized (Invalid token)
- **403**: Forbidden (Profile not verified)
- **422**: Validation Error
- **500**: Server Error

### Validation Error Format:
```json
{
    "error": true,
    "errorCode": {
        "field_name": ["Error message"]
    }
}
```

## 🔧 **FCM v1 API Configuration**

### **Backend Setup:**
```php
// config/firebase.php
'fcm' => [
    'v1_url' => 'https://fcm.googleapis.com/v1/projects/{project_id}/messages:send',
    'timeout' => env('FIREBASE_FCM_TIMEOUT', 30),
    'scopes' => ['https://www.googleapis.com/auth/firebase.messaging'],
],

// .env configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CREDENTIALS=storage/firebase-service-account.json
FIREBASE_FCM_TIMEOUT=30
```

### **Service Account Setup:**
1. Tạo Service Account trong Firebase Console
2. Cấp quyền "Firebase Cloud Messaging API Editor"
3. Download JSON credentials file
4. Đặt file vào `storage/firebase-service-account.json`
5. Verify permissions trong IAM console

### **Architecture:**
```
User App ─┐
          ├─> Laravel API ─> FcmV1Service ─> FCM v1 API ─> Firebase
Driver App─┘
```

### **Error Codes FCM v1:**
- **INVALID_ARGUMENT**: Token hoặc payload không hợp lệ
- **UNREGISTERED**: Token đã expire hoặc app bị uninstall
- **SENDER_ID_MISMATCH**: Token không thuộc về project
- **QUOTA_EXCEEDED**: Vượt quá giới hạn rate limit
- **UNAVAILABLE**: Service tạm thời không khả dụng
- **INTERNAL**: Lỗi internal server của FCM

---

## 🚀 Flutter Implementation Examples

### Dio HTTP Client Setup:
```dart
import 'package:dio/dio.dart';

class ApiClient {
    static const String baseUrl = 'http://your-domain.com/api';
    late Dio dio;
    
    ApiClient() {
        dio = Dio(BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
        ));
        
        // Add token interceptor
        dio.interceptors.add(InterceptorsWrapper(
            onRequest: (options, handler) {
                String? token = getStoredToken();
                if (token != null) {
                    options.headers['Authorization'] = 'Bearer $token';
                }
                handler.next(options);
            },
        ));
    }
}
```

### API Call Examples:
```dart
// Đăng ký FCM Token (FCM v1)
Future<void> registerFcmToken(String token) async {
    try {
        await dio.post('/fcm/token', data: {
            'fcm_token': token,
        });
    } on DioException catch (e) {
        throw ApiException(e.response?.data);
    }
}

// Xóa FCM Token
Future<void> removeFcmToken(String token) async {
    try {
        await dio.delete('/fcm/token', data: {
            'fcm_token': token,
        });
    } on DioException catch (e) {
        throw ApiException(e.response?.data);
    }
}

// Tính phí vận chuyển
Future<ShippingFeeResponse> calculateShippingFee({
    required Map<String, dynamic> fromAddress,
    required Map<String, dynamic> toAddress,
}) async {
    try {
        final response = await dio.post('/shipping-fee', data: {
            'from_address': fromAddress,
            'to_address': toAddress,
        });
        return ShippingFeeResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
        throw ApiException(e.response?.data);
    }
}

// Tạo đơn hàng
Future<Order> createOrder(CreateOrderRequest request) async {
    try {
        final response = await dio.post('/orders', data: request.toJson());
        return Order.fromJson(response.data['data']);
    } on DioException catch (e) {
        throw ApiException(e.response?.data);
    }
}

// Lấy đơn hàng đang xử lý
Future<PaginatedResponse<Order>> getInProcessOrders({int page = 1}) async {
    try {
        final response = await dio.get('/orders/inproccess?page=$page');
        return PaginatedResponse<Order>.fromJson(
            response.data,
            (json) => Order.fromJson(json),
        );
    } on DioException catch (e) {
        throw ApiException(e.response?.data);
    }
}

// Đánh giá tài xế
Future<void> reviewDriver(int orderId, int rating) async {
    try {
        await dio.post('/orders/$orderId/review', data: {
            'driver_rate': rating,
        });
    } on DioException catch (e) {
        throw ApiException(e.response?.data);
    }
}
```

### Suggested App Flow:
```dart
// 1. Authentication Flow
class AuthService {
    Future<void> sendOTP(String phoneNumber) async {
        await dio.post('/register/otp', data: {'phone_number': phoneNumber});
    }
    
    Future<AuthToken> register(String phoneNumber, String otp) async {
        final response = await dio.post('/register', data: {
            'phone_number': phoneNumber,
            'otp': otp,
        });
        return AuthToken.fromJson(response.data['data']);
    }
}

// 2. Order Flow
class OrderService {
    // Tính phí → Tạo đơn → Theo dõi → Đánh giá
    Future<void> completeOrderFlow() async {
        // Step 1: Calculate fee
        final fee = await calculateShippingFee(...);
        
        // Step 2: Create order
        final order = await createOrder(...);
        
        // Step 3: Track order
        final inProcessOrders = await getInProcessOrders();
        
        // Step 4: Review driver (after completion)
        await reviewDriver(order.id, 5);
    }
}
```

## 🔄 **Real-time Updates**

### FCM Push Notifications:
User sẽ nhận push notifications cho:
- **Tài xế chấp nhận**: Khi driver accept đơn hàng
- **Tài xế từ chối**: Khi driver decline đơn hàng  
- **Đơn hàng hoàn thành**: Khi driver hoàn thành giao hàng
- **Không có tài xế**: Khi không tìm thấy driver

### Polling Strategy:
```dart
// Polling cho order status updates
Timer.periodic(Duration(seconds: 10), (timer) async {
    if (hasActiveOrder) {
        final order = await getOrderDetail(currentOrderId);
        updateOrderStatus(order.statusCode);
        
        if (order.statusCode == 3) { // Completed
            timer.cancel();
            showReviewDialog(order);
        }
    }
});
```

---

**📝 Note**: 
- Hệ thống sử dụng **FCM v1 API** với OAuth 2.0 authentication
- Đảm bảo handle các error cases và implement retry logic cho network requests
- Sử dụng secure storage để lưu access token
- FCM tokens được auto-refresh bởi Firebase SDK, app cần listen `onTokenRefresh`
- Test notification delivery trên cả Android và iOS với different app states
- Implement proper notification channels cho Android
- Handle notification permissions properly cho iOS 14+

## FCM v1 Implementation trong Flutter:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmV1Service {
    static FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    static FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
    static String? _currentToken;
    
    // Khởi tạo FCM v1
    static Future<void> initializeFCM() async {
        // Setup local notifications
        await _setupLocalNotifications();
        
        // Request permission (iOS)
        NotificationSettings settings = await _firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
        );
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            // Lấy FCM token
            String? token = await _firebaseMessaging.getToken();
            if (token != null) {
                _currentToken = token;
                await registerFcmToken(token);
                print('FCM Token: $token');
            }
            
            // Listen for token refresh (FCM v1 auto-refresh)
            _firebaseMessaging.onTokenRefresh.listen((String newToken) {
                _currentToken = newToken;
                registerFcmToken(newToken);
                print('FCM Token refreshed: $newToken');
            });
            
            // Setup notification handlers
            setupNotificationHandlers();
        } else {
            print('FCM permission denied');
        }
    }
    
    // Setup local notifications
    static Future<void> _setupLocalNotifications() async {
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
        );
        
        const initSettings = InitializationSettings(
            android: androidSettings,
            iOS: iosSettings,
        );
        
        await _localNotifications.initialize(
            initSettings,
            onDidReceiveNotificationResponse: _onNotificationTap,
        );
    }
    
    // Đăng ký token với server (FCM v1)
    static Future<void> registerFcmToken(String token) async {
        try {
            await ApiClient().dio.post('/fcm/token', data: {
                'fcm_token': token
            });
            print('FCM token registered successfully');
        } catch (e) {
            print('Failed to register FCM token: $e');
            // Retry logic
            Future.delayed(Duration(seconds: 30), () {
                registerFcmToken(token);
            });
        }
    }
    
    // Xóa token khi logout
    static Future<void> removeFcmToken() async {
        try {
            if (_currentToken != null) {
                await ApiClient().dio.delete('/fcm/token', data: {
                    'fcm_token': _currentToken
                });
                _currentToken = null;
            }
        } catch (e) {
            print('Failed to remove FCM token: $e');
        }
    }
    
    // Setup notification handlers cho FCM v1
    static void setupNotificationHandlers() {
        // Foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            print('Received foreground message: ${message.messageId}');
            _showLocalNotification(message);
            _handleNotificationData(message);
        });
        
        // Background/terminated app opened via notification
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            print('App opened via notification: ${message.messageId}');
            _handleNotificationTap(message.data);
        });
        
        // App opened from terminated state
        FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
            if (message != null) {
                print('App launched via notification: ${message.messageId}');
                _handleNotificationTap(message.data);
            }
        });
    }
    
    // Show local notification when app is in foreground
    static Future<void> _showLocalNotification(RemoteMessage message) async {
        const androidDetails = AndroidNotificationDetails(
            'user_notifications',
            'User Notifications',
            channelDescription: 'Thông báo cho app người dùng',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
        );
        
        const iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
        );
        
        const details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
        );
        
        await _localNotifications.show(
            message.hashCode,
            message.notification?.title ?? 'Thông báo',
            message.notification?.body ?? '',
            details,
            payload: jsonEncode(message.data),
        );
    }
    
    // Xử lý notification data
    static void _handleNotificationData(RemoteMessage message) {
        final data = message.data;
        final actionType = data['action_type'];
        final orderId = data['order_id'];
        
        switch (actionType) {
            case 'driver_accepted':
                OrderController.instance.refreshOrderStatus(orderId);
                break;
            case 'driver_declined':
                OrderController.instance.showDriverDeclinedDialog(orderId);
                break;
            case 'order_completed':
                OrderController.instance.showOrderCompletedDialog(orderId);
                break;
            case 'no_driver_available':
                OrderController.instance.showNoDriverDialog(orderId);
                break;
        }
    }
    
    // Handle notification tap
    static void _handleNotificationTap(Map<String, dynamic> data) {
        final orderId = data['order_id'];
        if (orderId != null) {
            Get.toNamed('/order-detail', arguments: orderId);
        }
    }
    
    static void _onNotificationTap(NotificationResponse response) {
        if (response.payload != null) {
            final data = jsonDecode(response.payload!);
            _handleNotificationTap(data);
        }
    }
}

// Order Controller integration
class OrderController extends GetxController {
    static OrderController get instance => Get.find<OrderController>();
    
    void refreshOrderStatus(String orderId) async {
        try {
            final order = await OrderService.getOrderDetail(orderId);
            // Update UI
            update();
        } catch (e) {
            print('Error refreshing order: $e');
        }
    }
    
    void showDriverDeclinedDialog(String orderId) {
        Get.dialog(
            AlertDialog(
                title: Text('Tài xế từ chối'),
                content: Text('Đang tìm tài xế khác cho đơn hàng của bạn...'),
                actions: [
                    TextButton(
                        onPressed: () => Get.back(),
                        child: Text('OK'),
                    ),
                ],
            ),
        );
    }
    
    void showOrderCompletedDialog(String orderId) {
        Get.dialog(
            AlertDialog(
                title: Text('Đơn hàng hoàn thành'),
                content: Text('Đơn hàng của bạn đã được giao thành công!'),
                actions: [
                    TextButton(
                        onPressed: () {
                            Get.back();
                            Get.toNamed('/review', arguments: orderId);
                        },
                        child: Text('Đánh giá'),
                    ),
                    TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Để sau'),
                    ),
                ],
            ),
        );
    }
    
    void showNoDriverDialog(String orderId) {
        Get.dialog(
            AlertDialog(
                title: Text('Không có tài xế'),
                content: Text('Hiện tại không có tài xế trong khu vực. Bạn có muốn thử lại không?'),
                actions: [
                    TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Hủy'),
                    ),
                    TextButton(
                        onPressed: () {
                            Get.back();
                            OrderService.findRandomDriver(orderId);
                        },
                        child: Text('Thử lại'),
                    ),
                ],
            ),
        );
    }
}
```

### Dependencies cho pubspec.yaml:
```yaml
dependencies:
  firebase_messaging: ^14.6.9
  flutter_local_notifications: ^15.1.1
  get: ^4.6.6
  dio: ^5.3.2

dev_dependencies:
  flutter_lints: ^2.0.0
```
