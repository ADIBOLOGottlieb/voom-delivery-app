@extends('layouts.public')

@section('title', 'Politique de confidentialité')

@section('content')
    <h1>Politique de confidentialité</h1>
    <p class="muted">Application mobile et service VOOM Delivery · dernière mise à jour : 17 novembre 2026</p>

    <h2>Responsable du traitement</h2>
    <p><strong>VOOM Delivery</strong>, agence de livraison à Lomé, Togo. Pour toute question sur vos données :</p>
    @include('legal._contact')

    <h2>Données collectées</h2>
    <ul>
        <li><strong>Compte</strong> : nom, numéro de téléphone, email (facultatif), quartier, mot de passe (stocké chiffré, jamais lisible).</li>
        <li><strong>Livraisons</strong> : adresses et positions GPS de retrait et de livraison, nom et numéro du destinataire,
            description du colis, instructions, horaires souhaités.</li>
        <li><strong>Photos</strong> : photos des colis et des articles envoyées dans l'application ou la discussion avec l'agence,
            et votre photo de profil (facultative).</li>
        <li><strong>Paiements</strong> : moyen (Flooz, Mixx by Yas), référence de transaction, numéro payeur, montant
            et capture d'écran de la transaction.</li>
        <li><strong>Messages</strong> : contenu de la discussion avec l'agence (texte, photos, position partagée).</li>
        <li><strong>Notifications</strong> : jeton de notification de votre téléphone (Firebase Cloud Messaging).</li>
        <li><strong>Localisation des livreurs</strong> : pendant toute la connexion à l’espace livreur, la position GPS est transmise périodiquement à l’agence afin qu’elle puisse suivre les livreurs actifs. Le partage s’arrête à la déconnexion ; les positions de plus de deux minutes ne sont plus affichées comme actives.</li>
        <li><strong>Remise et avis</strong> : signature du destinataire lors de la confirmation de remise du colis, note et commentaire facultatif du client après la livraison.</li>
    </ul>
    <p>Nous ne collectons pas vos contacts. Le suivi de position en arrière-plan concerne uniquement les livreurs connectés qui ont autorisé l’accès à la localisation.</p>

    <h2>Pourquoi nous les utilisons</h2>
    <ul>
        <li>Créer votre compte et vous connecter.</li>
        <li>Calculer le prix, organiser et suivre vos livraisons.</li>
        <li>Vérifier vos paiements et éviter qu'une même transaction serve deux fois.</li>
        <li>Vous prévenir de l'avancement de vos livraisons et, si vous l'acceptez, des promotions.</li>
        <li>Vous envoyer un code par email si vous oubliez votre mot de passe.</li>
        <li>Permettre à l’agence de suivre les livreurs connectés et de vérifier la remise d’un colis.</li>
        <li>Respecter nos obligations comptables.</li>
    </ul>

    <h2>Avec qui elles sont partagées</h2>
    <ul>
        <li><strong>Le livreur</strong> chargé de votre course voit ce qui lui est nécessaire : adresses, positions, noms et numéros
            de l'expéditeur et du destinataire, photos du colis.</li>
        <li><strong>Nos prestataires techniques</strong>, uniquement pour faire fonctionner le service : hébergement (Render),
            notifications (Google Firebase), envoi d'emails (service SMTP).</li>
    </ul>
    <p>Vos données ne sont <strong>jamais vendues</strong> ni utilisées pour de la publicité ciblée.</p>

    <h2>Hébergement et sécurité</h2>
    <p>Le serveur et la base de données sont hébergés par Render (centre de données de Francfort, Union européenne).
        Les échanges entre l'application et le serveur sont chiffrés (HTTPS). Les captures de paiement ne sont visibles
        que par l'agence.</p>

    <h2>Durée de conservation</h2>
    <ul>
        <li>Compte : tant qu'il est actif ; supprimé (anonymisé) dès que vous le demandez.</li>
        <li>Historique des livraisons et des paiements : jusqu'à 10 ans (obligations comptables), sans lien avec votre identité après suppression du compte.</li>
        <li>Code de mot de passe oublié : 15 minutes.</li>
    </ul>

    <h2>Vos droits</h2>
    <p>Vous pouvez à tout moment :</p>
    <ul>
        <li><strong>accéder</strong> à vos données et les <strong>rectifier</strong> : dans l'application (Profil) ou en contactant l'agence ;</li>
        <li><strong>supprimer</strong> votre compte : dans l'application (Profil › Supprimer mon compte) ou en suivant
            <a href="{{ route('legal.account-deletion') }}">cette page</a> ;</li>
        <li>refuser les notifications, dans les réglages de votre téléphone.</li>
    </ul>
    <p>Vous pouvez aussi saisir l'Instance de protection des données à caractère personnel (IPDCP) du Togo.</p>

    <h2>Enfants</h2>
    <p>Le service s'adresse aux personnes majeures ; nous ne collectons pas sciemment de données sur des mineurs.</p>

    <h2>Modifications</h2>
    <p>Cette politique peut évoluer ; la date de mise à jour figure en haut de cette page.</p>

    <p><a class="btn" href="{{ route('legal.account-deletion') }}">Supprimer mon compte</a></p>
@endsection
