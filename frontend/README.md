# 🛒 Atelier7 E-commerce

Application Flutter e-commerce complète avec architecture Clean et gestion d'état GetX.

## 📋 Table des matières

- [Fonctionnalités](#-fonctionnalités)
- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Structure du projet](#-structure-du-projet)
- [Technologies utilisées](#-technologies-utilisées)
- [Sécurité](#-sécurité)

## ✨ Fonctionnalités

### 🔐 Authentification
- Inscription et connexion sécurisées
- Hashage des mots de passe (SHA-256)
- Stockage local avec SQLite
- Validation des formulaires

### 🛍️ Gestion des produits
- Liste des articles avec images
- Recherche et filtrage
- Détails des produits
- Panier persistant

### 📂 Gestion des catégories
- CRUD complet (Create, Read, Update, Delete)
- Upload d'images avec Cloudinary
- Interface intuitive

### 🗺️ Fonctionnalités additionnelles
- Carte interactive (Flutter Map)
- Navigation fluide
- Interface responsive

## 🏗️ Architecture

Le projet suit une **Clean Architecture** en trois couches :

```
lib/
├── domain/          # Logique métier
│   ├── entities/    # Entités métier
│   └── usecases/    # Cas d'utilisation
├── data/            # Couche de données
│   ├── datasource/  # Sources de données (API, DB)
│   ├── models/      # Modèles de données
│   └── repositories/# Implémentation des repositories
└── presentation/    # Interface utilisateur
    ├── controllers/ # Controllers GetX
    ├── screens/     # Écrans
    └── widgets/     # Composants UI réutilisables
```

### Principes appliqués
- ✅ Séparation des responsabilités
- ✅ Injection de dépendances (GetX)
- ✅ Gestion d'état réactive
- ✅ Gestion centralisée des erreurs

## 🔧 Prérequis

- Flutter SDK: ^3.5.3
- Dart SDK: ^3.5.3
- Android Studio / VS Code
- Un émulateur Android/iOS ou un appareil physique

## 📥 Installation

### 1. Cloner le projet
```bash
git clone <url-du-repo>
cd ecommerce
```

### 2. Installer les dépendances
```bash
flutter pub get
```

### 3. Vérifier la configuration Flutter
```bash
flutter doctor
```

### 4. Lancer l'application
```bash
flutter run
```

## ⚙️ Configuration

### Configuration de l'API Backend

Modifier l'URL de l'API dans `lib/utils/constants.dart`:

```dart
const baseUrl = "http://VOTRE_IP:3001/api";
```

**Pour trouver votre IP locale:**
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

### Configuration Cloudinary

Pour l'upload d'images, configurer vos identifiants Cloudinary dans le code approprié.

### Base de données locale

L'application utilise SQLite pour stocker les utilisateurs localement.
- Nom: `app.db`
- Tables: `users`

## 📁 Structure du projet

```
lib/
├── main.dart                 # Point d'entrée
├── approuter.dart            # Configuration des routes
├── domain/
│   ├── entities/
│   │   ├── article.entity.dart
│   │   ├── categorie.entity.dart
│   │   └── user.entity.dart
│   └── usecases/
│       ├── article.usecase.dart
│       ├── categorie.usecase.dart
│       └── user.usecase.dart
├── data/
│   ├── datasource/
│   │   ├── services/
│   │   │   ├── articleService.dart
│   │   │   └── categorie.service.dart
│   │   ├── models/
│   │   └── localdatasource/
│   │       └── user_local_data_source.dart
│   └── repositories/
│       ├── article.repository.dart
│       ├── categorie.repository.dart
│       └── user.repository.dart
├── presentation/
│   ├── controllers/
│   │   ├── article.controller.dart
│   │   ├── categorie.controller.dart
│   │   └── user.controller.dart
│   ├── screens/
│   │   ├── login.screen.dart
│   │   ├── register.screen.dart
│   │   ├── articleslist.screen.dart
│   │   ├── categorieslist.screen.dart
│   │   └── ... (15 écrans au total)
│   └── widgets/
│       └── ... (composants réutilisables)
└── utils/
    ├── constants.dart          # Configuration globale
    ├── error_handler.dart      # Gestion des erreurs
    ├── form_validators.dart    # Validation des formulaires
    └── password_helper.dart    # Sécurité des mots de passe
```

## 🛠️ Technologies utilisées

### Core
- **Flutter**: Framework UI cross-platform
- **Dart**: Langage de programmation

### State Management
- **GetX** (^4.6.6): Gestion d'état, injection de dépendances, navigation

### Networking
- **Dio** (^5.7.0): Client HTTP
- **http**: Requêtes HTTP additionnelles

### Database
- **sqflite** (^2.3.3): Base de données SQLite locale
- **path**: Gestion des chemins de fichiers

### UI/UX
- **flutter_map** (^7.0.2): Cartes interactives
- **latlong2** (^0.9.1): Coordonnées géographiques
- **persistent_shopping_cart** (^0.0.7): Panier persistant

### Media
- **image_picker** (^1.1.2): Sélection d'images
- **cloudinary_flutter** (^1.3.0): Upload et gestion d'images cloud
- **cloudinary_public** (^0.23.1)
- **cloudinary_url_gen** (^1.6.0)

### Security
- **crypto** (^3.0.6): Hashage des mots de passe

### Development
- **flutter_lints** (^4.0.0): Règles de linting

## 🔒 Sécurité

### Mots de passe
- ✅ Hashage SHA-256 avec salt
- ✅ Validation de la force du mot de passe
- ✅ Stockage sécurisé dans SQLite

### Validation
- ✅ Validation côté client (formulaires)
- ✅ Messages d'erreur explicites
- ✅ Protection contre les injections

### API
- ✅ Gestion des erreurs réseau
- ✅ Timeouts configurés (5 secondes)
- ✅ Gestion des codes HTTP

## 📊 Améliorations récentes

### ✅ Corrections appliquées
1. **Sécurité renforcée**
   - Hashage des mots de passe avec SHA-256
   - Helper de validation des mots de passe

2. **Gestion d'erreurs améliorée**
   - Classe ErrorHandler centralisée
   - Messages d'erreur explicites
   - Gestion des erreurs Dio

3. **Validation des formulaires**
   - Validateurs réutilisables
   - Feedback utilisateur

4. **Code optimisé**
   - Suppression des duplications
   - Meilleure organisation

5. **Configuration centralisée**
   - Constantes globales
   - Configuration API

## 🚀 Commandes utiles

```bash
# Installer les dépendances
flutter pub get

# Vérifier les mises à jour
flutter pub outdated

# Mettre à jour les packages
flutter pub upgrade

# Nettoyer le projet
flutter clean

# Analyser le code
flutter analyze

# Formater le code
flutter format lib/

# Build APK
flutter build apk

# Build en mode release
flutter build apk --release
```

## 📝 Notes

- L'URL de l'API est configurée pour un réseau local (à modifier pour la production)
- Les mots de passe sont hashés avant stockage
- Le panier est persistant entre les sessions
- Les images sont hébergées sur Cloudinary

## 👨‍💻 Développé par

Bahloul fares & Ben Rhaiem mohamed - Projet Atelier7 - Master ISET Sfax

## 📄 Licence

Ce projet est un projet académique.
