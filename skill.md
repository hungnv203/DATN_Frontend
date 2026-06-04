# Flutter Development Skill

## Skill: Create New Feature

When user requests a new feature:

### Step 1

Create Domain Layer

```text
domain/
├── entities
├── repositories
└── usecases
```

Generate:

* Entity
* Repository Contract
* UseCase

### Step 2

Create Data Layer

```text
data/
├── models
├── datasources
└── repositories
```

Generate:

* API Model
* DataSource
* Repository Implementation

### Step 3

Create Presentation Layer

```text
presentation/
├── providers
├── screens
└── widgets
```

Generate:

* Provider
* Screen
* Components

### Step 4

Wire Dependency Injection

Register:

```dart
Repository
UseCase
Provider
```

## Skill: Create Provider

Provider template:

```dart
class ExampleProvider extends ChangeNotifier {
  final ExampleUseCase _useCase;

  ExampleProvider(this._useCase);

  bool isLoading = false;
  String? error;

  Future<void> load() async {
    try {
      isLoading = true;
      notifyListeners();

      final result = await _useCase();

      // update state

    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
```

## Skill: API Integration

Always generate:

```text
RemoteDataSource
RepositoryImpl
UseCase
Provider
```

Never:

```text
Provider -> API
Screen -> API
Widget -> API
```

## Skill: Screen Creation

Each screen should contain:

```text
screen/
├── movie_screen.dart
├── widgets/
│   ├── movie_item.dart
│   └── movie_header.dart
```

Keep screen file small.

Move reusable widgets into widgets folder.

## Skill: Error Handling

Use unified exception handling.

```dart
ServerException
NetworkException
CacheException
```

Convert exceptions into user-friendly messages.

## Skill: State Handling

Every Provider should support:

```dart
Initial
Loading
Success
Error
```

Recommended:

```dart
enum ViewState {
  initial,
  loading,
  success,
  error
}
```

Use ViewState consistently across the application.
