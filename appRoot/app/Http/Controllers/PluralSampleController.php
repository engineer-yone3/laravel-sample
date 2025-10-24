<?php

namespace App\Http\Controllers;

use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;

class PluralSampleController extends Controller
{
    public function showForm(Request $request): View
    {
        $lang = session('lang');
        if (!$lang) {
            $acceptLang = $request->header('Accept-Language');
            $lang = (str_starts_with($acceptLang, 'ja')) ? 'ja' : 'en';
            session(['lang' => $lang]);
        }
        App::setLocale($lang);
        return view('plural-sample');
    }

    public function process(Request $request): View
    {
        $lang = session('lang', 'ja');
        App::setLocale($lang);
        $word = $request->input('word');
        $singular = \Illuminate\Support\Str::singular($word);
        $plural = \Illuminate\Support\Str::plural($word);
        return view('plural-sample', compact('word', 'singular', 'plural'));
    }

    public function switchLang($lang): RedirectResponse
    {
        if (!in_array($lang, ['ja', 'en'])) $lang = 'ja';
        session(['lang' => $lang]);
        \Illuminate\Support\Facades\App::setLocale($lang);
        return redirect()->route('plural.form');
    }
}
