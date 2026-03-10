# 🎯 Vue d'ensemble du système d'authentification et d'autorisation

## 📊 Diagramme de flux du système

```
┌─────────────────────────────────────────────────────────────────────┐
│                    UTILISATEUR LANCE L'APP                           │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │ LoadUserData()   │
                    │ SharedPrefs      │
                    └────────┬─────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │                                         │
        ▼                                         ▼
┌───────────────────────┐            ┌───────────────────────┐
│ isAuthenticated=true  │            │ isAuthenticated=false │
│ userRole = 'admin'    │            │ userRole = 'user'     │
│ OR 'user'             │            │ OR ''                 │
└───────────────────────┘            └───────────────────────┘
        │                                         │
        │                    ┌────────────────────┴──────────────────┐
        │                    │         Drawer affiche :              │
        │                    │  - Accueil                           │
        │                    │  - Produits                          │
        │                    │  - Connexion  ← Important!           │
        │                    │  - Inscription                       │
        └────────┬───────────┴──────────────────────────────────────┘
                 │
        ┌────────▼──────────────────────────┐
        │  Drawer affiche :                  │
        │  - Accueil                        │
        │  - Produits                       │
        │  - Panier        ✅ requiresAuth  │
        │  - Paramètres    ✅ requiresAuth  │
        │  - Déconnexion   ✅ Si connecté  │
        │                                   │
        │  SI ADMIN:                        │
        │  - Catégories [ADMIN] ✅         │
        └────────┬──────────────────────────┘
                 │
        ┌────────▼─────────────────────────┐
        │  UTILISATEUR CLIQUE MENU          │
        └────────┬─────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
┌──────────────────┐  ┌──────────────────┐
│ Route publique?  │  │ Route requiert   │
│ / ou /Products   │  │ authentification?│
│                  │  │ /cartView ou     │
├──────────────────┤  │ /settingsDetails │
│ Naviguer         │  │                  │
│ directement ✅   │  ├──────────────────┤
│                  │  │ Authentifié?     │
└──────────────────┘  │                  │
                      ├──────────────────┤
                      │  OUI: Naviguer ✅│
                      │  NON: Écran      │
                      │  "Connexion      │
                      │  requise"        │
                      │  [Bouton login]  │
                      └──────────────────┘
```

---

## 🚨 Système de vérification multi-niveaux

```
                        ACCÈS À UNE ROUTE
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
            ┌──────────────┐     ┌──────────────┐
            │ Route Admin? │     │ Route Auth   │
            │              │     │ requise?     │
            └──────┬───────┘     └──────┬───────┘
                   │                    │
        ┌──────────▼──────────┐  ┌──────▼──────────┐
        │ isAdmin == true?    │  │ isAuthenticated?│
        │                     │  │                 │
        ├─────────┬───────────┤  ├────────┬────────┤
        │ OUI ✅  │ NON ❌   │  │ OUI ✅ │ NON ❌ │
        │ Accès   │ Écran    │  │ Accès  │ Écran  │
        │ OK      │ "Accès   │  │ OK     │"Connexion"
        │         │ refusé"  │  │        │requise"│
        └─────────┴──────────┘  └────────┴────────┘
```

---

## 📱 État du Drawer selon l'utilisateur

### 👤 Utilisateur NON connecté

```
┌─────────────────────────────┐
│   MY DRAWER                 │
├─────────────────────────────┤
│ 👤 Utilisateur              │  ← anonyme
│ email@example.com           │
├─────────────────────────────┤
│ 🏠 Accueil                  │  ✅ Visible
│ 🛍️ Produits                 │  ✅ Visible
│ 🔐 Connexion                │  ✅ Visible !!!
│ 📝 Inscription              │  ✅ Visible !!!
├─────────────────────────────┤
│ (Déconnexion masqué)        │  ❌ Masqué
├─────────────────────────────┤
│ ℹ️ À propos                  │
└─────────────────────────────┘
```

### 👥 Utilisateur connecté (USER)

```
┌──────────────────────────┐
│ 🟢 MY DRAWER             │  ← Vert (color user)
├──────────────────────────┤
│ 👤 John Doe              │  ← Connecté
│ user@test.com            │
├──────────────────────────┤
│ 🏠 Accueil               │  ✅ Visible
│ 🛍️ Produits              │  ✅ Visible
│ 🛒 Panier                │  ✅ Visible ! (requiresAuth)
│ ⚙️ Paramètres            │  ✅ Visible ! (requiresAuth)
│ ✅ Déconnexion           │  ✅ Visible !
├──────────────────────────┤
│ ℹ️ À propos              │
└──────────────────────────┘

(Connexion masqué)  ❌
(Inscription masqué) ❌
(Catégories masqué)  ❌
```

### 👑 Utilisateur connecté (ADMIN)

```
┌──────────────────────────┐
│ 🟣 MY DRAWER             │  ← Rose (color admin)
├──────────────────────────┤
│ 🛡️ Admin Test             │  ← Admin
│ admin@test.com           │
│ [ADMIN]                  │  ← Badge
├──────────────────────────┤
│ 🏠 Accueil               │  ✅ Visible
│ 🛍️ Produits              │  ✅ Visible
│ 📁 Catégories [ADMIN]    │  ✅ Visible ! (adminOnly)
│ 🛒 Panier                │  ✅ Visible
│ ⚙️ Paramètres            │  ✅ Visible
│ ✅ Déconnexion           │  ✅ Visible !
├──────────────────────────┤
│ ℹ️ À propos              │
└──────────────────────────┘

(Connexion masqué)   ❌
(Inscription masqué)  ❌
```

---

## 🎬 Scénarios d'interaction

### Scénario 1️⃣ : Non-connecté → Clic panier

```
START
  │
  ├─ Drawer n'affiche pas "Panier"
  │  └─ Utilisateur ne peut pas cliquer
  │
  └─ User essaie d'accéder /cartView directement via URL
     │
     └─ AuthRouteGuard intercepte
        │
        ├─ Vérify: isAuthenticated?
        │  ├─ NON
        │  │
        │  └─ Afficher écran "Connexion requise"
        │     │
        │     ├─ Icône 🔒 orange
        │     ├─ Message "Veuillez vous connecter"
        │     │
        │     └─ Bouton "Se connecter"
        │        │
        │        └─ Navigator
        │           └─ Aller à login
        │
        └─ USER SE CONNECTE
           │
           └─ Revenir à /cartView
              │
              └─ ✅ CartView charge
```

### Scénario 2️⃣ : User connecté → Clic paramètres

```
START
  │
  ├─ Drawer affiche "Paramètres"
  │  └─ User clique "Paramètres"
  │
  └─ AuthRouteGuard intercepte (/settingsDetails)
     │
     ├─ Vérify: isAuthenticated?
     │  ├─ OUI
     │  │
     │  └─ ✅ SettingsScreen charge directement
```

### Scénario 3️⃣ : User connecté → Essaie catégories

```
START
  │
  ├─ Drawer n'affiche PAS "Catégories"
  │  └─ User ne voit pas l'option
  │
  └─ User essaie d'accéder /Categories directement
     │
     └─ AdminRouteGuard intercepte
        │
        ├─ Vérify: isAdmin?
        │  ├─ NON (c'est un user)
        │  │
        │  └─ Afficher écran "Accès refusé"
        │     │
        │     ├─ Icône 🔒 rouge
        │     ├─ Message "Accès réservé aux administrateurs"
        │     ├─ Affiche son rôle: "Votre rôle: user"
        │     │
        │     └─ Bouton "Retour"
        │        │
        │        └─ Navigator.pop()
```

### Scénario 4️⃣ : Admin connecté → Accès catégories

```
START
  │
  ├─ Drawer affiche "Catégories [ADMIN]" avec badge orange
  │  └─ Admin clique
  │
  └─ AdminRouteGuard intercepte (/Categories)
     │
     ├─ Vérify: isAdmin?
     │  ├─ OUI
     │  │
     │  └─ ✅ Categorieslist charge
     │     │
     │     ├─ ✅ Bouton ➕ pour ajouter visible
     │     ├─ ✅ Boutons ✏️ et 🗑️ visibles
```

### Scénario 5️⃣ : Connecté → Clic déconnexion

```
START
  │
  ├─ Drawer affiche "Déconnexion" (car isAuthenticated = true)
  │  └─ User clique
  │
  └─ Exécuter logout()
     │
     ├─ SharedPreferences.clear()
     │  ├─ isAuthenticated = false
     │  ├─ userName = ''
     │  ├─ userEmail = ''
     │  ├─ userId = ''
     │  ├─ userRole = ''
     │
     └─ Rediriger vers /Settings (login)
        │
        └─ ✅ Drawer met à jour automatiquement
           │
           └─ Affiche Connexion/Inscription
              Masque Panier/Paramètres/Déconnexion
```

---

## 🔐 Points d'authentification

```
┌─────────────────────────────────────────┐
│         Points d'authentification         │
├─────────────────────────────────────────┤
│                                         │
│ 1. SharedPreferences                    │
│    └─ Stockage isAuthenticated          │
│                                         │
│ 2. AuthController                       │
│    ├─ Observable isAuthenticated        │
│    ├─ Getter isAdmin                    │
│    └─ Getter isUser                     │
│                                         │
│ 3. Drawer (mydrawer.dart)               │
│    ├─ Filtrage des menus                │
│    └─ Bouton déconnexion conditionnel   │
│                                         │
│ 4. Route Guards (approuter.dart)        │
│    ├─ AdminRouteGuard                   │
│    └─ AuthRouteGuard                    │
│                                         │
│ 5. Backend API                          │
│    └─ Verification JWT (À FAIRE)        │
│                                         │
└─────────────────────────────────────────┘
```

---

## ⚡ Logique décisionnelle simple

### Pour afficher un item du menu

```javascript
if (choice.adminOnly) {
  // Catégories - admin seulement
  show = isAdmin;
} else if (choice.requiresAuth) {
  // Panier, paramètres - auth requise
  show = isAuthenticated;
} else if (isLoginRoute) {
  // Connexion, inscription - non-auth seulement
  show = !isAuthenticated;
} else {
  // Accueil, produits - toujours
  show = true;
}
```

### Pour naviguer vers une route

```javascript
if (route.isAdminOnly) {
  if (!isAdmin) {
    show AdminRouteGuard;
    return;
  }
}

if (route.requiresAuth) {
  if (!isAuthenticated) {
    show AuthRouteGuard;
    return;
  }
}

// Tous les vérifications passées
loadScreen();
```

---

## ✅ Vérifications de sécurité

| Vérification | Niveau | Status |
|-------------|--------|---------|
| Menu filtré | Frontend | ✅ OK |
| Routes gardées | Frontend | ✅ OK |
| Boutons masqués | Frontend | ✅ OK |
| Redirects | Frontend | ✅ OK |
| API protection | Backend | ⚠️ À FAIRE |
| JWT validation | Backend | ⚠️ À FAIRE |

---

## 📈 Métriques de sécurité

### Avant cette implémentation
- ❌ Utilisateurs confus par les menus
- ❌ Boutons non-pertinents visibles
- ❌ Accès possible à routes non-autorisées
- ⚠️ Backend fourni le rôle mais pas utilisé

### Après cette implémentation
- ✅ Menus contextuels et clairs
- ✅ Boutons pertinents seulement
- ✅ Routes protégées par Guards
- ✅ Frontend sécurisé
- ⚠️ Backend encore à sécuriser

**Score de sécurité : 3/5** (bon frontend, backend incomplete)

---

## 🎯 Résumé pour tester

| Test | Étapes | Résultat attendu |
|------|--------|------------------|
| T1 | Non-connecté, ouvrir drawer | Panier et paramètres masqués |
| T2 | Non-connecté, cliquer panier (menu) | Panier ne devrait pas être cliquable |
| T3 | Non-connecté, accès /cartView URL | Écran "Connexion requise" |
| T4 | Connecté (user), ouvrir drawer | Panier visible |
| T5 | Connecté (user), accès /Categories | Écran "Accès refusé" rouge |
| T6 | Connecté (admin), ouvrir drawer | Catégories visible avec badge |
| T7 | Connecté (admin), accès /Categories | OK, charge la page |
| T8 | Connecté, cliquer déconnexion | Revenir login, drawer réinitialise |

---

Created: Today  
Status: ✅ Ready for testing  
Severity: 🟡 Medium (Frontend secure, Backend TBD)
