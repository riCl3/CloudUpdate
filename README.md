# 🌦️📰 Weather & News App

A modern, elegant **Flutter app** that delivers **real-time weather updates** and the **latest news headlines** in one unified experience. Built using clean architecture and the latest Flutter best practices.

![App Banner](assets/banner.png) <!-- Optional: Add screenshot/banner -->

---

## 🚀 Features

### ☁️ Weather Module
- Get **current weather** based on your location
- View **5-day weather forecast**
- Supports location permissions with fallback
- Weather details include temperature, humidity, wind speed, condition icon
- Built using **OpenWeatherMap API**

### 📰 News Module
- Browse latest **Top Headlines**
- Filter by **category**, **country**, or **keyword**
- Offline support (optional via local caching)
- Built using **NewsAPI**

### 🎨 UI/UX
- Clean and intuitive UI
- Light/Dark theme ready
- Smooth animations & transitions
- Uses **Riverpod** or **Provider** for state management

---

## 📸 Screenshots

| Weather | News | Forecast |
|--------|------|----------|
| ![](assets/screenshot1.png) | ![](assets/screenshot2.png) | ![](assets/screenshot3.png) |

---

## 🛠️ Tech Stack

| Layer              | Technologies Used                              |
|-------------------|--------------------------------------------------|
| UI                | Flutter, Custom Widgets, Animations             |
| State Management  | Riverpod / Provider                             |
| Networking        | Dio, HTTP, JSON serialization                   |
| Location          | geolocator, geocoding                           |
| Persistence       | Hive / SharedPreferences (for offline support)  |
| APIs              | OpenWeatherMap, NewsAPI                         |

---

## 📦 Setup Instructions

---

## 🔧 Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/weather-news-app.git
   cd weather-news-app
    ```
2. ## Install dependencies

```
flutter pub get
```
3. ## Set up APIs

### Create a .env file or use dart-define in launch.json

4. ## Add your keys:
```
WEATHER_API_KEY=your_openweather_key
NEWS_API_KEY=your_newsapi_key
```
5. ## Run the app

```
flutter run
```
6. ## API Key Setup
You can pass API keys using Flutter's --dart-define flag.
```
flutter run --dart-define=WEATHER_API_KEY=your_key --dart-define=NEWS_API_KEY=your_key
```
Or set them using a .env file and use flutter_dotenv.

📱 Platforms Supported
✅ Android

✅ iOS (Tested)

✅ Web (Basic support)

✅ Desktop (Optional, experimental)

🤝 Contributing
Contributions are welcome! If you find bugs or want to improve features/UI:

Fork the repository

Create a new branch

Open a Pull Request (PR)


✨ Credits
Weather API: OpenWeatherMap

News API: NewsAPI.org

  
