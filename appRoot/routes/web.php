<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/plural-sample', [\App\Http\Controllers\PluralSampleController::class, 'showForm'])->name('plural.form');
Route::post('/plural-sample', [\App\Http\Controllers\PluralSampleController::class, 'process'])->name('plural.process');
Route::get('/plural-sample/lang/{lang}', [\App\Http\Controllers\PluralSampleController::class, 'switchLang'])->name('plural.lang');
