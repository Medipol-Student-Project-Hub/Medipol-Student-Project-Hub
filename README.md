# Medipol Student Project Hub

A collaborative platform for Medipol University students to share project ideas and form interdisciplinary teams.

## Tech Stack
- **Backend**: Django REST Framework
- **Frontend**: Flutter
- **Database**: SQLite (Development) / MySQL (Production)
- **Authentication**: JWT (JSON Web Tokens)

## Team Members
- Erva Şengül - Backend & API
- Azra Karakaya - Database & API
- Beril Mutlu - Frontend & UI
- Ayşe Çapacı - Frontend & UI

## Prerequisites

Before running this project, ensure you have the following installed:

### Backend Requirements
- **Python**: 3.11 or higher
- **pip**: Latest version
- **Virtual Environment**: venv or virtualenv

### Frontend Requirements
- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: Included with Flutter
- **Android Studio** (for Android development) or **Xcode** (for iOS development)

### Database
- **SQLite**: Included with Python (for development)
- **MySQL**: 8.0 or higher (optional, for production)

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Medipol-Student-Project-Hub/Medipol-Student-Project-Hub.git
cd Medipol-Student-Project-Hub
```

### 2. Backend Setup

#### Step 1: Create Virtual Environment

```bash
cd backend
python -m venv venv
```

#### Step 2: Activate Virtual Environment

**Mac/Linux:**
```bash
source venv/bin/activate
```

**Windows:**
```bash
venv\Scripts\activate
```

#### Step 3: Install Dependencies

```bash
pip install -r requirements.txt
```

#### Step 4: Environment Variables (Optional)

Create a `.env` file in the `backend` directory if you need custom configuration:

```env
# Database Configuration (Optional - defaults to SQLite)
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=db.sqlite3

# For MySQL (uncomment and configure if needed)
# DB_ENGINE=django.db.backends.mysql
# DB_NAME=medipol_project_hub
# DB_USER=your_mysql_username
# DB_PASSWORD=your_mysql_password
# DB_HOST=localhost
# DB_PORT=3306

# Django Secret Key (Optional - auto-generated if not set)
SECRET_KEY=your-secret-key-here

# Debug Mode
DEBUG=True

# Allowed Hosts
ALLOWED_HOSTS=localhost,127.0.0.1
```

#### Step 5: Database Setup

Run migrations to create database tables:

```bash
python manage.py migrate
```

#### Step 6: Load Sample Data (Optional)

To populate the database with sample data for testing:

```bash
python manage.py seed_data
```

This will create:
- Sample student and faculty accounts
- Sample projects with different statuses
- Team memberships
- Join requests
- Messages between users

#### Step 7: Run Backend Server

```bash
python manage.py runserver
```

The backend API will be available at `http://localhost:8000`

### 3. Frontend Setup

#### Step 1: Navigate to Frontend Directory

```bash
cd frontend/project_hub
```

#### Step 2: Install Dependencies

```bash
flutter pub get
```

#### Step 3: Configure API Endpoint

The API endpoint is configured in `lib/services/api_config.dart`. By default, it points to:
- **Android Emulator**: `http://10.0.2.2:8000`
- **iOS Simulator**: `http://localhost:8000`
- **Physical Device**: Update to your computer's IP address (e.g., `http://192.168.1.100:8000`)

To change the API endpoint, edit `lib/services/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://YOUR_IP_ADDRESS:8000';
  // ...
}
```

#### Step 4: Run Flutter App

**For Android Emulator/iOS Simulator:**
```bash
flutter run
```

**For specific device:**
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

## Database Setup (MySQL - Optional)

If you want to use MySQL instead of SQLite:

### 1. Install MySQL

Download and install MySQL from [https://dev.mysql.com/downloads/](https://dev.mysql.com/downloads/)

### 2. Create Database

```sql
CREATE DATABASE medipol_project_hub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'medipol_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON medipol_project_hub.* TO 'medipol_user'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Install MySQL Client

```bash
pip install mysqlclient
```

### 4. Update Django Settings

In `backend/config/settings.py`, update the DATABASES configuration:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'medipol_project_hub',
        'USER': 'medipol_user',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
```

### 5. Run Migrations

```bash
python manage.py migrate
```

## Sample User Accounts (After Running seed_data)

### Students
- **Email**: `erva.sengul@medipol.edu.tr` | **Password**: `password123`
- **Email**: `ayse.capaci@medipol.edu.tr` | **Password**: `password123`
- **Email**: `beril.mutlu@medipol.edu.tr` | **Password**: `password123`

### Faculty
- **Email**: `ahmet.yilmaz@medipol.edu.tr` | **Password**: `password123`
- **Email**: `mehmet.kaya@medipol.edu.tr` | **Password**: `password123`

## Project Structure

```
Medipol-Student-Project-Hub/
├── backend/                    # Django REST API
│   ├── config/                 # Project configuration
│   │   ├── settings.py         # Django settings
│   │   ├── urls.py             # Main URL routing
│   │   └── management/         # Custom management commands
│   │       └── commands/
│   │           └── seed_data.py # Database seeding script
│   ├── users/                  # User management app
│   │   ├── models.py           # User, Student, Faculty models
│   │   ├── views.py            # Authentication & user endpoints
│   │   └── serializers.py      # User data serializers
│   ├── projects/               # Project management app
│   │   ├── models.py           # Project, JoinRequest, Milestone models
│   │   ├── views.py            # Project CRUD endpoints
│   │   └── serializers.py      # Project data serializers
│   ├── teams/                  # Team management app
│   │   ├── models.py           # Team model
│   │   └── views.py            # Team endpoints
│   ├── messaging/              # Messaging app
│   │   ├── models.py           # Message, Conversation models
│   │   └── views.py            # Messaging endpoints
│   ├── requirements.txt        # Python dependencies
│   └── manage.py               # Django management script
│
├── frontend/project_hub/       # Flutter mobile app
│   ├── lib/
│   │   ├── models/             # Data models
│   │   │   ├── user.dart       # User model classes
│   │   │   ├── project.dart    # Project model classes
│   │   │   └── message.dart    # Message model classes
│   │   ├── providers/          # State management (Provider)
│   │   │   ├── auth_provider.dart
│   │   │   ├── project_provider.dart
│   │   │   └── message_provider.dart
│   │   ├── screens/            # UI screens
│   │   │   ├── welcome_page.dart
│   │   │   ├── login_page.dart
│   │   │   ├── home_page.dart
│   │   │   ├── project_detail_page.dart
│   │   │   ├── professor_dashboard.dart
│   │   │   └── messaging_page.dart
│   │   ├── services/           # API services
│   │   │   ├── api_client.dart # HTTP client configuration
│   │   │   ├── api_config.dart # API endpoints
│   │   │   ├── auth_service.dart
│   │   │   ├── project_service.dart
│   │   │   └── message_service.dart
│   │   └── main.dart           # App entry point
│   ├── pubspec.yaml            # Flutter dependencies
│   └── android/                # Android-specific files
│
└── README.md                   # This file
```

## API Documentation

### Base URL
```
http://localhost:8000/api/
```

### Authentication Endpoints
- `POST /api/auth/login/` - User login
- `POST /api/auth/register/student/` - Student registration
- `POST /api/auth/register/faculty/` - Faculty registration
- `POST /api/auth/token/refresh/` - Refresh JWT token

### Project Endpoints
- `GET /api/projects/` - List all projects
- `GET /api/projects/{id}/` - Get project details
- `POST /api/projects/` - Create new project
- `PUT /api/projects/{id}/` - Update project
- `DELETE /api/projects/{id}/` - Delete project
- `POST /api/projects/{id}/join/` - Send join request
- `GET /api/projects/my-requests/` - Get user's join requests
- `GET /api/projects/received-requests/` - Get received join requests (project owners)
- `POST /api/projects/join-requests/{id}/approve/` - Approve join request
- `POST /api/projects/join-requests/{id}/reject/` - Reject join request

### User Endpoints
- `GET /api/students/profile/` - Get current student profile
- `PATCH /api/students/update_profile/` - Update student profile
- `GET /api/faculty/profile/` - Get current faculty profile
- `PATCH /api/faculty/update_profile/` - Update faculty profile

### Messaging Endpoints
- `GET /api/messages/conversations/` - List user conversations
- `GET /api/messages/conversations/{id}/` - Get conversation details
- `POST /api/messages/send/` - Send a message
- `PATCH /api/messages/{id}/read/` - Mark message as read

### Team Endpoints
- `GET /api/teams/` - List teams
- `GET /api/teams/{id}/` - Get team details
- `POST /api/teams/{id}/add_member/` - Add team member
- `POST /api/teams/{id}/remove_member/` - Remove team member

## Troubleshooting

### Backend Issues

#### Port Already in Use
If port 8000 is already in use, run the server on a different port:
```bash
python manage.py runserver 8001
```
Don't forget to update the API endpoint in the Flutter app.

#### Database Migration Errors
If you encounter migration errors, try:
```bash
python manage.py migrate --run-syncdb
```

#### Module Not Found Errors
Ensure virtual environment is activated and all dependencies are installed:
```bash
source venv/bin/activate  # Mac/Linux
pip install -r requirements.txt
```

#### CORS Errors
If you see CORS errors in the browser/app, ensure `django-cors-headers` is installed and configured in `settings.py`:
```python
INSTALLED_APPS = [
    ...
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    ...
]

CORS_ALLOW_ALL_ORIGINS = True  # For development only
```

### Frontend Issues

#### Connection Refused / Network Error
- Ensure backend server is running on `http://localhost:8000`
- For Android emulator, use `http://10.0.2.2:8000` instead of `localhost`
- For physical device, use your computer's IP address (e.g., `http://192.168.1.100:8000`)
- Check firewall settings to allow connections

#### Flutter Package Errors
Clear Flutter cache and reinstall packages:
```bash
flutter clean
flutter pub get
```

#### Build Errors
If you encounter build errors:
```bash
flutter clean
flutter pub get
flutter run
```

#### iOS Simulator Issues (Mac only)
If iOS simulator doesn't launch:
```bash
open -a Simulator
flutter run
```

### Common Issues

#### Cannot Login After Running seed_data
The seed_data command creates sample accounts. Use the credentials listed in the "Sample User Accounts" section above.

#### 404 Errors on API Calls
Check that:
1. Backend server is running
2. API endpoint in `api_config.dart` is correct
3. The route exists in Django URL configuration

#### Token Expired Errors
JWT tokens expire after a certain time. The app should automatically refresh tokens, but if you see authentication errors:
1. Logout and login again
2. Check token expiration settings in `backend/config/settings.py`

## Additional Notes

### Running in Production

For production deployment:
1. Set `DEBUG = False` in Django settings
2. Configure proper `ALLOWED_HOSTS`
3. Use environment variables for sensitive data
4. Set up HTTPS
5. Use a production database (MySQL/PostgreSQL)
6. Configure proper CORS settings
7. Use a production WSGI server (gunicorn/uwsgi)

### Data Persistence

- SQLite database file: `backend/db.sqlite3`
- To reset the database: Delete `db.sqlite3` and run migrations again
- Running `seed_data` multiple times may create duplicate data

### Code Standards

This project follows these coding standards:
- **Python**: PEP 8 style guide
- **Dart/Flutter**: Effective Dart style guide
- **Naming**: Descriptive variable and method names
- **Comments**: Added to complex business logic
- **Indentation**: 4 spaces for Python, 2 spaces for Dart

## Support

For issues or questions, please contact the development team or create an issue in the repository.
