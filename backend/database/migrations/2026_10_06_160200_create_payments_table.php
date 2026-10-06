<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->constrained()->cascadeOnDelete();
            $table->string('method', 20); // flooz | mixx
            $table->string('transaction_ref', 100);
            $table->string('payer_phone', 30);
            $table->unsignedInteger('amount');
            $table->string('screenshot_path');
            $table->string('status', 20)->default('submitted')->index();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->string('rejection_reason')->nullable();
            $table->timestamps();

            $table->index(['method', 'transaction_ref']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
