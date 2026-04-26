# Calories Tracker

A comprehensive Flutter-based health and fitness application designed to help users track their nutritional intake, exercises, and physical progress. The app features role-based access control, allowing both individual clients and dieticians to collaborate on health goals.

## 🚀 Key Features

### For Clients
- **Daily Food Diary:** Log breakfast, lunch, dinner, and snacks with detailed nutritional information.
- **Exercise Tracking:** Record physical activities and monitor active calories burned.
- **Water Intake:** Keep track of daily hydration levels.
- **Weight Monitoring:** Log weight entries and visualize progress through interactive charts.
- **Nutritional Insights:** View daily breakdowns of calories and macronutrients.
- **Global Food Search:** Search a vast database of foods powered by the FatSecret API.

### For Dieticians
- **Client Dashboard:** View and manage a list of assigned clients.
- **Diary Supervision:** Remotely monitor client food diaries to provide feedback.
- **Progress Tracking:** Analyze client weight trends and nutritional consistency.
- **Food Management:** Create and manage custom food entries for the application database.

### General Features
- **Theming:** Full support for Light and Dark modes.
- **Role-Based Routing:** Automated navigation based on user roles (Client vs. Dietician).
- **Secure Authentication:** Robust login and signup system powered by Firebase.

## 🛠 Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend/Database:** [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **External API:** [FatSecret Platform API](https://platform.fatsecret.com/) (via OAuth1)
- **Data Visualization:** [fl_chart](https://pub.dev/packages/fl_chart)
- **Environment Config:** [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- A Firebase project
- FatSecret Platform API credentials

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/calories_tracking.git
    cd calories_tracking
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup:**
    - Create a new project in the [Firebase Console](https://console.firebase.google.com/).
    - Add Android and iOS apps to your project.
    - Download `google-services.json` and place it in `android/app/`.
    - Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
    - Enable **Email/Password Authentication** and **Cloud Firestore**.

4.  **Environment Variables:**
    Create a `.env` file in the project root and add your FatSecret API credentials:
    ```env
    FATSECRET_CONSUMER_KEY=your_consumer_key
    FATSECRET_CONSUMER_SECRET=your_consumer_secret
    ```

5.  **Run the application:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

- `lib/auth/`: Authentication logic, Firebase initialization, and role-based routing.
- `lib/pages/`: UI screens for diary, weight, exercise, and dietician dashboard.
- `lib/services/`: External API service for FatSecret integration.
- `lib/providers/`: Theme and state management logic.
- `lib/widgets/`: Reusable UI components like cards and toggles.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
