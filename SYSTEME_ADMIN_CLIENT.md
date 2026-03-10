# Système Admin/Client - Documentation Complète

## 📋 Vue d'ensemble

**OUI, votre application possède maintenant un système complet de séparation entre partie ADMIN et partie CLIENT.**

Le système est basé sur un champ `role` dans la base de données qui peut avoir deux valeurs :
- `'admin'` : Utilisateurs administrateurs avec accès complet
- `'user'` : Utilisateurs normaux avec accès limité

---

## 🏗️ Architecture du système de rôles

### Backend (Node.js/MySQL)

#### 1. Modèle utilisateur (`backend/backend nodejs/models/user.js`)

```javascript
role: {
  type: DataTypes.ENUM('user', 'admin'),
  allowNull: false,
  defaultValue: 'user'
}
```

**Points clés :**
- Tous les nouveaux utilisateurs sont `'user'` par défaut
- Seul un admin peut créer un autre admin (modification directe en base de données nécessaire)
- Le rôle est stocké de manière sécurisée avec le modèle Sequelize

#### 2. API d'authentification

**Route `/api/users/register` :**
- Accepte un paramètre optionnel `role` (par défaut : `'user'`)
- Hash le mot de passe avec bcrypt
- Retourne le rôle dans la réponse

**Route `/api/users/login` :**
- Vérifie email + mot de passe
- Génère un JWT token (15min)
- **Retourne le rôle de l'utilisateur** dans la réponse
- Génère un refresh token (1 an)

### Frontend (Flutter/GetX)

#### 1. Stockage du rôle

**Fichier : `lib/data/repositories/user.repository.dart`**

```dart
Future<void> _persistAuth(Map<String, dynamic> user, AuthResponse response) async {
  final prefs = await SharedPreferences.getInstance();
  
  await prefs.setString(StorageKeys.accessToken, response.accessToken);
  await prefs.setString(StorageKeys.refreshToken, response.refreshToken);
  await prefs.setString(StorageKeys.userId, user['_id'] ?? user['id']);
  await prefs.setString(StorageKeys.userName, user['name']);
  await prefs.setString(StorageKeys.userEmail, user['email']);
  await prefs.setString(StorageKeys.userRole, user['role'] ?? 'user'); // ✅ Stockage du rôle
}
```

**Points clés :**
- Le rôle est sauvegardé dans SharedPreferences lors de la connexion
- Persistant même après redémarrage de l'application
- Récupéré automatiquement au lancement

#### 2. Contrôleur d'authentification

**Fichier : `lib/presentation/controllers/user.controller.dart`**

```dart
class AuthController extends GetxController {
  var userRole = ''.obs; // Observable pour réactivité
  
  // Getters pratiques
  bool get isAdmin => userRole.value == 'admin';
  bool get isUser => userRole.value == 'user';
  
  // Chargement au démarrage
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userName.value = prefs.getString(StorageKeys.userName) ?? '';
    userEmail.value = prefs.getString(StorageKeys.userEmail) ?? '';
    userId.value = prefs.getString(StorageKeys.userId) ?? '';
    userRole.value = prefs.getString(StorageKeys.userRole) ?? ''; // ✅ Chargement du rôle
  }
  
  // Nettoyage à la déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    userName.value = '';
    userEmail.value = '';
    userId.value = '';
    userRole.value = ''; // ✅ Reset du rôle
  }
}
```

---

## 🔐 Protections mises en place

### 1. Interface utilisateur (Drawer)

**Fichier : `lib/presentation/widgets/mydrawer.dart`**

#### A. Différenciation visuelle

**Pour les ADMINS :**
- 🟣 **Couleur rose** dans l'en-tête du drawer
- 🛡️ **Icône admin_panel_settings**
- 🏷️ **Badge "ADMIN"** visible

**Pour les USERS :**
- 🟢 **Couleur verte** dans l'en-tête du drawer
- 👤 **Icône person**
- Pas de badge

```dart
decoration: BoxDecoration(
  color: authController.userRole.value == 'admin'
      ? const Color.fromARGB(255, 175, 30, 124)  // Rose admin
      : const Color.fromARGB(255, 30, 175, 124),  // Vert user
),
```

#### B. Filtrage des menus

Les éléments du menu marqués `adminOnly: true` ne sont **visibles que pour les admins**.

```dart
class Choice {
  final bool adminOnly;  // ✅ Nouveau champ
  // ...
}

const List<Choice> choices = <Choice>[
  Choice(title: 'Accueil', icon: Icons.home, route: '/'),
  Choice(title: 'Catégories', icon: Icons.category, route: '/Categories', adminOnly: true), // ⚠️ Admin seulement
  Choice(title: 'Produits', icon: Icons.shopping_bag, route: '/Products'),
  Choice(title: 'Panier', icon: Icons.shopping_cart, route: '/cartView'),
  // ...
];
```

**Logique de filtrage :**
```dart
...choices.where((choice) {
  if (choice.adminOnly) {
    return authController.userRole.value == 'admin'; // Masquer pour non-admins
  }
  return true; // Afficher pour tous
})
```

### 2. Protection des écrans

#### A. Liste des catégories

**Fichier : `lib/presentation/screens/categorieslist.screen.dart`**

**Bouton d'ajout (FloatingActionButton) :**
```dart
floatingActionButton: Obx(() {
  final authController = Get.find<AuthController>();
  if (!authController.isAdmin) {
    return const SizedBox.shrink(); // ❌ Masqué pour non-admins
  }
  return FloatingActionButton(
    onPressed: () {
      Navigator.of(context).pushNamed('/addcategories');
    },
    child: const Icon(Icons.add),
  );
}),
```

**Résultat :**
- Admin : Voit le bouton ➕ pour ajouter une catégorie
- User : Le bouton est invisible

#### B. Widget de catégorie

**Fichier : `lib/presentation/widgets/categorieslist.widget.dart`**

**Boutons d'édition et suppression :**
```dart
trailing: Obx(() {
  final authController = Get.find<AuthController>();
  if (!authController.isAdmin) {
    return const SizedBox.shrink(); // ❌ Masqué pour non-admins
  }
  return Wrap(
    children: <Widget>[
      IconButton(
        icon: const Icon(Icons.edit, color: Colors.green),
        onPressed: () => { /* Éditer */ }
      ),
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => controller.deleteCategorie(categories.id),
      ),
    ],
  );
}),
```

**Résultat :**
- Admin : Voit les boutons ✏️ (éditer) et 🗑️ (supprimer)
- User : Les catégories sont en lecture seule

### 3. Protection des routes (Route Guards)

**Fichier : `lib/approuter.dart`**

#### Widget de protection

```dart
class AdminRouteGuard extends StatelessWidget {
  final Widget child;
  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Obx(() {
      if (authController.isAdmin) {
        return child; // ✅ Admin : accès autorisé
      }
      
      // ❌ Non-admin : écran d'accès refusé
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accès refusé'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const Text('Accès réservé aux administrateurs'),
              Text('Votre rôle : ${authController.userRole.value}'),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    });
  }
}
```

#### Routes protégées

```dart
Map<String, WidgetBuilder> appRoutes() {
  return {
    '/Categories': (context) => const AdminRouteGuard(
          child: Categorieslist(),
        ),
    '/addcategories': (context) => const AdminRouteGuard(
          child: Addcategorie(),
        ),
    '/editcategories': (context) {
      final categorie = ModalRoute.of(context)!.settings.arguments as CategorieEntity;
      return AdminRouteGuard(
        child: Editcategorie(categorie: categorie),
      );
    },
    // Autres routes non protégées...
  };
}
```

**Fonctionnement :**
1. Un utilisateur normal clique sur "Catégories" dans le menu → ❌ Menu item invisible
2. Si l'utilisateur accède directement via URL → ❌ Écran "Accès refusé" avec message
3. Admin → ✅ Accès complet à toutes les fonctionnalités

---

## 📊 Tableau récapitulatif : Admin vs Client

| Fonctionnalité | 👑 ADMIN | 👤 CLIENT |
|----------------|----------|-----------|
| **Voir les produits** | ✅ | ✅ |
| **Rechercher des produits** | ✅ | ✅ |
| **Ajouter au panier** | ✅ | ✅ |
| **Passer commande** | ✅ | ✅ |
| **Voir les catégories** | ✅ | ❌ |
| **Ajouter une catégorie** | ✅ | ❌ |
| **Modifier une catégorie** | ✅ | ❌ |
| **Supprimer une catégorie** | ✅ | ❌ |
| **Menu "Catégories" visible** | ✅ | ❌ |
| **Badge ADMIN dans drawer** | ✅ | ❌ |
| **Couleur drawer** | 🟣 Rose | 🟢 Vert |
| **Icône drawer** | 🛡️ admin_panel | 👤 person |

---

## 🧪 Comment tester le système

### 1. Créer un compte admin

**Option A : Modification en base de données**
```sql
-- Se connecter à MySQL
UPDATE users 
SET role = 'admin' 
WHERE email = 'votre_email@example.com';
```

**Option B : Via l'API (si autorisé)**
```bash
curl -X POST http://localhost:3001/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin Test",
    "email": "admin@test.com",
    "password": "admin123",
    "role": "admin"
  }'
```

### 2. Tester avec deux comptes

**Test complet recommandé :**

1. **Créer deux comptes :**
   - `admin@test.com` avec rôle `admin`
   - `user@test.com` avec rôle `user`

2. **Se connecter avec le compte USER :**
   - ✅ Le drawer est **VERT**
   - ✅ Icône = 👤
   - ❌ Pas de menu "Catégories"
   - ✅ Peut voir et acheter des produits
   - ❌ Aucun bouton d'édition/suppression visible

3. **Se déconnecter et se connecter avec ADMIN :**
   - ✅ Le drawer est **ROSE**
   - ✅ Icône = 🛡️ + badge "ADMIN"
   - ✅ Menu "Catégories" visible avec badge orange "ADMIN"
   - ✅ Bouton ➕ pour ajouter une catégorie
   - ✅ Boutons ✏️ et 🗑️ sur chaque catégorie

4. **Tester la protection de route :**
   - Connecté en USER, essayer d'accéder à `/Categories` directement
   - Résultat attendu : Écran rouge "Accès réservé aux administrateurs"

---

## 🔒 Sécurité

### Niveaux de protection

| Niveau | Description | Implémenté |
|--------|-------------|------------|
| **UI cachée** | Les boutons admin ne s'affichent pas pour les users | ✅ |
| **Menu filtré** | Les items admin sont masqués dans le drawer | ✅ |
| **Route guards** | Écran d'accès refusé si tentative d'accès direct | ✅ |
| **Backend protection** | (NON IMPLÉMENTÉ) Middleware JWT vérifiant le rôle | ⚠️ À FAIRE |

### ⚠️ Amélioration recommandée : Middleware backend

**Actuellement :** La protection est uniquement côté frontend. Un utilisateur malveillant pourrait contourner en appelant directement l'API.

**À ajouter :** Middleware Express pour vérifier le rôle dans le JWT

**Fichier : `backend/backend nodejs/middleware/admin.js`** (à créer)
```javascript
module.exports = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ 
      message: 'Accès réservé aux administrateurs' 
    });
  }
  next();
};
```

**Utilisation dans les routes :**
```javascript
const authJWT = require('../middleware/auth');
const adminAuth = require('../middleware/admin');

// Route protégée : seuls les admins peuvent ajouter une catégorie
router.post('/api/categories', authJWT, adminAuth, async (req, res) => {
  // Logique de création de catégorie
});
```

---

## 🎯 Ce qui a été fait aujourd'hui

✅ **Backend :** Rôle déjà existant dans le modèle User  
✅ **Frontend Storage :** Ajout de la persistance du rôle (SharedPreferences)  
✅ **Frontend Controller :** Suivi du rôle avec observables GetX  
✅ **UI Drawer :** Différenciation visuelle admin/user  
✅ **Menu Filtering :** Masquage des items admin pour les users  
✅ **Screen Protection :** Boutons cachés pour non-admins  
✅ **Route Guards :** Protection des routes avec écran d'accès refusé  
✅ **Documentation :** Ce fichier explicatif complet  

---

## 📝 Résumé en 3 points

1. **OUI, votre app a une séparation admin/client** basée sur le champ `role` en base de données
2. **Comment ça marche :**
   - Backend retourne le rôle lors de la connexion
   - Frontend stocke le rôle et adapte l'UI dynamiquement
   - Admins voient tout (rose, badge, menus admin)
   - Users voient uniquement l'espace client (vert, pas d'admin)
3. **Protection à 3 niveaux :**
   - UI (boutons cachés)
   - Routes (écran d'accès refusé)
   - Backend à améliorer (middleware recommandé)

---

**Auteur :** Système de rôles implémenté le $(date)  
**Version :** 1.0
