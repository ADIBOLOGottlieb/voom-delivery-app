<?php

namespace Database\Seeders;

use App\Enums\Role;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        if (app()->isProduction() && ! env('ADMIN_PASSWORD')) {
            $this->command?->warn('ADMIN_PASSWORD non défini : compte admin non créé.');

            return;
        }

        User::updateOrCreate(['email' => env('ADMIN_EMAIL', 'admin@voom.tg')], [
            'name' => 'Administrateur VOOM',
            'phone_number' => env('ADMIN_PHONE', '+22890000000'),
            'password' => env('ADMIN_PASSWORD', 'ChangeMoi2026!'),
            'role' => Role::Admin,
            'is_active' => true,
        ]);

        if (! app()->isProduction()) {
            $this->seedDemoData();
        }
    }

    private function seedDemoData(): void
    {
        User::updateOrCreate(['phone_number' => '+22891000001'], [
            'name' => 'Kossi Livreur (démo)',
            'email' => 'livreur@voom.tg',
            'password' => 'password123',
            'role' => Role::Courier,
            'vehicle' => 'Moto · TG-0001-AA',
            'is_active' => true,
        ]);

        User::updateOrCreate(['phone_number' => '+22892000001'], [
            'name' => 'Ama Cliente (démo)',
            'email' => 'client@voom.tg',
            'password' => 'password123',
            'role' => Role::Client,
            'is_active' => true,
        ]);

        $products = [
            ['shopping', 'Pagne wax 6 yards', 15000, 'pièce', 'Boutique Grand Marché', 'Grand Marché de Lomé', 6.1300, 1.2250],
            ['shopping', 'Sac à main en cuir', 12000, 'pièce', 'Boutique Grand Marché', 'Grand Marché de Lomé', 6.1300, 1.2250],
            ['agro', 'Tomates fraîches', 800, 'kg', "Marché d'Adawlato", "Marché d'Adawlato, Lomé", 6.1287, 1.2238],
            ['agro', 'Gari de manioc', 600, 'kg', 'Coopérative Agoè', 'Agoè-Nyivé, Lomé', 6.2000, 1.2100],
            ['agro', 'Ananas', 500, 'pièce', 'Coopérative Agoè', 'Agoè-Nyivé, Lomé', 6.2000, 1.2100],
        ];

        foreach ($products as [$category, $name, $price, $unit, $vendor, $address, $lat, $lng]) {
            Product::updateOrCreate(['name' => $name], [
                'category' => $category,
                'price' => $price,
                'unit' => $unit,
                'vendor_name' => $vendor,
                'pickup_address' => $address,
                'pickup_lat' => $lat,
                'pickup_lng' => $lng,
                'is_active' => true,
            ]);
        }
    }
}
