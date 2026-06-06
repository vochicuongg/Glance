### YÊU CẦU DÀNH CHO AI ASSISTANT:
Hãy dùng công cụ `edit_file` mở file `android/app/src/main/kotlin/com/glanceapp/glance/GlanceOverlayService.kt`.

Tìm đến phần `companion object { ... }` (nằm ở đầu class) và **BỔ SUNG THÊM** 4 dòng hằng số sau vào bên trong block đó:

```kotlin
        const val ACTION_SET_INTENSITY = "com.glanceapp.glance.SET_INTENSITY"
        const val EXTRA_INTENSITY = "intensity"
        const val EXTRA_NOTIFICATION_TITLE = "notification_title"
        const val EXTRA_NOTIFICATION_TEXT = "notification_text"

```

Chỉ cần nạp lại 4 biến này để giải quyết lỗi Unresolved reference. Sửa xong hãy báo cáo lại trạng thái.
