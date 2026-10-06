<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\CourierDeliveryController;
use App\Http\Controllers\Api\DeliveryController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::middleware('throttle:10,1')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);

        Route::get('/products', [CatalogController::class, 'products']);
        Route::get('/payment-info', [CatalogController::class, 'paymentInfo']);

        Route::middleware('role:client')->group(function () {
            Route::get('/deliveries', [DeliveryController::class, 'index']);
            Route::post('/deliveries', [DeliveryController::class, 'store']);
            Route::post('/deliveries/quote', [DeliveryController::class, 'quote']);
            Route::get('/deliveries/{delivery}', [DeliveryController::class, 'show']);
            Route::post('/deliveries/{delivery}/cancel', [DeliveryController::class, 'cancel']);
            Route::post('/deliveries/{delivery}/payment', [DeliveryController::class, 'submitPayment']);
        });

        Route::middleware('role:livreur')->prefix('courier')->group(function () {
            Route::get('/deliveries', [CourierDeliveryController::class, 'index']);
            Route::get('/deliveries/{delivery}', [CourierDeliveryController::class, 'show']);
            Route::post('/deliveries/{delivery}/status', [CourierDeliveryController::class, 'updateStatus']);
        });
    });
});
