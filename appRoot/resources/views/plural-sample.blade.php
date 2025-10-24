<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
<head>
    <meta charset="UTF-8">
    <title>@lang('plural-sample.title')</title>
    @vite('resources/css/app.css')
</head>
<body class="bg-gray-50 min-h-screen">
<h1 class="text-2xl font-bold text-center mt-8 mb-4">@lang('plural-sample.title')</h1>
<div class="flex justify-center items-start gap-8 mt-8">
    <div class="bg-white p-8 rounded shadow w-96">
        <div class="mb-4 text-right">
            <span class="mr-2">@lang('plural-sample.lang_select'):</span>
            <a href="{{ route('plural.lang', ['lang' => 'ja']) }}"
               class="text-blue-600 hover:underline">@lang('plural-sample.lang_ja')</a> |
            <a href="{{ route('plural.lang', ['lang' => 'en']) }}"
               class="text-blue-600 hover:underline">@lang('plural-sample.lang_en')</a>
        </div>
        <form method="POST" action="{{ route('plural.process') }}" class="space-y-4">
            @csrf
            <label for="word" class="block font-semibold mb-2">@lang('plural-sample.input_label')</label>
            <input type="text" id="word" name="word" value="{{ old('word', $word ?? '') }}" required
                   class="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-400"
                   inputmode="latin" autocomplete="off" pattern="[A-Za-z0-9]*"
                   onfocus="this.style.imeMode='disabled'" onpaste="return false;">
            <button type="submit"
                    class="w-full py-2 px-4 bg-blue-600 text-white font-bold rounded hover:bg-blue-700 transition">@lang('plural-sample.convert_button')</button>
        </form>
    </div>
    @isset($word)
        <div class="bg-white p-8 rounded shadow w-80">
            <h2 class="text-xl font-semibold mb-4 text-center">@lang('plural-sample.result_title')</h2>
            <table class="w-full border border-gray-300 rounded">
                <thead>
                <tr class="bg-gray-100">
                    <th class="py-2 px-4 border-b text-left">@lang('plural-sample.singular')</th>
                    <th class="py-2 px-4 border-b text-left">@lang('plural-sample.plural')</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td class="py-2 px-4 border-b">{{ $singular }}</td>
                    <td class="py-2 px-4 border-b">{{ $plural }}</td>
                </tr>
                </tbody>
            </table>
            <div class="mt-4 text-sm text-gray-500">@lang('plural-sample.input_value'): {{ $word }}</div>
        </div>
    @endisset
</div>
</body>
</html>
