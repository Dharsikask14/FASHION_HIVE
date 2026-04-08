# SIVA SILKS — Fashion & Footwear App

## Quick Start

```bash
# 1. Generate platform files (first time only)
flutter create --platforms=android,web,windows .

# 2. Install packages
flutter pub get

# 3. Run
flutter run -d <device-id>      # Android phone
flutter run -d chrome           # Web
flutter run -d windows          # Desktop
```

---

## 🖼️ Adding Your Shop Logo

Your logo currently shows as an "SS" badge. To replace it with your real logo:

### Step 1 — Add your image
Copy your logo file into:
```
fashion_app/assets/images/siva_silks_logo.png
```
(PNG format recommended, ideally 200×200px or square)

### Step 2 — Enable in code
Open `lib/widgets/shop_logo.dart` and follow the comment instructions (uncomment the `Image.asset` block and remove the fallback).

The logo will automatically appear:
- In the animated top-left button on every screen
- In the shop info popup dialog

---

## ✅ Features

| Feature | Status |
|---|---|
| Animated SS logo on every screen | ✅ |
| Shop info popup (tap logo) | ✅ |
| Home banner slider (overflow fixed) | ✅ |
| Notification panel (tap bell icon) | ✅ |
| Fully editable profile with validation | ✅ |
| Birthday — calendar date picker | ✅ |
| Gender — dropdown selection | ✅ |
| Mobile — +91 Indian format, 10-digit validation | ✅ |
| Saved Addresses section (functional) | ✅ |
| Payment Methods section (functional) | ✅ |
| My Coupons section (functional) | ✅ |
| Track Order with progress steps | ✅ |
| Help & Support with FAQ + contact | ✅ |
| Notifications preferences | ✅ |
| Language selector | ✅ |
| Change Password with validation | ✅ |
| Buy Now → goes directly to checkout | ✅ |
| Full order flow (cart → checkout → success) | ✅ |
| Light theme (warm red/gold palette) | ✅ |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── theme/app_theme.dart       ← Colors & typography
├── models/models.dart         ← Data models
├── data/app_state.dart        ← State management
├── widgets/
│   ├── shop_logo_button.dart  ← Animated logo + shop info
│   ├── shop_logo.dart         ← Logo image widget (add your logo here)
│   └── product_card.dart
└── screens/
    ├── home_screen.dart
    ├── explore_screen.dart
    ├── product_detail_screen.dart
    ├── cart_screen.dart
    ├── checkout_screen.dart
    └── other_screens.dart     ← Profile, Wishlist, Search, Notifications
```

---

© 2025 Siva Silks — Salem, Tamil Nadu
