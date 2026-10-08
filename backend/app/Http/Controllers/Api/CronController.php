<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DeliveryReminder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Tâches périodiques déclenchées par un appel HTTP (Render gratuit n'a pas de planificateur).
 * Appelé toutes les 10 min par le workflow GitHub « keep-alive » ou cron-job.org,
 * avec l'en-tête X-Cron-Key = CRON_SECRET.
 */
class CronController extends Controller
{
    public function __invoke(Request $request, DeliveryReminder $reminder): JsonResponse
    {
        $secret = (string) config('services.cron.secret');
        abort_if($secret === '' || ! hash_equals($secret, (string) $request->header('X-Cron-Key')), 403);

        return response()->json(['reminders_sent' => $reminder->sendDueReminders()]);
    }
}
