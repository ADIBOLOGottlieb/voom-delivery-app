<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Sous-catégories (onglets Agro), packs, annonces promo, heure limite de livraison
 * et jeton de notification push.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subcategories', function (Blueprint $table) {
            $table->id();
            $table->string('category', 20)->index(); // shopping | agro
            $table->string('name', 60);
            $table->unsignedSmallInteger('position')->default(0);
            $table->timestamps();
        });

        Schema::table('products', function (Blueprint $table) {
            $table->foreignId('subcategory_id')->nullable()->after('category')->constrained()->nullOnDelete();
            $table->string('type', 10)->default('product')->after('subcategory_id')->index(); // product | pack
        });

        Schema::create('pack_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pack_id')->constrained('products')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->unsignedSmallInteger('quantity')->default(1);
            $table->unique(['pack_id', 'product_id']);
        });

        Schema::create('promotions', function (Blueprint $table) {
            $table->id();
            $table->string('title', 80);
            $table->string('body', 255);
            $table->string('image_path')->nullable();
            $table->foreignId('product_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('pushed_at')->nullable();
            $table->timestamps();
        });

        Schema::table('deliveries', function (Blueprint $table) {
            $table->timestamp('deadline_at')->nullable()->after('scheduled_at')->index();
            $table->timestamp('last_reminder_at')->nullable()->after('deadline_at');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('fcm_token')->nullable()->after('vehicle');
        });
    }

    public function down(): void
    {
        Schema::table('users', fn (Blueprint $t) => $t->dropColumn('fcm_token'));
        Schema::table('deliveries', function (Blueprint $t) {
            $t->dropIndex(['deadline_at']);
            $t->dropColumn(['deadline_at', 'last_reminder_at']);
        });
        Schema::dropIfExists('promotions');
        Schema::dropIfExists('pack_items');
        Schema::table('products', function (Blueprint $t) {
            $t->dropConstrainedForeignId('subcategory_id');
            $t->dropIndex(['type']);
            $t->dropColumn('type');
        });
        Schema::dropIfExists('subcategories');
    }
};
