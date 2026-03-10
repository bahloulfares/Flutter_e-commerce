# Guide : Créer un compte administrateur

## 🎯 Objectif
Créer un compte utilisateur avec le rôle `'admin'` pour tester les fonctionnalités d'administration.

---

## Méthode 1 : Via SQL (Recommandé)

### Étape 1 : Créer un compte utilisateur normal

Utilisez l'application Flutter pour créer un compte :
- Email : `admin@test.com`
- Mot de passe : `admin123`
- Nom : `Admin Test`

### Étape 2 : Modifier le rôle en base de données

**Ouvrez MySQL Workbench ou votre client MySQL :**

```sql
-- Se connecter à la base de données
USE votre_nom_de_base_de_donnees;  -- Remplacer par le nom de votre DB

-- Vérifier les utilisateurs existants
SELECT id, name, email, role FROM users;

-- Modifier le rôle d'un utilisateur spécifique
UPDATE users 
SET role = 'admin' 
WHERE email = 'admin@test.com';

-- Vérifier la modification
SELECT id, name, email, role FROM users WHERE email = 'admin@test.com';
```

**Résultat attendu :**
```
| id | name       | email           | role  |
|----|------------|-----------------|-------|
| 5  | Admin Test | admin@test.com  | admin |
```

---

## Méthode 2 : Via l'API (si modification autorisée)

**Avec Postman ou curl :**

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

**Réponse attendue :**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "5",
    "name": "Admin Test",
    "email": "admin@test.com",
    "role": "admin"  ← Vérifiez cette valeur
  }
}
```

---

## Méthode 3 : Script Node.js automatique

Créez un fichier `create-admin.js` dans le dossier backend :

```javascript
const bcrypt = require('bcrypt');
const db = require('./models');
const User = db.user;

async function createAdmin() {
  try {
    // Vérifier si l'admin existe déjà
    const existingAdmin = await User.findOne({ 
      where: { email: 'admin@test.com' } 
    });

    if (existingAdmin) {
      console.log('❌ Un utilisateur avec cet email existe déjà');
      
      // Option : mettre à jour le rôle
      await existingAdmin.update({ role: 'admin' });
      console.log('✅ Rôle mis à jour vers "admin"');
      return;
    }

    // Créer un nouvel admin
    const hashedPassword = await bcrypt.hash('admin123', 10);
    
    const admin = await User.create({
      name: 'Admin Test',
      email: 'admin@test.com',
      password: hashedPassword,
      role: 'admin'
    });

    console.log('✅ Compte admin créé avec succès !');
    console.log('📧 Email :', admin.email);
    console.log('🔑 Mot de passe : admin123');
    console.log('👑 Rôle :', admin.role);
    
  } catch (error) {
    console.error('❌ Erreur lors de la création de l\'admin :', error);
  } finally {
    process.exit();
  }
}

// Exécuter la fonction
createAdmin();
```

**Pour l'exécuter :**
```bash
cd backend/backend\ nodejs
node create-admin.js
```

---

## ✅ Vérification après création

### 1. Test de connexion

Lancez l'application Flutter et connectez-vous avec :
- Email : `admin@test.com`
- Mot de passe : `admin123`

### 2. Signes d'un compte admin

**Dans le drawer (menu latéral) :**
- ✅ Couleur de l'en-tête : **ROSE** (au lieu de vert)
- ✅ Icône : **🛡️ admin_panel_settings** (au lieu de 👤 person)
- ✅ Badge **"ADMIN"** visible dans les cercles
- ✅ Menu **"Catégories"** visible avec badge orange "ADMIN"

**Dans l'écran des catégories :**
- ✅ Bouton **➕ flottant** pour ajouter une catégorie
- ✅ Boutons **✏️ Éditer** et **🗑️ Supprimer** sur chaque catégorie

### 3. Test de comparaison

**Créez aussi un compte USER normal :**
- Email : `user@test.com`
- Mot de passe : `user123`

**Connectez-vous alternativement avec les deux comptes pour comparer :**

| Caractéristique | Admin | User |
|----------------|-------|------|
| Couleur drawer | 🟣 Rose | 🟢 Vert |
| Icône | 🛡️ admin | 👤 person |
| Badge ADMIN | ✅ Oui | ❌ Non |
| Menu "Catégories" | ✅ Visible | ❌ Masqué |
| Bouton ➕ catégorie | ✅ Visible | ❌ Masqué |
| Boutons ✏️🗑️ | ✅ Visibles | ❌ Masqués |

---

## 🔐 Sécurité : Bonnes pratiques

### ⚠️ Ne jamais exposer la création d'admin dans l'interface publique

**DANGER :** Ne pas permettre à n'importe qui de créer un admin via l'API publique.

**Solution recommandée :**
- Créer le premier admin manuellement (SQL ou script)
- Permettre aux admins de promouvoir d'autres utilisateurs via une interface admin dédiée
- Protéger la route `/register` avec un paramètre `role` uniquement accessible aux admins

### Exemple de protection backend

**Fichier : `routes/user.route.js`**

```javascript
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    
    // ⚠️ IMPORTANT : Forcer le rôle 'user' sauf si demandé par un admin
    let finalRole = 'user';
    
    if (role === 'admin') {
      // Vérifier si la requête vient d'un admin authentifié
      // (nécessite un middleware authJWT + adminAuth)
      if (!req.user || req.user.role !== 'admin') {
        return res.status(403).json({ 
          message: 'Seuls les admins peuvent créer des admins' 
        });
      }
      finalRole = 'admin';
    }
    
    // Créer l'utilisateur avec le rôle approprié
    const user = await User.create({
      name,
      email,
      password: await bcrypt.hash(password, 10),
      role: finalRole
    });
    
    // ... reste du code
  } catch (error) {
    // ...
  }
});
```

---

## 📝 Récapitulatif

### Étapes rapides pour créer un admin :

1. **Créer un compte** via l'app : `admin@test.com` / `admin123`
2. **Se connecter à MySQL** et exécuter :
   ```sql
   UPDATE users SET role = 'admin' WHERE email = 'admin@test.com';
   ```
3. **Se déconnecter** de l'app Flutter
4. **Se reconnecter** avec `admin@test.com`
5. **Vérifier** : drawer rose, badge ADMIN, menu Catégories visible

### Comptes de test recommandés :

| Email | Mot de passe | Rôle | Usage |
|-------|--------------|------|-------|
| admin@test.com | admin123 | admin | Tests admin |
| user@test.com | user123 | user | Tests client |

---

**Besoin d'aide ?** Vérifiez la console de votre backend pour les logs d'authentification.
