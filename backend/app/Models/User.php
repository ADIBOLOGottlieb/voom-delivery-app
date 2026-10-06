<?php

namespace App\Models;

use App\Enums\Role;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'phone_number', 'password', 'role', 'is_active', 'vehicle'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'role' => Role::class,
            'is_active' => 'boolean',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === Role::Admin;
    }

    public function isCourier(): bool
    {
        return $this->role === Role::Courier;
    }

    public function isClient(): bool
    {
        return $this->role === Role::Client;
    }

    /** Livraisons demandées par ce client. */
    public function deliveries(): HasMany
    {
        return $this->hasMany(Delivery::class, 'client_id');
    }

    /** Livraisons assignées à ce livreur. */
    public function assignedDeliveries(): HasMany
    {
        return $this->hasMany(Delivery::class, 'courier_id');
    }

    public function scopeCouriers(Builder $query): Builder
    {
        return $query->where('role', Role::Courier);
    }
}
