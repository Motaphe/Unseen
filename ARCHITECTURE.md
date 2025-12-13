# Unseen - Architecture Documentation

## High-Level Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        UI[UI Screens]
        Widgets[Reusable Widgets]
    end

    subgraph "State Management"
        AuthProvider[AuthProvider]
        HuntProvider[HuntProvider]
    end

    subgraph "Services"
        AuthService[AuthService]
        FirestoreService[FirestoreService]
        LocalDataService[LocalDataService]
        QRService[QRService]
        AudioService[AudioService]
        HapticService[HapticService]
    end

    subgraph "Backend"
        Firebase[(Firebase)]
        LocalStorage[(Local Storage)]
    end

    UI --> AuthProvider
    UI --> HuntProvider
    UI --> Widgets

    AuthProvider --> AuthService
    HuntProvider --> FirestoreService
    HuntProvider --> LocalDataService

    AuthService --> Firebase
    FirestoreService --> Firebase
    LocalDataService --> LocalStorage
```

## Data Model Relationships

```mermaid
erDiagram
    Hunt ||--|{ Clue : contains
    Hunt ||--o{ UserProgress : tracks
    User ||--o{ UserProgress : has
    Clue ||--o| UserProgress : recorded-in

    Hunt {
        string id PK
        string name
        string description
        string difficulty
        int clueCount
        list clueIds
        bool isAvailable
    }

    Clue {
        string id PK
        string huntId FK
        int order
        string hint
        string narrative
        string qrCode
        bool requiresPhoto
    }

    UserProgress {
        string id PK
        string userId FK
        string huntId FK
        int currentClueOrder
        list cluesFound
        map evidencePhotos
        datetime completedAt
        int pointsEarned
    }

    User {
        string uid PK
        string email
        string displayName
        list huntsCompleted
        int totalPoints
    }
```

## Service Layer Architecture

```mermaid
graph TB
    subgraph "Authentication"
        AuthService[AuthService]
        FirebaseAuth[Firebase Auth]
    end

    subgraph "Data Services"
        FirestoreService[FirestoreService]
        LocalDataService[LocalDataService]
        Firestore[(Cloud Firestore)]
        LocalDB[(In-Memory)]
    end

    subgraph "Feature Services"
        QRService[QR Code Generation]
        AudioService[Horror Audio]
        HapticService[Vibration]
    end

    AuthService --> FirebaseAuth
    FirestoreService --> Firestore
    LocalDataService --> LocalDB
    FirestoreService -.fallback.-> LocalDataService
```

## State Management

```mermaid
graph TB
    subgraph "Providers"
        AuthProvider[AuthProvider<br/>ChangeNotifier]
        HuntProvider[HuntProvider<br/>ChangeNotifier]
    end

    subgraph "State"
        AuthState["AuthStatus<br/>User<br/>ErrorMessage"]
        HuntState["Hunts<br/>CurrentHunt<br/>Clues<br/>Progress"]
    end

    subgraph "Services"
        AuthService[AuthService]
        FirestoreService[FirestoreService]
    end

    AuthProvider --> AuthState
    HuntProvider --> HuntState

    AuthProvider --> AuthService
    HuntProvider --> FirestoreService

    AuthService -.notifies.-> AuthProvider
    FirestoreService -.notifies.-> HuntProvider
```

## Navigation Flow

```mermaid
graph TD
    Splash[Splash] --> Auth{Authenticated?}

    Auth -->|No| Login[Login]
    Auth -->|Yes| Home[Home]

    Login --> Register[Register]
    Register --> Home
    Login --> Home

    Home --> HuntSelect[Hunt Select]
    Home --> Profile[Profile]
    Home --> AdminBuilder[Admin Builder]

    HuntSelect --> Hunt[Hunt Screen]
    Hunt --> ClueFound[Clue Found]
    Hunt --> HuntComplete[Hunt Complete]

    ClueFound --> Hunt
    HuntComplete --> Home

    Profile --> Settings[Settings]
    Profile --> PhotoGallery[Photo Gallery]

    style Splash fill:#8B0000
    style Home fill:#4a0e0e
    style Hunt fill:#6b1515
```

## Hunt Gameplay Workflow

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant HuntProvider
    participant Firestore
    participant Audio

    User->>UI: Select Hunt
    UI->>HuntProvider: startHunt(huntId)
    HuntProvider->>Firestore: Load Hunt + Clues
    Firestore-->>HuntProvider: Data
    HuntProvider-->>UI: Ready

    UI->>Audio: Play Ambient Sound
    UI->>User: Show Current Clue

    User->>UI: Scan QR Code

    alt Valid QR
        UI->>HuntProvider: markClueFound()
        HuntProvider->>Firestore: Save Progress
        UI->>Audio: Play Success Sound
        UI->>User: Show Narrative

        alt Last Clue
            UI->>HuntProvider: completeHunt()
            UI->>User: Completion Screen
        else More Clues
            UI->>User: Next Clue
        end
    else Invalid QR
        UI->>Audio: Play Error Sound
        UI->>User: Error Message
    end
```

## Firebase Collections

```mermaid
graph TB
    subgraph "Firestore"
        Users[users/]
        Hunts[hunts/]
        Clues[clues/]
        Progress[progress/]
    end

    Users --> UserDoc["userId<br/>email, displayName<br/>huntsCompleted, totalPoints"]
    Hunts --> HuntDoc["huntId<br/>name, difficulty<br/>clueIds, clueCount"]
    Clues --> ClueDoc["clueId<br/>huntId, order<br/>hint, narrative, qrCode"]
    Progress --> ProgressDoc["userId_huntId<br/>currentClueOrder<br/>cluesFound, evidencePhotos"]
```

## Offline Fallback

```mermaid
sequenceDiagram
    participant User
    participant HuntProvider
    participant Firestore
    participant LocalData

    User->>HuntProvider: Load Hunt
    HuntProvider->>Firestore: getHunt()

    alt Firestore Available
        Firestore-->>HuntProvider: Hunt Data
        HuntProvider-->>User: Online Mode
    else Firestore Error
        Firestore--xHuntProvider: Connection Failed
        HuntProvider->>LocalData: getHunt()
        LocalData-->>HuntProvider: Cached Data
        HuntProvider-->>User: Offline Mode
    end
```

---

**Tech Stack:** Flutter 3.x, Firebase (Auth, Firestore, Storage), Provider, GoRouter, mobile_scanner, audioplayers

**Key Patterns:** Provider for state management, Service layer for business logic, Offline-first with local fallback
