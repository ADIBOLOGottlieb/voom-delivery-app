<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** Sous-catégorie de la marketplace (onglets verticaux de l'écran Agroalimentaire). */
#[Fillable(['category', 'name', 'position'])]
class Subcategory extends Model
{
    protected function casts(): array
    {
        return ['position' => 'integer'];
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }
}
