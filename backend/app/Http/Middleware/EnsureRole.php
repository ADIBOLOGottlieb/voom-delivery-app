<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Restreint une route à un ou plusieurs rôles : ->middleware('role:livreur').
 * Refuse aussi les comptes désactivés par l'admin.
 */
class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user || ! $user->is_active) {
            abort(403, 'Compte inactif ou non authentifié.');
        }

        if (! in_array($user->role->value, $roles, true)) {
            abort(403, 'Accès non autorisé pour ce type de compte.');
        }

        return $next($request);
    }
}
