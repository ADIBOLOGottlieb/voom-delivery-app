<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Rappels push aux livreurs pour les livraisons urgentes (Express ou heure limite proche).
// En production, déclenché toutes les 10 min via POST /api/v1/cron/run (voir CronController).
Artisan::command('deliveries:remind', function (App\Services\DeliveryReminder $reminder) {
    $this->info($reminder->sendDueReminders().' rappel(s) envoyé(s).');
})->purpose('Rappeler aux livreurs les livraisons urgentes');
