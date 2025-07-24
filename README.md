# 📱 VOOM Delivery - Application Mobile Flutter

![Flutter](https://img.shields.io/badge/Flutter-3.24.5-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Status](https://img.shields.io/badge/Status-Production%20Ready-success?style=for-the-badge)

## 🚀 Présentation

Ce dépôt contient l'application mobile Flutter pour le projet VOOM Delivery. Elle offre une interface utilisateur moderne et intuitive pour les services de livraison, shopping et agroalimentaire.

### 🎨 Design
L'application utilise une palette de couleurs jaune, blanc et noir pour une esthétique moderne et épurée.

## 🏗️ Architecture

L'application Flutter est le frontend du système VOOM Delivery. Elle communique avec un backend développé en Laravel via des APIs RESTful.

- **Lien vers le Backend Laravel** : [https://github.com/your-github-username/voom-delivery-backend](https://github.com/your-github-username/voom-delivery-backend)

## 🚀 Installation Rapide

1.  **Cloner ce dépôt** :
    ```bash
    git clone <URL_DE_CE_DEPOT>
    cd voom-delivery-app
    ```

2.  **Installer les dépendances Flutter** :
    ```bash
    flutter pub get
    ```

3.  **Configurer l'URL de l'API Backend** :
    Ouvrez `lib/services/auth_service.dart` et mettez à jour la variable `baseUrl` avec l'URL de votre API Laravel déployée :
    ```dart
    static const String baseUrl = 'http://your-backend-ip-or-domain:8000/api/v1';
    ```

4.  **Lancer l'application** :
    ```bash
    flutter run
    ```

## 📋 Fonctionnalités Principales

-   **Écran de démarrage (Splash Screen)**
-   **Authentification** : Inscription et Connexion
-   **Navigation principale** : Accueil, Shopping, Agroalimentaire, Plis & Colis, Profil
-   **Module Shopping** : Catalogue de produits, recherche, panier (à développer)
-   **Module Agroalimentaire** : Produits frais, producteurs locaux (à développer)
-   **Module Plis & Colis** : Demandes de livraison, suivi (à développer)
-   **Profil Utilisateur** : Gestion des informations, historique

## 📚 Documentation

Pour une documentation complète sur le projet (architecture, déploiement, APIs), veuillez consulter le dépôt du backend :

-   **[Documentation Complète du Projet](https://github.com/your-github-username/voom-delivery-backend/blob/main/DOCUMENTATION_FINALE.md)**
-   **[Guide de Déploiement](https://github.com/your-github-username/voom-delivery-backend/blob/main/GUIDE_DEPLOIEMENT.md)**
-   **[Cahier des Charges Original](https://github.com/your-github-username/voom-delivery-backend/blob/main/Cahier_des_Charges_VOOM_Delivery_MAJ(1).docx)**

## 👥 Équipe de Développement

Ce projet a été développé par l'équipe VOOM Delivery.

## 📄 Licence

Ce projet est développé pour VOOM Delivery. Tous droits réservés.

---

**🎉 Application VOOM Delivery - Prête pour la Production !**

*Développée avec ❤️ pour révolutionner la livraison au Togo*

