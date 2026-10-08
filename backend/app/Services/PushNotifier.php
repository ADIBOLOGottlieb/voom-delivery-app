<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Notifications push via Firebase Cloud Messaging (API HTTP v1) — gratuit, sans carte bancaire.
 *
 * Configuration : FIREBASE_CREDENTIALS = contenu JSON du compte de service Firebase encodé en base64
 * (Console Firebase › Paramètres du projet › Comptes de service › Générer une clé privée).
 * Sans configuration, les envois sont ignorés (journalisés) et l'app fonctionne normalement.
 */
class PushNotifier
{
    public const TOPIC_CLIENTS = 'clients';

    public const TOPIC_COURIERS = 'couriers';

    /** @var array{project_id: string, client_email: string, private_key: string}|null */
    private ?array $credentials;

    public function __construct()
    {
        $raw = config('services.fcm.credentials');
        $json = $raw ? (json_decode(base64_decode($raw, true) ?: '', true) ?: json_decode($raw, true)) : null;

        $this->credentials = is_array($json) && isset($json['project_id'], $json['client_email'], $json['private_key'])
            ? $json
            : null;
    }

    public function isConfigured(): bool
    {
        return $this->credentials !== null;
    }

    /** @param array<string, string> $data */
    public function toUser(User $user, string $title, string $body, array $data = [], bool $urgent = false): bool
    {
        if (! $user->fcm_token) {
            return false;
        }

        $sent = $this->send(['token' => $user->fcm_token], $title, $body, $data, $urgent);

        if ($sent === 'unregistered') {
            $user->forceFill(['fcm_token' => null])->save();
        }

        return $sent === true;
    }

    /** @param array<string, string> $data */
    public function toTopic(string $topic, string $title, string $body, array $data = []): bool
    {
        return $this->send(['topic' => $topic], $title, $body, $data) === true;
    }

    /**
     * @param  array<string, string>  $target
     * @param  array<string, string>  $data
     */
    private function send(array $target, string $title, string $body, array $data, bool $urgent = false): bool|string
    {
        if (! $this->isConfigured()) {
            Log::info('Push non envoyé (Firebase non configuré)', compact('title'));

            return false;
        }

        $response = Http::withToken($this->accessToken())
            ->acceptJson()
            ->timeout(15)
            ->post("https://fcm.googleapis.com/v1/projects/{$this->credentials['project_id']}/messages:send", [
                'message' => [
                    ...$target,
                    'notification' => ['title' => $title, 'body' => $body],
                    'data' => array_map('strval', $data),
                    'android' => [
                        'priority' => 'high',
                        'notification' => ['channel_id' => $urgent ? 'voom_urgent' : 'voom_default', 'sound' => 'default'],
                    ],
                ],
            ]);

        if ($response->successful()) {
            return true;
        }

        $errorCode = $response->json('error.details.0.errorCode') ?? $response->json('error.status');
        Log::warning('Push FCM refusé', ['status' => $response->status(), 'error' => $errorCode]);

        return in_array($errorCode, ['UNREGISTERED', 'INVALID_ARGUMENT'], true) && isset($target['token'])
            ? 'unregistered'
            : false;
    }

    /** Jeton OAuth2 du compte de service (JWT signé RS256), mis en cache 50 minutes. */
    private function accessToken(): string
    {
        return Cache::remember('fcm_access_token', now()->addMinutes(50), function () {
            $now = time();
            $encode = fn (array $part) => rtrim(strtr(base64_encode(json_encode($part)), '+/', '-_'), '=');

            $unsigned = $encode(['alg' => 'RS256', 'typ' => 'JWT']).'.'.$encode([
                'iss' => $this->credentials['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ]);

            openssl_sign($unsigned, $signature, $this->credentials['private_key'], 'sha256WithRSAEncryption');
            $jwt = $unsigned.'.'.rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

            return (string) Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ])->throw()->json('access_token');
        });
    }
}
