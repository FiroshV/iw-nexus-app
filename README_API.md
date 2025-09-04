# Enhanced API Service

This Flutter application now features a fully centralized and enhanced API service architecture that makes URL management and API calls extremely easy to maintain.

## Key Features

✅ **Centralized URL Management** - All API URLs managed from a single place
✅ **Environment Support** - Automatic dev/staging/production URL switching
✅ **Secure Configuration** - Environment variables support with `.env` files
✅ **Enhanced HTTP Client** - Custom client with logging and interceptors
✅ **Comprehensive Documentation** - Full dartdoc documentation for all methods
✅ **Type-Safe Endpoints** - Organized constants for all API endpoints

## Quick Start

### 1. Change API URLs

To change API URLs, simply update the `.env` file:

```bash
# Development
API_BASE_URL=http://localhost:3000/api

# Production
API_BASE_URL=https://your-production-api.com/api

# Staging
API_BASE_URL=https://staging-api.your-domain.com/api
```

### 2. Using the API Service

All API calls are made through the centralized `ApiService` class:

```dart
// Authentication
final response = await ApiService.checkUserExists(
  identifier: 'user@example.com',
  method: 'email',
);

// User management
final users = await ApiService.getAllUsers(
  page: 1,
  limit: 20,
  department: 'Engineering',
);

// Attendance
final checkIn = await ApiService.checkIn(
  location: {
    'latitude': 40.7128,
    'longitude': -74.0060,
    'address': 'Office Location'
  },
);
```

## File Structure

```
lib/
├── config/
│   ├── api_config.dart         # Environment and configuration management
│   ├── api_endpoints.dart      # All API endpoint constants
│   └── http_client_config.dart # Enhanced HTTP client configuration
├── services/
│   └── api_service.dart        # Main API service with all methods
└── main.dart                   # Initialized with ApiConfig.initialize()
```

## Configuration Files

### 1. `api_config.dart`
- Environment detection (dev/staging/production)
- Base URL management with environment variable support
- HTTP timeouts, retry settings, and other configurations
- App-specific headers and user agent

### 2. `api_endpoints.dart`
- All API endpoints as constants
- Helper methods for dynamic endpoints (user/{id})
- Query builders for complex endpoints with parameters

### 3. `http_client_config.dart`
- Enhanced HTTP client with request/response interceptors
- Network logging for development
- Connection pooling and keep-alive settings
- Request retry logic and error handling

## Environment Variables

Create a `.env` file in the root directory:

```bash
# API Configuration
API_BASE_URL=http://localhost:3000/api

# Debug settings
ENABLE_API_LOGGING=true
ENABLE_AUTH_LOGGING=true

# App configuration
APP_NAME=IW Nexus
APP_VERSION=1.0.0
```

## Benefits

1. **Easy URL Changes**: Change URLs in one place (`.env` file)
2. **Environment Management**: Automatic switching between dev/staging/production
3. **Better Maintainability**: All endpoints organized in constants
4. **Enhanced Debugging**: Built-in logging and error handling
5. **Type Safety**: Strongly typed responses and parameters
6. **Comprehensive Documentation**: Full documentation for all methods

## Development vs Production

The service automatically detects the build mode:
- **Debug Mode**: Uses development URLs and enables logging
- **Profile Mode**: Uses staging URLs
- **Release Mode**: Uses production URLs and disables logging

## Adding New Endpoints

1. Add the endpoint constant to `api_endpoints.dart`:
```dart
static const String newFeature = '/new-feature';
```

2. Add the method to `api_service.dart`:
```dart
/// Description of the new endpoint
static Future<ApiResponse<Map<String, dynamic>>> newFeature() async {
  return await _makeRequest<Map<String, dynamic>>(
    ApiEndpoints.newFeature,
    HttpMethods.get,
  );
}
```

That's it! The new endpoint is now available throughout the app with full configuration support.