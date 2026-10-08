<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\Setting;
use App\Models\Subcategory;
use Illuminate\Database\Seeder;

/**
 * Structure de départ de la marketplace (exécutée une seule fois, y compris en production) :
 * 6 sous-catégories Agro renommables par l'admin, classement des produits existants, 2 packs d'exemple.
 */
class CatalogStructureSeeder extends Seeder
{
    /** Sous-catégorie => mots-clés recherchés dans le nom ou la description des produits. */
    private const AGRO = [
        'Céréales & légumineuses' => ['céréale', 'légumineuse', 'gari', 'farine', 'riz', 'maïs', 'mil', 'sorgho', 'fonio', 'haricot', 'soja', 'arachide'],
        'Légumes' => ['légume', 'tomate', 'oignon', 'piment', 'gombo', 'adémè', 'gboma', 'chou', 'carotte', 'laitue'],
        'Tubercules' => ['tubercule', 'igname', 'manioc', 'patate', 'pomme de terre'],
        'Fruits' => ['fruit', 'ananas', 'banane', 'mangue', 'papaye', 'orange', 'avocat', 'coco'],
        'Œufs, volaille & poisson' => ['œuf', 'oeuf', 'poulet', 'poisson'],
        'Huiles & transformés' => ['huile', 'miel'],
    ];

    public function run(): void
    {
        if (Setting::get('catalog_structure_seeded')) {
            return;
        }

        $position = 0;
        foreach (self::AGRO as $name => $keywords) {
            $subcategory = Subcategory::firstOrCreate(['category' => 'agro', 'name' => $name], ['position' => $position++]);

            Product::where('category', 'agro')->where('type', 'product')->whereNull('subcategory_id')->get()
                ->filter(fn (Product $p) => $this->matches($p, $keywords))
                ->each(fn (Product $p) => $p->update(['subcategory_id' => $subcategory->id]));
        }

        $this->pack('Pack sauce légumes', 'Tomate, oignon, piment et gombo pour une sauce familiale.', 3500, [
            'Tomate fraîche' => 2, 'Oignon' => 1, 'Piment frais' => 1, 'Gombo frais' => 1,
        ]);
        $this->pack('Pack céréales familial', 'Riz local, maïs et haricot pour la semaine.', 8500, [
            'Riz local étuvé' => 5, 'Maïs jaune (grain)' => 5, 'Haricot blanc (niébé)' => 2,
        ]);

        Setting::put(['catalog_structure_seeded' => '1']);
    }

    /** @param list<string> $keywords */
    private function matches(Product $product, array $keywords): bool
    {
        $text = mb_strtolower($product->name.' '.$product->description);
        foreach ($keywords as $keyword) {
            if (str_contains($text, $keyword)) {
                return true;
            }
        }

        return false;
    }

    /** @param array<string, int> $items nom du produit => quantité */
    private function pack(string $name, string $description, int $price, array $items): void
    {
        $components = Product::whereIn('name', array_keys($items))->get()->keyBy('name');
        if ($components->count() !== count($items)) {
            return; // catalogue de départ modifié par l'admin : pas de pack d'exemple
        }

        $pack = Product::firstOrCreate(['name' => $name], [
            'category' => 'agro',
            'type' => 'pack',
            'description' => $description,
            'price' => $price,
            'unit' => 'pack',
            'vendor_name' => 'VOOM Delivery',
            'pickup_address' => 'Grand Marché de Lomé (Adawlato)',
            'pickup_lat' => 6.1287,
            'pickup_lng' => 1.2238,
            'is_active' => true,
        ]);

        $pack->packItems()->sync(
            $components->mapWithKeys(fn (Product $p) => [$p->id => ['quantity' => $items[$p->name]]])->all()
        );
    }
}
