<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            $table->foreignId('signature_media_id')->nullable()->constrained('media')->nullOnDelete();
            $table->timestamp('signed_at')->nullable();
            $table->text('courier_note')->nullable();
            $table->string('cancellation_actor', 20)->nullable()->index();
            $table->foreignId('reprogrammed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reprogrammed_at')->nullable();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->decimal('last_lat', 10, 7)->nullable();
            $table->decimal('last_lng', 10, 7)->nullable();
            $table->timestamp('location_updated_at')->nullable()->index();
        });

        Schema::table('products', function (Blueprint $table) {
            $table->foreignId('video_media_id')->nullable()->constrained('media')->nullOnDelete();
        });

        Schema::create('courier_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('courier_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();
            $table->timestamps();
            $table->index(['courier_id', 'created_at']);
        });

        Schema::create('expenses', function (Blueprint $table) {
            $table->id();
            $table->string('reason', 255);
            $table->date('spent_on')->index();
            $table->string('recipient', 255);
            $table->unsignedInteger('amount');
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('delivery_cancellation_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->constrained()->cascadeOnDelete();
            $table->foreignId('courier_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('actor', 20)->index();
            $table->string('reason', 255);
            $table->timestamp('cancelled_at')->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expenses');
        Schema::dropIfExists('delivery_cancellation_events');
        Schema::dropIfExists('courier_reviews');
        Schema::table('products', fn (Blueprint $table) => $table->dropConstrainedForeignId('video_media_id'));
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn(['last_lat', 'last_lng', 'location_updated_at']));
        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropConstrainedForeignId('signature_media_id');
            $table->dropConstrainedForeignId('reprogrammed_by');
            $table->dropColumn(['signed_at', 'courier_note', 'cancellation_actor', 'reprogrammed_at']);
        });
    }
};
