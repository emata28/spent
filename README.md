# Spent - Flutter App with Supabase

A Flutter application with Supabase backend integration for managing expenses and transactions.

## Setup Instructions

1. Install Flutter:

   - Follow the [official Flutter installation guide](https://flutter.dev/docs/get-started/install)
   - Make sure you have Flutter SDK version 3.0.0 or higher

2. Clone this repository:

   ```bash
   git clone <repository-url>
   cd spent
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Set up Supabase:

   - Create a new project on [Supabase](https://supabase.com)
   - Get your project URL and anon key from the project settings
   - Create a `.env` file in the root directory with the following content:
     ```
     SUPABASE_URL=your_supabase_project_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

5. Update the Supabase credentials in `lib/main.dart`:

   - Replace `YOUR_SUPABASE_URL` with your actual Supabase project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your actual Supabase anon key

6. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/main.dart` - Main application entry point
- `lib/services/supabase_service.dart` - Supabase service for handling backend operations
- `lib/models/` - Data models
- `lib/screens/` - UI screens
- `lib/widgets/` - Reusable widgets

## Features

- User authentication (sign up, sign in, sign out)
- CRUD operations for data management
- Real-time data synchronization
- Secure data handling

## Dependencies

- Flutter SDK
- supabase_flutter: ^2.0.0
- flutter_dotenv: ^5.1.0
- provider: ^6.0.5
- go_router: ^13.0.0
