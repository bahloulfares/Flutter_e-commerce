# Requirements Document

## Introduction

Cette fonctionnalité ajoute l'authentification biométrique (Face ID et empreinte digitale) à l'écran de connexion de l'application Flutter e-commerce. Elle s'appuie sur l'authentification email/password existante avec JWT. La biométrie est proposée comme méthode de connexion rapide après une première connexion réussie par email/password. Le stockage des credentials est local (SharedPreferences sécurisé), et la vérification biométrique est effectuée entièrement côté appareil via le plugin `local_auth`. Aucun changement backend n'est requis.

Téléphone cible : Infinix X6882 (Android 14). State management : GetX.

---

## Glossaire

- **BiometricService** : Service Flutter responsable de la vérification de la disponibilité biométrique et du déclenchement de l'authentification biométrique via `local_auth`.
- **AuthController** : Contrôleur GetX existant (`user.controller.dart`) gérant l'état d'authentification de l'utilisateur.
- **LoginForm** : Widget Flutter existant (`loginform.widget.dart`) affichant le formulaire email/password.
- **SecureStorage** : Mécanisme de stockage local sécurisé des credentials (email + password chiffrés) via `flutter_secure_storage`.
- **JWT** : JSON Web Token retourné par le backend Node.js après une authentification réussie.
- **local_auth** : Plugin Flutter officiel pour l'authentification biométrique (empreinte digitale, Face ID).
- **Credential** : Combinaison email + password d'un utilisateur, stockée localement de façon chiffrée après consentement.

---

## Requirements

### Requirement 1 : Vérification de la disponibilité biométrique

**User Story :** En tant qu'utilisateur, je veux que l'application vérifie si mon appareil supporte la biométrie, afin que le bouton biométrique ne s'affiche que si la fonctionnalité est réellement disponible.

#### Acceptance Criteria

1. WHEN l'écran de connexion est affiché, THE BiometricService SHALL vérifier si l'appareil supporte l'authentification biométrique via `local_auth`.
2. WHEN l'appareil supporte la biométrie et qu'un credential est enregistré, THE LoginForm SHALL afficher le bouton d'authentification biométrique.
3. IF l'appareil ne supporte pas la biométrie, THEN THE LoginForm SHALL masquer le bouton d'authentification biométrique.
4. IF aucun credential n'est enregistré en SecureStorage, THEN THE LoginForm SHALL masquer le bouton d'authentification biométrique.

---

### Requirement 2 : Enregistrement du consentement et des credentials

**User Story :** En tant qu'utilisateur, je veux pouvoir activer la connexion biométrique après une connexion email/password réussie, afin de ne pas avoir à ressaisir mes identifiants à chaque fois.

#### Acceptance Criteria

1. WHEN une connexion email/password réussit, THE LoginForm SHALL proposer à l'utilisateur d'activer la connexion biométrique via une boîte de dialogue de consentement.
2. WHEN l'utilisateur accepte le consentement, THE SecureStorage SHALL stocker l'email et le password de façon chiffrée.
3. WHEN l'utilisateur refuse le consentement, THE SecureStorage SHALL ne stocker aucun credential biométrique.
4. THE SecureStorage SHALL stocker les credentials uniquement après une authentification email/password réussie et un consentement explicite de l'utilisateur.

---

### Requirement 3 : Authentification biométrique

**User Story :** En tant qu'utilisateur, je veux me connecter avec mon empreinte digitale ou Face ID, afin d'accéder rapidement à l'application sans saisir mon email et mon mot de passe.

#### Acceptance Criteria

1. WHEN l'utilisateur appuie sur le bouton biométrique, THE BiometricService SHALL déclencher la vérification biométrique native de l'appareil via `local_auth`.
2. WHEN la vérification biométrique réussit, THE AuthController SHALL récupérer les credentials depuis SecureStorage et appeler la méthode `login(email, password)` existante.
3. WHEN la connexion via les credentials récupérés réussit, THE AuthController SHALL naviguer vers l'écran `/Products`.
4. IF la vérification biométrique échoue, THEN THE LoginForm SHALL afficher un message d'erreur indiquant l'échec de l'authentification biométrique.
5. IF la vérification biométrique est annulée par l'utilisateur, THEN THE LoginForm SHALL rester sur l'écran de connexion sans afficher d'erreur.

---

### Requirement 4 : Gestion des erreurs biométriques

**User Story :** En tant qu'utilisateur, je veux être informé clairement en cas de problème biométrique, afin de pouvoir utiliser la connexion email/password comme alternative.

#### Acceptance Criteria

1. IF la biométrie est temporairement verrouillée (trop de tentatives), THEN THE LoginForm SHALL afficher un message indiquant que la biométrie est temporairement indisponible et inviter l'utilisateur à utiliser email/password.
2. IF les credentials stockés en SecureStorage sont corrompus ou absents, THEN THE BiometricService SHALL supprimer les credentials corrompus et THE LoginForm SHALL masquer le bouton biométrique.
3. WHEN une erreur inattendue survient lors de l'authentification biométrique, THE LoginForm SHALL afficher un message d'erreur générique et conserver le formulaire email/password accessible.

---

### Requirement 5 : Déconnexion et suppression des credentials biométriques

**User Story :** En tant qu'utilisateur, je veux que mes credentials biométriques soient supprimés lors de la déconnexion, afin de garantir la sécurité de mon compte.

#### Acceptance Criteria

1. WHEN l'utilisateur se déconnecte via `AuthController.logout()`, THE SecureStorage SHALL supprimer les credentials biométriques stockés.
2. THE AuthController SHALL appeler la suppression des credentials biométriques dans le cadre du flux de déconnexion existant.

---

### Requirement 6 : Permissions Android

**User Story :** En tant que développeur, je veux que les permissions Android nécessaires soient déclarées, afin que l'application puisse accéder au capteur biométrique sur Android 14.

#### Acceptance Criteria

1. THE AndroidManifest SHALL déclarer la permission `USE_BIOMETRIC`.
2. THE AndroidManifest SHALL déclarer la permission `USE_FINGERPRINT` pour la compatibilité avec les versions Android antérieures à Android 9.
3. WHERE l'appareil cible est Android 14 (API 34), THE BiometricService SHALL utiliser l'API `BiometricPrompt` via `local_auth` sans requérir de permissions supplémentaires à l'exécution.
