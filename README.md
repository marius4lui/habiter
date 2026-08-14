<div align="center">

# 🌱 Habiter

**Build better habits, one day at a time.**

[![Flutter](https://img.shields.io/badge/Flutter-3.44.8-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-4285F4?style=for-the-badge)](https://github.com/marius4lui/habiter/releases)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Release](https://img.shields.io/github/v/release/marius4lui/habiter?style=for-the-badge&color=blue)](https://github.com/marius4lui/habiter/releases/latest)

<img src="assets/images/app_icon.png" width="120" alt="Habiter Logo" />

*A beautiful, cross-platform habit tracker built with Flutter*

[Download](#-download) • [Features](#-features) • [Screenshots](#-screenshots) • [Getting Started](#-getting-started) • [Contributing](#-contributing)

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 📱 Cross-Platform
Works seamlessly on **Android**, **iOS**, **Windows**, **macOS**, **Linux**, and **Web** from a single codebase.

### 🖥️ Desktop Optimized
Responsive layout with **NavigationRail sidebar** on desktop, **bottom navigation** on mobile.

### 🌙 Dark Mode
Beautiful dark theme with carefully crafted colors that are easy on the eyes.

</td>
<td width="50%">

### 📊 Analytics
Track your progress with **weekly charts**, **streaks**, and **completion rates**.

### 🔔 Reminders
Never miss a habit with **customizable notifications**.

### 🔒 Privacy First
All data stored **locally** on your device. No accounts required.

</td>
</tr>
</table>

---

## 📥 Download

### Latest Release: v1.3.3

| Platform | Download |
|----------|----------|
| 🤖 **Android** | [APK (Universal)](https://github.com/marius4lui/habiter/releases/latest) |
| 🪟 **Windows** | [Windows x64](https://github.com/marius4lui/habiter/releases/latest) |
| 🐧 **Linux** | [Linux x64](https://github.com/marius4lui/habiter/releases/latest) |
| 🍎 **macOS** | [macOS](https://github.com/marius4lui/habiter/releases/latest) |
| 🌐 **Web** | [Web App](https://github.com/marius4lui/habiter/releases/latest) |

---

## 🖼️ Screenshots

<div align="center">

| Mobile | Desktop |
|--------|---------|
| *Mobile view with bottom navigation* | *Desktop view with sidebar navigation* |

</div>

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44.8
- [Git](https://git-scm.com/)

### Installation

```bash
# Clone the repository
git clone https://github.com/marius4lui/habiter.git

# Navigate to project directory
cd habiter

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Web
flutter build web --release
```

---

## 🏗️ Project Structure

```
habiter/
├── lib/
│   ├── l10n/              # Localization (EN/DE)
│   ├── models/            # Data models
│   ├── providers/         # State management
│   ├── screens/           # App screens
│   ├── theme/             # App theming
│   ├── utils/             # Utility functions
│   └── widgets/           # Reusable widgets
├── assets/
│   └── images/            # App icons & images
├── android/               # Android configuration
├── ios/                   # iOS configuration
├── windows/               # Windows configuration
├── linux/                 # Linux configuration
├── macos/                 # macOS configuration
└── web/                   # Web configuration
```

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Provider** | State management |
| **SharedPreferences** | Local data persistence |
| **fl_chart** | Beautiful charts |
| **Google Fonts** | Typography (Plus Jakarta Sans) |
| **flutter_animate** | Smooth animations |

---

## 🌍 Localization

Habiter supports multiple languages:

- 🇬🇧 English
- 🇩🇪 German (Deutsch)

Want to contribute a translation? See [Contributing](#-contributing).

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with ❤️ and Flutter**

⭐ Star this repo if you find it helpful!

</div>
