<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DeliveryController;
use App\Http\Controllers\Admin\ProductController;
use App\Http\Controllers\Admin\SettingController;
use App\Http\Controllers\Admin\UserController;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/admin');

Route::prefix('admin')->name('admin.')->group(function () {
    Route::middleware('guest')->group(function () {
        Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
        Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    });

    Route::middleware(['auth', 'role:admin'])->group(function () {
        Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

        Route::get('/', [DeliveryController::class, 'dashboard'])->name('dashboard');

        Route::get('/deliveries', [DeliveryController::class, 'index'])->name('deliveries.index');
        Route::get('/deliveries/{delivery}', [DeliveryController::class, 'show'])->name('deliveries.show');
        Route::post('/deliveries/{delivery}/assign', [DeliveryController::class, 'assign'])->name('deliveries.assign');
        Route::post('/deliveries/{delivery}/cancel', [DeliveryController::class, 'cancel'])->name('deliveries.cancel');

        Route::post('/payments/{payment}/approve', [DeliveryController::class, 'approvePayment'])->name('payments.approve');
        Route::post('/payments/{payment}/reject', [DeliveryController::class, 'rejectPayment'])->name('payments.reject');
        Route::get('/payments/{payment}/screenshot', [DeliveryController::class, 'screenshot'])->name('payments.screenshot');

        Route::get('/couriers', [UserController::class, 'couriers'])->name('couriers.index');
        Route::get('/couriers/create', [UserController::class, 'create'])->name('couriers.create');
        Route::post('/couriers', [UserController::class, 'store'])->name('couriers.store');
        Route::get('/couriers/{courier}/edit', [UserController::class, 'edit'])->name('couriers.edit');
        Route::put('/couriers/{courier}', [UserController::class, 'update'])->name('couriers.update');

        Route::get('/clients', [UserController::class, 'clients'])->name('clients.index');
        Route::post('/clients/{client}/toggle', [UserController::class, 'toggleClient'])->name('clients.toggle');

        Route::resource('products', ProductController::class)->except('show');

        Route::get('/settings', [SettingController::class, 'edit'])->name('settings.edit');
        Route::put('/settings', [SettingController::class, 'update'])->name('settings.update');
    });
});
