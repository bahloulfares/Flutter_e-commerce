# 🚀 Démarrage de l'application Flutter

## Pour un émulateur Android (local sur le même PC)
```bash
flutter run --dart-define=ENV=emulator
```

## Pour un vrai téléphone sur le même réseau (Wi-Fi)
```bash
flutter run --dart-define=ENV=dev
```

## Pour un simulateur iOS (local)
```bash
flutter run -d "iPhone 15"
```

## Avec logs détaillés
```bash
flutter run --dart-define=ENV=emulator --verbose
```

## Killer le processus Flutter et redémarrer
```bash
flutter clean
flutter pub get
flutter run --dart-define=ENV=emulator
```
