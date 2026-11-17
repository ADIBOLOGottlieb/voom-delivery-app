<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['reason', 'spent_on', 'recipient', 'amount', 'created_by'])]
class Expense extends Model
{
    protected function casts(): array { return ['spent_on' => 'date', 'amount' => 'integer']; }
}
