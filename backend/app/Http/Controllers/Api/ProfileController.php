<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Media;
use Illuminate\Http\Request;

/** Photo de profil (client et livreur). */
class ProfileController extends Controller
{
    public function updateAvatar(Request $request): UserResource
    {
        $request->validate(['photo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120']]);

        $user = $request->user();
        $previous = $user->avatar_media_id;

        $user->forceFill(['avatar_media_id' => Media::fromUpload($request->file('photo'))->id])->save();
        if ($previous) {
            Media::whereKey($previous)->delete();
        }

        return new UserResource($user->refresh());
    }

    public function deleteAvatar(Request $request): UserResource
    {
        $user = $request->user();
        $previous = $user->avatar_media_id;

        $user->forceFill(['avatar_media_id' => null])->save();
        if ($previous) {
            Media::whereKey($previous)->delete();
        }

        return new UserResource($user->refresh());
    }
}
