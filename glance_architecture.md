BƯỚC 1: CẤP QUYỀN PACKAGE VISIBILITY TRONG ANDROID MANIFEST

Target: android/app/src/main/AndroidManifest.xml

Vấn đề: Từ Android 11, canLaunchUrl sẽ return false nếu không có thẻ <queries>.

Action: Mở file Manifest, thêm khối lệnh <queries> sau đây vào ngay phía trên thẻ <application> (cùng cấp với các thẻ <uses-permission>):

XML
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" />
    </intent>
    <intent>
        <action android:name="android.intent.action.SENDTO" />
        <data android:scheme="mailto" />
    </intent>
</queries>

**BƯỚC 2: TỐI ƯU HÀM LAUNCH URL TRONG DART**
* **Target:** `lib/features/dashboard/widgets/about_app_sheet.dart`
* **Action:** Sửa lại logic `onTap` của Website, GitHub và Email. 
  - Đừng phụ thuộc vào `if (await canLaunchUrl(url))`. 
  - Hãy gọi trực tiếp `await launchUrl(url, mode: LaunchMode.externalApplication);` bọc trong `try-catch`. Nếu là `mailto` thì không cần tham số `mode`.

**BƯỚC 3: THÊM TÍNH NĂNG ZOOM MÃ QR (DIALOG POPUP)**
* **Target:** `lib/features/dashboard/widgets/about_app_sheet.dart`
* **Action:** 
  1. Tìm các widget `Image.asset(...)` hiển thị QR Code của MBBank và ZaloPay.
  2. Bọc mỗi ảnh QR bằng một `GestureDetector` hoặc `InkWell`.
  3. Viết một hàm private `_showZoomedQR(BuildContext context, String imagePath, String title, String subtitle)`. Hàm này sẽ gọi `showDialog` với giao diện:
     - Dùng `Dialog` có `backgroundColor: Colors.transparent` và `insetPadding: EdgeInsets.all(16)`.
     - Bên trong là một `Container` bo góc, nền màu Dark Charcoal viền Gold nhạt (Glassmorphism style).
     - Bố cục từ trên xuống: 
       + Nút đóng (X) góc trên bên phải.
       + Hình ảnh QR Code (kích thước lớn, bo góc).
       + Khoảng trống nhỏ (SizedBox).
       + Text Title (VD: "MBBank" hoặc "ZaloPay") - màu Gold, in đậm.
       + Text Subtitle (VD: "078604112004 - VO CHI CUONG") - màu Trắng.
       + Nút Copy (Sao chép) ngay bên dưới để người dùng có thể copy luôn từ popup.
  4. Gắn hàm `_showZoomedQR` vào sự kiện `onTap` của 2 mã QR với các tham số tương ứng.

Hãy phân tích cẩn thận, đặc biệt là vị trí chèn `<queries>` trong file XML phải chuẩn xác. Trả về báo cáo sau khi hoàn tất.