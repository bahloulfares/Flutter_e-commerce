# 🔧 Guide de Débogage du Chatbot

## Résumé des Corrections Appliquées

✅ **Fichier `chatbot_screen.dart` recréé avec:**
- Logs détaillés en `developer.log()` pour suivre chaque étape
- Gestion d'erreurs améliorée
- Messages d'erreur affichés à l'utilisateur
- Code simplifié et nettoyé

## 🐛 Étapes de Débogage Pas à Pas

### **Étape 1 : Vérifier l'Accès au Chatbot**
1. Lancez l'app: `flutter run`
2. Appuyez sur l'écran **Produits**
3. Cherchez le **bouton FAB "Assistant"** en bas à droite
4. Si vous ne le voyez pas → **Problème de route** (voir Étape 6)

### **Étape 2 : Observer les Logs**
1. Ouvrez la **Console Flutter** (`flutter logs`)
2. Filtrez par: `flutter logs | grep "CHATBOT"`
3. Vous devriez voir:
   ```
   🤖 CHATBOT: Démarrage
   📦 CHATBOT: Chargement produits...
   ✅ CHATBOT: X produits reçus
   ✅ CHATBOT: X convertis
   ```

### **Étape 3 : Tester Envoi de Message**
1. Tapez: `"Bonjour"`
2. Attendez 2 secondes
3. Observez les logs:
   ```
   💬 CHATBOT: "Bonjour"
   🤖 CHATBOT: Intent=greeting
   ```

### **Étape 4 : Problèmes Courants**

#### 🔴 **Pas de message de bienvenue**
```
Symptôme: Écran vide au lancement
Cause: _addWelcomeMessage() ne s'exécute pas
Solution: Vérifiez initState() dans les logs
```

#### 🔴 **Backend ne répond pas**
```
Symptôme: "❌ CHATBOT ERREUR: Chargement produits échouée"
Cause: API non accessible
Solution:
- Vérifier .env.dev: API_BASE_URL=http://192.168.1.10:3001/api
- Tester: curl http://192.168.1.10:3001/api/articles
- Backend en cours d'exécution? node app.js
```

#### 🔴 **Conversion Article échouée**
```
Symptôme: "❌ CHATBOT ERREUR: Conversion Article échouée"
Cause: Format JSON invalide
Solution: Vérifiez Article.fromJson() capture les erreurs
Logs complets: Voir developer.log() avec {error: e}
```

#### 🔴 **Le message n'envoie pas**
```
Symptôme: Bouton Send non réactif
Cause: Possible timeout ou exception non attrapée
Solution: Vérifiez les logs pour "CHATBOT ERREUR"
```

### **Étape 5 : Tester les Réponses Rapides**
1. Écran du chatbot affiche des boutons (ex: "Voir les produits")
2. Appuyez sur un bouton
3. Logs devraient montrer:
   ```
   💬 CHATBOT: "Je recherche des smartphones"
   🤖 CHATBOT: Intent=productSearch
   ```

### **Étape 6 : Vérifier la Route**
1. Fichier: `approuter.dart` ligne 238
2. Recherchez: `'/chatbot': (context) => const ChatbotScreen(),`
3. Si manquante → Ajouter

### **Étape 7 : Vérifier le FAB**
1. Fichier: `products.dart` ligne 43
2. Recherchez: `FloatingActionButton.extended(...'/chatbot'...)`
3. Si manquant → Ajouter le bouton

## 📍 Points de Test Principaux

### **Backend (Node.js)**
```
Port: 3001
Route: http://192.168.1.10:3001/api/articles
Status: Doit retourner une liste d'articles
```

### **Frontend (Flutter)**
```
Route: /chatbot
Fichier: chatbot_screen.dart
Service: ChatbotService (détection d'intention)
```

## 🔍 Commandes Utiles

### **Flutter Logs**
```bash
flutter logs                              # Tous les logs
flutter logs | grep "CHATBOT"            # Seulement chatbot
flutter logs | grep "ChatbotDebug"       # Plus spécifique
```

### **Test Backend**
```bash
# Depuis le dossier backend
node app.js                              # Lancer le backend
curl http://192.168.1.10:3001/api/articles
```

### **Rebuild Flutter**
```bash
flutter clean
flutter pub get
flutter run
```

## 📊 Architecture Complète

```
┌─────────────────────────────────┐
│   Flutter App (Frontend)        │
│ chatbot_screen.dart             │
│ ├─ UI (bulles de message)       │
│ ├─ _sendMessage()               │
│ └─ _loadProducts()              │
└──────────── ↓ ──────────────────┘
             HTTP
┌──────────────────────────────────┐
│  ChatbotService (Local)          │
│ ├─ detectIntent()                │
│ ├─ generateResponse()             │
│ └─ _filterProducts()              │
└──────────── ↓ ──────────────────┘
             Produits
┌──────────────────────────────────┐
│  ArticleService (HTTP)           │
│ └─ getArticles()                  │
└──────────── ↓ ──────────────────┘
             HTTP
┌──────────────────────────────────┐
│   Backend (Node.js)              │
│ localhost:3001/api/articles      │
└──────────────────────────────────┘
```

## ✨ Résumé des Logs

### **Séquence Normale (Sans Erreur)**
```
🤖 CHATBOT: Démarrage
📦 CHATBOT: Chargement produits...
✅ CHATBOT: 5 produits reçus
✅ CHATBOT: 5 convertis
💬 CHATBOT: "Bonjour"
🤖 CHATBOT: Intent=greeting, Confiance=0.8
```

### **Avec Erreur Backend**
```
🤖 CHATBOT: Démarrage
📦 CHATBOT: Chargement produits...
❌ CHATBOT: Erreur produits - Erreur réseau: Connection refused
```

### **Avec Erreur Format**
```
✅ CHATBOT: 5 produits reçus
❌ CHATBOT: Conversion Article échouée - Erreur...
```

## 🎯 Prochaines Étapes

1. **Lancez l'app** et observez les logs
2. **Repérez le message d'erreur rouge** (❌)
3. **Consultez la section correspondante** dans ce guide
4. **Appliquez la solution** suggérée
5. **Relancez** pour confirmer

---

**Créé**: 12 Mai 2026  
**Version**: 1.0  
**Statut**: Chatbot en débogage intensif
