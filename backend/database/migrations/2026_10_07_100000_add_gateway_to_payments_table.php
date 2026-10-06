<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Paiements via agrégateur (KKiaPay, PayGate) en plus des preuves par capture d'écran. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->string('gateway', 20)->nullable()->after('method');
            $table->string('gateway_reference', 100)->nullable()->index()->after('gateway');
            $table->uuid('checkout_token')->nullable()->unique()->after('gateway_reference');
            $table->string('screenshot_path')->nullable()->change();
            $table->string('transaction_ref', 100)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropUnique(['checkout_token']);
            $table->dropIndex(['gateway_reference']);
            $table->dropColumn(['gateway', 'gateway_reference', 'checkout_token']);
        });
    }
};
