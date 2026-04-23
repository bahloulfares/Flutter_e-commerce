# Plan d'implémentation : biometric-login

## Vue d'ensemble

Ajout de l'authentification biométrique (empreinte digitale / Face ID) à l'application Flutter existante. L'implémentation suit la Clean Architecture en place (data / domain / presentation) et s'appuie sur `local_auth` et `flutter_secure_storage`. Aucune modification backend n'est requise.

## Tâches

- [x] 1. Ajouter les dépendances et les permissions Android
  - Ajouter `local_auth: ^2.3.0` et `flutter_secure_storage: ^9.2.4` dans `frontend/pubspec.yaml`
  - Ajouter `<uses-permission android:name="android.permission.USE_BIOMETRIC" />` dans `frontend/android/app/src/main/AndroidManifest.xml`
  - Ajouter `<uses-permission android:name="android.permission.USE_FINGERPRINT" />` dans le même fichier
  - _Requirements: 6.1, 6.2_

- [x] 2. Implémenter SecureStorageService
  - [x] 2.1 Créer `frontend/lib/utils/secure_storage_service.dart`
    - Définir l'interface `ISecureStorageService` avec les méthodes `saveCredentials`, `getCredentials`, `deleteCredentials`, `hasCredentials`
    - Implémenter `SecureStorageService` avec les clés `biometric_email` et `biometric_password`
    - Gérer les credentials corrompus (email présent mais password absent → supprimer + retourner null)
    - _Requirements: 2.2, 2.3, 4.2, 5.1_

  - [ ]* 2.2 Écrire le test de propriété P2 — Round-trip credentials
    - **Property 2 : Round-trip sauvegarde des credentials**
    - **Validates: Requirements 2.2**
    - Générer des paires (email, password) non vides aléatoires → save → get → comparer l'égalité exacte
    - Annoter : `// Feature: biometric-login, Property 2: Round-trip sauvegarde des credentials`
    - Fichier : `frontend/test/utils/secure_storage_service_test.dart`

  - [ ]* 2.3 Écrire le test de propriété P7 — Nettoyage des credentials corrompus
    - **Property 7 : Nettoyage des credentials corrompus**
    - **Validates: Requirements 4.2**
    - Générer des états partiels (email seul, password seul, valeurs vides) → vérifier `getCredentials() == null` et `hasCredentials() == false`
    - Annoter : `// Feature: biometric-login, Property 7: Nettoyage des credentials corrompus`
    - Fichier : `frontend/test/utils/secure_storage_service_test.dart`

  - [ ]* 2.4 Écrire le test de propriété P6 — Suppression au logout
    - **Property 6 : Suppression des credentials au logout**
    - **Validates: Requirements 5.1**
    - Générer des credentials aléatoires → save → deleteCredentials → vérifier `hasCredentials() == false` et `getCredentials() == null`
    - Annoter : `// Feature: biometric-login, Property 6: Suppression des credentials au logout`
    - Fichier : `frontend/test/utils/secure_storage_service_test.dart`

- [x] 3. Implémenter BiometricService
  - [x] 3.1 Créer `frontend/lib/utils/biometric_service.dart`
    - Définir l'enum `BiometricResult { success, failure, cancelled, notAvailable }`
    - Définir l'interface `IBiometricService` avec `isAvailable()` et `authenticate({required String reason})`
    - Implémenter `BiometricService` en mappant les `PlatformException` de `local_auth` vers `BiometricResult`
    - `isAvailable()` retourne `true` uniquement si l'appareil supporte la biométrie ET qu'un biométrique est enrôlé
    - _Requirements: 1.1, 3.1, 4.1, 6.3_

  - [ ]* 3.2 Écrire les tests unitaires de BiometricService
    - Tester que `isAvailable()` retourne `false` quand `local_auth` lève `NotAvailable`
    - Tester le mapping de chaque `PlatformException` vers le `BiometricResult` attendu (NotAvailable, LockedOut, PermanentlyLockedOut, UserCanceled, SystemCanceled)
    - Fichier : `frontend/test/utils/biometric_service_test.dart`
    - _Requirements: 1.1, 3.1, 4.1_

- [x] 4. Modifier AuthController pour intégrer la biométrie
  - [x] 4.1 Modifier `frontend/lib/presentation/controllers/user.controller.dart`
    - Injecter `ISecureStorageService` et `IBiometricService` via le constructeur
    - Ajouter l'état observable `var isBiometricAvailable = false.obs`
    - Implémenter `checkBiometricAvailability()` : vérifie `isAvailable()` ET `hasCredentials()` → met à jour `isBiometricAvailable`
    - Implémenter `loginWithBiometrics()` : appelle `authenticate()`, récupère les credentials, appelle `login(email, password)` existant
    - Implémenter `saveBiometricCredentials(String email, String password)` : délègue à `SecureStorageService`
    - Modifier `logout()` : appeler `_secureStorage.deleteCredentials()` avant de vider les SharedPreferences
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.2, 3.3, 5.1, 5.2_

  - [ ]* 4.2 Écrire le test de propriété P1 — Visibilité du bouton biométrique
    - **Property 1 : Visibilité du bouton biométrique**
    - **Validates: Requirements 1.2, 1.3, 1.4**
    - Générer toutes les combinaisons (isAvailable: bool, hasCredentials: bool) → vérifier que `isBiometricAvailable` est `true` ssi les deux sont `true`
    - Annoter : `// Feature: biometric-login, Property 1: Visibilité du bouton biométrique`
    - Fichier : `frontend/test/presentation/controllers/auth_controller_biometric_test.dart`

  - [ ]* 4.3 Écrire le test de propriété P3 — Round-trip biométrie → login
    - **Property 3 : Round-trip authentification biométrique → login**
    - **Validates: Requirements 3.2**
    - Mocker `BiometricService` retournant `success` + générer des credentials aléatoires → vérifier que `login()` est appelé avec exactement ces credentials
    - Annoter : `// Feature: biometric-login, Property 3: Round-trip authentification biométrique → login`
    - Fichier : `frontend/test/presentation/controllers/auth_controller_biometric_test.dart`

  - [ ]* 4.4 Écrire le test de propriété P4 — Navigation après succès biométrique
    - **Property 4 : Navigation après succès biométrique**
    - **Validates: Requirements 3.3**
    - Générer des credentials valides + mock login success → vérifier que la route `/Products` est atteinte et `isAuthenticated == true`
    - Annoter : `// Feature: biometric-login, Property 4: Navigation après succès biométrique`
    - Fichier : `frontend/test/presentation/controllers/auth_controller_biometric_test.dart`

- [ ] 5. Checkpoint — Vérifier les services et le contrôleur
  - S'assurer que tous les tests passent, poser des questions à l'utilisateur si nécessaire.

- [x] 6. Modifier LoginForm pour afficher le bouton biométrique et le dialogue de consentement
  - [x] 6.1 Modifier `frontend/lib/presentation/widgets/loginform.widget.dart`
    - Appeler `_controller.checkBiometricAvailability()` dans `initState`
    - Ajouter un `Obx` qui affiche le bouton biométrique (icône empreinte) si `_controller.isBiometricAvailable.value == true`
    - Après un login email/password réussi : afficher un `AlertDialog` de consentement proposant d'activer la biométrie
    - Si l'utilisateur accepte : appeler `_controller.saveBiometricCredentials(email, password)`
    - Brancher le bouton biométrique sur `_controller.loginWithBiometrics()` et gérer les `BiometricResult` retournés
    - Afficher un message d'erreur pour `BiometricResult.failure` (y compris LockedOut / PermanentlyLockedOut)
    - Traiter `BiometricResult.cancelled` silencieusement (aucun message)
    - _Requirements: 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 3.1, 3.4, 3.5, 4.1, 4.3_

  - [ ]* 6.2 Écrire le test de propriété P5 — Affichage d'erreur sur échec biométrique
    - **Property 5 : Affichage d'erreur sur échec biométrique**
    - **Validates: Requirements 3.4, 4.1, 4.3**
    - Générer des variantes de `BiometricResult.failure` → vérifier qu'un message d'erreur non vide est affiché et que le formulaire email/password reste accessible
    - Annoter : `// Feature: biometric-login, Property 5: Affichage d'erreur sur échec biométrique`
    - Fichier : `frontend/test/presentation/widgets/loginform_biometric_test.dart`

  - [ ]* 6.3 Écrire les tests unitaires du LoginForm biométrique
    - Tester que le dialogue de consentement s'affiche après un login email/password réussi
    - Tester que le bouton biométrique est absent quand `isBiometricAvailable == false`
    - Tester que l'annulation (`BiometricResult.cancelled`) n'affiche aucun message d'erreur
    - Fichier : `frontend/test/presentation/widgets/loginform_biometric_test.dart`
    - _Requirements: 2.1, 2.3, 3.5_

- [ ] 7. Checkpoint final — S'assurer que tous les tests passent
  - S'assurer que tous les tests passent, poser des questions à l'utilisateur si nécessaire.

## Notes

- Les tâches marquées `*` sont optionnelles et peuvent être ignorées pour un MVP rapide
- Chaque tâche référence les exigences spécifiques pour la traçabilité
- Les tests de propriétés valident les comportements universels décrits dans le design
- Les tests unitaires couvrent les cas limites et les mappings d'erreurs
- `IBiometricService` et `ISecureStorageService` permettent le mocking via `mocktail`
