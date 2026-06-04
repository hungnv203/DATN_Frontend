# Agent Context

## Project Overview

You are senior flutter developer,This project is a Flutter mobile application developed using Clean Architecture principles.

### Tech Stack

* Flutter
* Dart
* Provider (ChangeNotifier) for state management
* REST API
* Clean Architecture

## Project Structure

```text
lib/
├── core/
├── data/
├── domain/
└── presentation/
```

### Layer Responsibilities

#### core

Contains shared components:

* Constants
* Themes
* Extensions
* Network clients
* Error handling
* Utilities
* Base classes

#### data

Responsible for data access.

Contains:

* Models
* DTOs
* Repositories implementation
* Data sources
* API services
* Local storage

#### domain

Business layer.

Contains:

* Entities
* Repository contracts
* UseCases

No Flutter dependency should exist in this layer.

#### presentation

UI layer.

Contains:

* Screens
* Widgets
* Providers (ChangeNotifier)
* Dialogs
* Navigation

## Architecture Flow

```text
UI
 ↓
Provider
 ↓
UseCase
 ↓
Repository
 ↓
DataSource
 ↓
API / Local DB
```

## Dependency Rule

```text
presentation
    ↓
domain
    ↓
data
    ↓
core

Never reverse dependencies.
```

## State Management

Use Provider + ChangeNotifier.

Example:

```text
MovieScreen
    ↓
MovieProvider
    ↓
GetMoviesUseCase
    ↓
MovieRepository
```

## Coding Principles

* SOLID
* DRY
* KISS
* Clean Code
* Feature-first development

## Naming Convention

### Screen

```dart
MovieListScreen
MovieDetailScreen
```

### Provider

```dart
MovieProvider
BookingProvider
```

### UseCase

```dart
GetMoviesUseCase
BookTicketUseCase
```

### Repository

```dart
abstract class MovieRepository

class MovieRepositoryImpl
```

### DataSource

```dart
MovieRemoteDataSource
MovieLocalDataSource
```

## Agent Responsibilities

When generating code:

1. Follow Clean Architecture strictly.
2. Put business logic into UseCases.
3. Keep Providers thin.
4. Avoid API calls directly from UI.
5. Avoid business logic inside Widgets.
6. Create Entities before Models.
7. Repository implementations belong to data layer.
8. Use ChangeNotifier for state updates.
9. Prefer composition over inheritance.
10. Generate production-ready code.
