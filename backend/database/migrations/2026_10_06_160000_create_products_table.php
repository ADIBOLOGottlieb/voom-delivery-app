<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('category', 20)->index(); // shopping | agro
            $table->string('name');
            $table->text('description')->nullable();
            $table->unsignedInteger('price'); // FCFA
            $table->string('unit', 30)->nullable();
            $table->string('image_path')->nullable();
            $table->string('vendor_name')->nullable();
            $table->string('pickup_address');
            $table->decimal('pickup_lat', 10, 7);
            $table->decimal('pickup_lng', 10, 7);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
