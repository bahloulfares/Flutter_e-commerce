# 📚 Documentation: Login & Filtrage E-Commerce

**Date:** 10 Mars 2026  
**Projet:** Application E-Commerce Flutter + Node.js

---

## ✅ CORRECTIONS EFFECTUÉES

### 1. **Route Panier Corrigée** 
📄 Fichier: `lib/presentation/widgets/mydrawer.dart`

**Avant:**
```dart
Choice(title: 'Panier', icon: Icons.shopping_cart, route: '/shopping'),
```

**Après:**
```dart
Choice(title: 'Panier', icon: Icons.shopping_cart, route: '/cartView'),
```

**Raison:** La route `/shopping` n'existe pas dans `approuter.dart`. La vraie route du panier est `/cartView`.

---

### 2. **Filtrage par Recherche Ajouté**
📄 Fichier: `lib/presentation/screens/products.dart`

**Fonctionnalités ajoutées:**
- ✅ **Recherche en temps réel** : filtre par nom et marque de produit
- ✅ **Bouton clear** : réinitialise la recherche
- ✅ **Affichage catégories** : chips horizontales pour navigation
- ✅ **État vide** : message si aucun produit trouvé

**Code implémenté:**
```dart
// État des filtres
String _searchQuery = '';
String? _selectedCategoryId;

// Barre de recherche avec clear
TextField(
  onChanged: (value) {
    setState(() {
      _searchQuery = value.toLowerCase();
    });
  },
  decoration: InputDecoration(
    hintText: 'Rechercher un produit...',
    suffixIcon: _searchQuery.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _searchQuery = ''),
          )
        : null,
  ),
)

// Logique de filtrage
final filteredArticles = _articleController.articlesList.where((article) {
  if (_searchQuery.isEmpty) return true;
  
  final designation = article.designation.toLowerCase();
  final marque = (article.marque ?? '').toLowerCase();
  final query = _searchQuery.toLowerCase();
  
  return designation.contains(query) || marque.contains(query);
}).toList();
```

---

### 3. **Entité Article Enrichie**
📄 Fichier: `lib/domain/entities/article.entity.dart`

**Champs ajoutés:**
```dart
class ArticleEntity {
  final String id;
  final String designation;
  final num? prix;
  final int? qtestock;
  final String? imageart;
  final String? marque;        // ✅ NOUVEAU
  final int? scategorieId;     // ✅ NOUVEAU
}
```

**Mapping mis à jour:**
📄 Fichier: `lib/domain/usecases/article.usecase.dart`
```dart
return ArticleEntity(
  id: element?.id ?? "",
  designation: element?.designation ?? "",
  prix: element?.prix ?? 0,
  qtestock: element?.qtestock ?? 0,
  imageart: element?.imageart ?? "",
  marque: element?.marque,         // ✅ AJOUTÉ
  scategorieId: element?.scategorieID,  // ✅ AJOUTÉ
);
```

---

## 🔐 LOGIQUE DE LOGIN COMPLÈTE

### **1. Architecture Backend**

#### **Base de données (MySQL):**
```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,  -- Hash bcrypt
  role ENUM('user', 'admin') DEFAULT 'user',
  avatar TEXT,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### **Routes API:**
📄 Fichier: `backend/routes/user.route.js`

**1️⃣ Inscription `/api/users/register`**
```javascript
router.post('/register', async (req, res) => {
  const { name, email, password, role = 'user' } = req.body;

  // Validation
  if (!name || !email || !password) {
    return res.status(400).json({ 
      success: false, 
      message: "All fields are required" 
    });
  }

  // Vérifier si email existe déjà
  const existingUser = await User.findOne({ where: { email } });
  if (existingUser) {
    return res.status(409).json({ 
      success: false, 
      message: "Account already exists" 
    });
  }

  // Hash du mot de passe (bcrypt avec 10 rounds)
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);

  // Création de l'utilisateur
  const newUser = await User.create({
    name,
    email,
    password: hashedPassword,
    role,
  });

  return res.status(201).json({ 
    success: true, 
    user: { id, name, email, role }
  });
});
```

**2️⃣ Connexion `/api/users/login`**
```javascript
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  // Validation
  if (!email || !password) {
    return res.status(400).json({ 
      success: false, 
      message: "All fields are required" 
    });
  }

  // Trouver l'utilisateur
  const user = await User.findOne({ where: { email } });
  if (!user) {
    return res.status(404).json({ 
      success: false, 
      message: "Account doesn't exist" 
    });
  }

  // Vérifier le mot de passe
  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    return res.status(400).json({ 
      success: false, 
      message: "Invalid credentials" 
    });
  }

  // Générer les tokens JWT
  const token = jwt.sign(
    { user: { id: user.id, email: user.email, name: user.name } },
    process.env.TOKEN,
    { expiresIn: '15m' }  // Token de courte durée
  );

  const refreshToken = jwt.sign(
    { user: { id: user.id, email: user.email } },
    process.env.REFRESH_TOKEN,
    { expiresIn: '1y' }  // Refresh token longue durée
  );

  res.status(200).json({
    success: true,
    token,           // Pour authentifier les requêtes
    refreshToken,    // Pour renouveler le token
    user: { id, name, email, role },
  });
});
```

---

### **2. Architecture Frontend**

#### **UseCase:**
📄 Fichier: `lib/domain/usecases/user.usecase.dart`

```dart
class AuthenticateUserUseCase {
  final UserService _service;

  AuthenticateUserUseCase({required UserService service}) 
    : _service = service;

  // LOGIN
  Future<bool> call(String email, String password) async {
    try {
      final response = await _service.login(email, password);
      
      if (response['success'] == true) {
        // Sauvegarder les données utilisateur
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageKeys.isLoggedIn, true);
        await prefs.setString(StorageKeys.username, response['user']['name']);
        await prefs.setString(StorageKeys.email, response['user']['email']);
        await prefs.setString(StorageKeys.userId, response['user']['id'].toString());
        await prefs.setString(StorageKeys.token, response['token']);
        await prefs.setString(StorageKeys.refreshToken, response['refreshToken']);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // REGISTER
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _service.register(name, email, password);
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
```

#### **Controller:**
📄 Fichier: `lib/presentation/controllers/user.controller.dart`

```dart
class AuthController extends GetxController {
  final AuthenticateUserUseCase _userUseCase;

  var isAuthenticated = false.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();  // Charger au démarrage
  }

  // Charger données depuis SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    isAuthenticated.value = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
    userName.value = prefs.getString(StorageKeys.username) ?? '';
    userEmail.value = prefs.getString(StorageKeys.email) ?? '';
    userId.value = prefs.getString(StorageKeys.userId) ?? '';
  }

  // Login
  Future<bool> login(String email, String password) async {
    final res = await _userUseCase.call(email, password);
    if (res) {
      await _loadUserData();  // Recharger les données
    }
    return res;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // Supprimer toutes les données
    isAuthenticated.value = false;
    userName.value = '';
    userEmail.value = '';
    userId.value = '';
  }
}
```

#### **Widget Login:**
📄 Fichier: `lib/presentation/widgets/loginform.widget.dart`

```dart
ElevatedButton(
  onPressed: _isLoading ? null : () async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final success = await _controller.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        // Rediriger vers Products
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/Products', 
          (route) => false
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email ou mot de passe invalide'))
        );
      }
      
      setState(() => _isLoading = false);
    }
  },
  child: _isLoading 
    ? CircularProgressIndicator() 
    : Text("Se connecter"),
)
```

---

## 🎯 CONDITIONS DE LOGIN

### **Quand le login est-il OBLIGATOIRE ?**

| **Action** | **Login requis?** | **Raison** |
|-----------|------------------|------------|
| 📋 Voir la liste des produits | ❌ NON | Permet aux visiteurs de découvrir le catalogue |
| 🔍 Rechercher des produits | ❌ NON | Navigation publique |
| 👁️ Voir les détails d'un produit | ❌ NON | Encourager l'intérêt avant inscription |
| 🛒 Ajouter au panier | ❌ NON | Panier local (PersistentShoppingCart) |
| 💳 **Passer commande** | ✅ **OUI** | Nécessite informations utilisateur |
| 📦 Voir historique commandes | ✅ **OUI** | Données personnelles |
| ⚙️ Modifier profil | ✅ **OUI** | Sécurité |
| ➕ Ajouter/modifier catégorie | ✅ **OUI (admin)** | Administration |

---

### **Implémentation de la Protection:**

**1️⃣ Dans le widget checkout:**
```dart
// checkout.screen.dart
void _placeOrder() async {
  final authController = Get.find<AuthController>();
  
  // ✅ Vérifier si l'utilisateur est connecté
  if (!authController.isAuthenticated.value) {
    Get.snackbar(
      'Connexion requise',
      'Vous devez vous connecter pour passer commande',
      snackPosition: SnackPosition.BOTTOM,
    );
    
    Get.offNamed('/Settings');  // Rediriger vers login
    return;
  }

  // Continuer avec la commande
  final userId = authController.userId.value;
  // ... création de commande
}
```

**2️⃣ Middleware de route (optionnel):**
```dart
// approuter.dart
'/checkout': (context) {
  final authController = Get.find<AuthController>();
  
  if (!authController.isAuthenticated.value) {
    return const Login();  // Forcer login
  }
  
  return const CheckoutScreen();
},
```

---

## 🔧 AMÉLIORATION FUTURE: Filtrage par Catégorie

### **Problème actuel:**
Les articles ont `scategorieId` (sous-catégorie), mais pas de lien direct vers la catégorie parente.

### **Solution 1: Modifier l'API Articles**

**Backend - Route améliorée:**
```javascript
// routes/article.route.js
router.get('/', async (req, res) => {
  try {
    const articles = await Article.findAll({
      include: [{
        model: Scategorie,
        as: 'scategorie',
        attributes: ['id', 'nomscategorie', 'categorieId'],
        include: [{
          model: Categorie,
          as: 'categorie',
          attributes: ['id', 'nomcategorie']
        }]
      }]
    });
    
    res.json(articles);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
```

**Frontend - Entité enrichie:**
```dart
class ArticleEntity {
  final String id;
  final String designation;
  final num? prix;
  final int? qtestock;
  final String? imageart;
  final String? marque;
  final int? scategorieId;
  final String? categorieName;     // ✅ NOUVEAU
  final int? categorieId;          // ✅ NOUVEAU
}
```

**Widget - Filtrage complet:**
```dart
final filteredArticles = _articleController.articlesList.where((article) {
  // Recherche
  final matchesSearch = _searchQuery.isEmpty ||
      article.designation.toLowerCase().contains(_searchQuery) ||
      (article.marque?.toLowerCase().contains(_searchQuery) ?? false);
  
  // Catégorie
  final matchesCategory = _selectedCategoryId == null ||
      article.categorieId?.toString() == _selectedCategoryId;
  
  return matchesSearch && matchesCategory;
}).toList();
```

### **Solution 2: Charger mapping côté Flutter**

```dart
class _ProductsState extends State<Products> {
  Map<int, int> scategorieToCategorie = {};  // subcatId -> catId

  @override
  void initState() {
    super.initState();
    _loadScategorieMapping();
  }

  Future<void> _loadScategorieMapping() async {
    final scategories = await scategorieUseCase.fetchScategories();
    setState(() {
      scategorieToCategorie = {
        for (var scat in scategories)
          scat.id: scat.categorieId
      };
    });
  }

  // Dans le filtrage
  final matchesCategory = _selectedCategoryId == null ||
      scategorieToCategorie[article.scategorieId] == 
          int.tryParse(_selectedCategoryId!);
}
```

---

## 📊 RÉCAPITULATIF

### ✅ **Ce qui fonctionne maintenant:**
1. Route panier corrigée (`/cartView`)
2. Recherche en temps réel (nom + marque)
3. Chips catégories affichées
4. Login/Register fonctionnels
5. Authentification persistante (SharedPreferences)

### 🚧 **À implémenter:**
1. Filtrage par catégorie complet (nécessite modification API)
2. Protection des routes sensibles (checkout, profil)
3. Refresh token automatique
4. Gestion erreurs réseau

### 🎯 **Best Practices Login:**
- **Toujours** hasher les mots de passe (bcrypt)
- **Ne jamais** stocker le mot de passe en clair
- Utiliser tokens JWT courts + refresh token
- Valider côté serveur ET client
- Effacer tokens au logout

---

**Développé avec ❤️ pour ISET Sfax**
