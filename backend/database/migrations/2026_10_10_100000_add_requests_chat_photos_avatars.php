<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Photos (stockées en base : le disque Render gratuit est effacé à chaque redémarrage),
 * photos de profil, photos des articles d'une livraison, demandes rapides avec chat
 * et statut « client habitué ».
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('mime', 50);
            $table->unsignedInteger('size');
            $table->longText('data'); // contenu encodé en base64
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('avatar_media_id')->nullable()->after('vehicle')->constrained('media')->nullOnDelete();
            $table->boolean('is_regular')->default(false)->after('is_active');
        });

        Schema::create('delivery_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->constrained()->cascadeOnDelete();
            $table->foreignId('media_id')->constrained('media')->cascadeOnDelete();
            $table->timestamps();
        });

        Schema::create('delivery_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('delivery_id')->nullable()->constrained()->nullOnDelete();
            $table->string('status', 20)->default('open')->index(); // open | scheduled | closed
            $table->timestamp('last_message_at')->nullable()->index();
            // Suivi des messages lus par identifiant (plus fiable qu'une heure à la seconde près).
            $table->unsignedBigInteger('last_message_id')->nullable();
            $table->unsignedBigInteger('admin_read_id')->nullable();
            $table->unsignedBigInteger('client_read_id')->nullable();
            $table->timestamps();
        });

        Schema::create('chat_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_request_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_id')->nullable()->constrained('users')->nullOnDelete(); // null = message système
            $table->text('body')->nullable();
            $table->foreignId('media_id')->nullable()->constrained('media')->nullOnDelete();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_messages');
        Schema::dropIfExists('delivery_requests');
        Schema::dropIfExists('delivery_photos');
        Schema::table('users', function (Blueprint $t) {
            $t->dropConstrainedForeignId('avatar_media_id');
            $t->dropColumn('is_regular');
        });
        Schema::dropIfExists('media');
    }
};
