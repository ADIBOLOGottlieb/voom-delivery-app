<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

/**
 * Image envoyée par un utilisateur (profil, articles, chat), stockée en base.
 * Servie publiquement par son UUID (non devinable) : GET /media/{uuid}.
 */
class Media extends Model
{
    protected $hidden = ['data'];

    public static function fromUpload(UploadedFile $file): self
    {
        $media = new self;
        $media->uuid = (string) Str::uuid();
        $media->mime = $file->getMimeType() ?: 'image/jpeg';
        $media->size = $file->getSize();
        $media->data = base64_encode($file->getContent());
        $media->save();

        return $media;
    }

    public function url(): string
    {
        return route('media.show', $this->uuid);
    }

    public function bytes(): string
    {
        return base64_decode($this->data);
    }
}
