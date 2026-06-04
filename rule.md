# Flutter Clean Architecture Rules

## General Rules

* Always follow Clean Architecture.
* Never put business logic inside UI widgets.
* Never call APIs directly from presentation layer.
* Never access DataSource from Provider.
* Always use UseCase between Provider and Repository.

## Layer Rules

### presentation

Allowed:

* Screens
* Widgets
* Providers
* Navigation
* UI State

Not allowed:

* API calls
* Database access
* Repository implementation

### domain

Allowed:

* Entities
* Repository interfaces
* UseCases

Not allowed:

* Flutter imports
* Dio imports
* API models

### data

Allowed:

* Models
* DTOs
* Repository implementations
* API services

Not allowed:

* Widgets
* BuildContext
* UI code

## Provider Rules

Provider must:

* Extend ChangeNotifier
* Manage UI state only
* Call UseCases
* Handle loading state
* Handle error state

Example state:

```dart
bool isLoading = false;
String? errorMessage;
```

Avoid:

```dart
API call directly
Database access
Complex business logic
```

## Entity Rules

Entities must:

* Be immutable
* Contain business objects only
* Not depend on Flutter

Example:

```dart
class Movie {
  final String id;
  final String title;

  const Movie({
    required this.id,
    required this.title,
  });
}
```

## Model Rules

Models must:

* Extend or map from Entity
* Support JSON serialization

Required:

```dart
factory MovieModel.fromJson(...)
Map<String, dynamic> toJson()
```

## UseCase Rules

Each UseCase should:

* Have one responsibility
* Return Result/Either if possible
* Be testable

Naming:

```dart
GetMoviesUseCase
GetMovieDetailUseCase
BookTicketUseCase
```

## UI Rules

Prefer:

```dart
Consumer
Selector
context.read()
context.watch()
```

Avoid unnecessary rebuilds.

## Code Generation Rules

Whenever creating a new feature:

Create:

1. Entity
2. Repository Contract
3. UseCase
4. Model
5. DataSource
6. Repository Implementation
7. Provider
8. Screen
9. Widgets

in this exact order.
