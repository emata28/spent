# Spent - Expense Tracking App

A Flutter application for tracking expenses and managing personal finances, built with Flutter and Supabase.

## Features

- **Authentication**

  - Email/Password authentication
  - Google Sign-In
  - Password reset functionality
  - Email verification
  - Secure password requirements
  - User profile management

- **Expense Tracking**
  - Add and categorize expenses
  - View expense history
  - Track spending patterns
  - Export expense reports

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Supabase account
- Google Cloud account (for Google Sign-In)
- PowerShell (for Windows users)

### Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/spent.git
   cd spent
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Supabase:

   - Create a new project in Supabase
   - Enable Email and Google authentication providers
   - Copy your Supabase URL and anon key
   - Create a `.env` file in the root directory:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

4. Configure Google Sign-In:

   - Create a project in Google Cloud Console
   - Enable Google Sign-In API
   - Create OAuth 2.0 credentials
   - Add authorized domains and redirect URIs
   - Configure the credentials in Supabase dashboard

5. Run the app:

   **Option 1: Using PowerShell Script (Recommended for Windows)**

   ```powershell
   .\run.ps1
   ```

   This script will:

   - Enable web support if not already enabled
   - Run Flutter pub get to ensure dependencies are up to date
   - Launch the app in Chrome

   **Option 2: Manual Run**

   ```bash
   flutter run -d chrome
   ```

## Project Structure

```
lib/
├── main.dart              # Application entry point
├── pages/                 # UI pages
│   ├── login_page.dart    # Login screen
│   └── signup_page.dart   # Registration screen
├── services/             # Business logic
│   └── supabase_service.dart  # Supabase client and methods
└── widgets/              # Reusable UI components
```

## Authentication Flow

1. **Sign Up**

   - Users can create an account with email and password
   - Password must meet security requirements
   - Email verification is required
   - User profile information is collected

2. **Sign In**

   - Email/password authentication
   - Google Sign-In option
   - Password reset functionality
   - Session management

3. **Security**
   - Secure password storage
   - Email verification
   - Session management
   - Protected routes

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend services
- Google for authentication services
