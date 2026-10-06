# VOOM Delivery

Application de livraison à Lomé (Togo) : le client demande une livraison d'un **point A** (récupération du colis) à un **point B** (destination), paie par **Flooz** ou **Mixx by Yas** sur le compte marchand de l'agence et envoie la **capture d'écran** de la transaction. L'agence vérifie le paiement et assigne un **livreur**, qui suit la course sur **Google Maps**.

Le dépôt contient :

| Dossier | Contenu |
|---|---|
| `lib/` | Application mobile Flutter (clients et livreurs) |
| `backend/` | API REST + panneau d'administration web (Laravel 13, Sanctum) |
| `render.yaml` | Déploiement de l'API sur Render (Blueprint) |

## Fonctionnement

```
Client                         Admin (web /admin)                 Livreur
──────                         ──────────────────                 ───────
1. Demande A → B (carte)
   prix calculé (distance)
2. Paie Flooz / Mixx
   + envoie la capture  ──▶ 3. Vérifie la transaction
                               ✔ confirme  /  ✘ refuse (motif)
                            4. Assigne un livreur actif  ──▶ 5. Voit la livraison assignée
                                                             carte A/B, itinéraire, appel
                                                          6. « Colis récupéré » puis « Livré »
7. Suit le statut en temps réel
```

- **Rôles** : `client` (inscription libre dans l'app), `livreur` (compte créé par l'admin uniquement), `admin` (panneau web).
- **Marketplace** (Shopping, Agroalimentaire) : produits gérés par l'admin. Une commande crée une livraison dont le point A est l'adresse du vendeur ; le total = articles + frais de livraison.
- **Tarif** : forfait + distance estimée × prix/km (+ supplément Express), minimum configurable, arrondi à 50 F. Réglable dans *Admin › Réglages*.
- **Paiement** : numéros marchands Flooz / Mixx by Yas configurés dans *Admin › Réglages*. Une référence de transaction ne peut servir qu'une fois. Un livreur ne peut être assigné qu'après confirmation du paiement.

## Identité visuelle

Couleurs VOOM : jaune `#FFD700`, noir `#000000`, blanc. Le logo (moto stylisée formant « VOOM ») est dans :

| Fichier | Usage |
|---|---|
| `assets/images/voom_logo.svg` | Logo affiché dans l'app (splash, connexion, espace livreur) |
| `assets/images/voom_icon.png` (1024×1024) | Source des icônes Android / iOS |
| `backend/public/images/voom-logo.svg`, `voom-icon.svg` | Panneau admin et favicon |

Pour utiliser le fichier officiel de l'agence : remplacer ces fichiers (mêmes noms), puis régénérer les icônes avec `dart run flutter_launcher_icons`.

## Démarrage en local

### 1. Backend

Prérequis : PHP 8.3+, Composer.

```bash
cd backend
composer install
cp .env.example .env          # puis ajuster ADMIN_EMAIL / ADMIN_PASSWORD
php artisan key:generate
php artisan migrate --seed    # SQLite par défaut ; crée l'admin + données de démo
php artisan storage:link
php artisan serve --host=0.0.0.0 --port=8000
```

- Panneau admin : http://localhost:8000/admin (identifiants `ADMIN_EMAIL` / `ADMIN_PASSWORD` du `.env`).
- Comptes de démo (hors production) : client `client@voom.tg`, livreur `livreur@voom.tg`, mot de passe `password123`.
- Tests : `php artisan test`.

### 2. Application Flutter

Prérequis : Flutter 3.35+ ; sous Windows, activer le **Mode développeur** (requis pour les plugins).

1. Créer une clé **Google Maps** (Maps SDK for Android / iOS) dans Google Cloud Console.
2. Android : ajouter dans `android/local.properties` (non versionné) :
   ```
   MAPS_API_KEY=VOTRE_CLE
   ```
   iOS : définir la variable de build `MAPS_API_KEY` dans Xcode (utilisée par `Info.plist › GMSApiKey`).
3. Lancer :
   ```bash
   flutter pub get
   # Émulateur Android (backend sur la machine hôte) :
   flutter run
   # Téléphone réel sur le même Wi-Fi :
   flutter run --dart-define=API_BASE_URL=http://IP_DU_PC:8000/api/v1
   ```
   En build release, l'app utilise par défaut `https://voom-delivery-api.onrender.com/api/v1`.

Tests : `flutter test` · analyse : `flutter analyze`.

## Déploiement de l'API sur Render

1. Render › **New** › **Blueprint** › choisir ce dépôt : `render.yaml` crée le service web **`voom-delivery-api`** (Docker, dossier `backend/`) et la base PostgreSQL **`voom-delivery-db`**.
2. Renseigner les variables demandées : `ADMIN_EMAIL`, `ADMIN_PHONE`, `ADMIN_PASSWORD`.
3. Au démarrage, le conteneur exécute les migrations et crée/met à jour le compte admin.
4. URL de l'API : `https://voom-delivery-api.onrender.com/api/v1` · admin : `https://voom-delivery-api.onrender.com/admin`.

> ⚠️ Plan gratuit : le disque est éphémère (les captures de paiement et photos produits sont perdues au redéploiement) et la base PostgreSQL gratuite expire après 30 jours. Pour la production, passer en plan payant et activer le disque prévu (commenté) dans `render.yaml`.

## API (préfixe `/api/v1`, jeton `Authorization: Bearer …`)

| Méthode | Route | Rôle | Description |
|---|---|---|---|
| POST | `/register` | public | Inscription client |
| POST | `/login` | public | Connexion (`login` = email ou téléphone) |
| GET | `/me` · POST `/logout` | connecté | Profil · déconnexion |
| GET | `/products?category=shopping\|agro` | connecté | Marketplace |
| GET | `/payment-info` | connecté | Numéros marchands Flooz / Mixx |
| POST | `/deliveries/quote` | client | Estimation du prix |
| GET/POST | `/deliveries` | client | Mes livraisons · nouvelle demande |
| GET | `/deliveries/{id}` | client | Détail |
| POST | `/deliveries/{id}/payment` | client | Preuve de paiement (multipart, `screenshot`) |
| POST | `/deliveries/{id}/cancel` | client | Annulation (avant confirmation du paiement) |
| GET | `/courier/deliveries[?scope=history]` | livreur | Livraisons assignées |
| GET | `/courier/deliveries/{id}` | livreur | Détail + coordonnées A/B |
| POST | `/courier/deliveries/{id}/status` | livreur | `picked_up` puis `delivered` |
