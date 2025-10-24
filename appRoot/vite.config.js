import {defineConfig} from 'vite';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import fs from 'fs';

// ローカル開発環境でのみSSLファイルの存在をチェック
const isLocal = process.env.NODE_ENV !== 'production' && fs.existsSync('../ssl/localhost.key') && fs.existsSync('../ssl/localhost.crt');

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
        tailwindcss(),
    ],
    server: {
        host: '0.0.0.0',
        port: 5173,
        ...(isLocal && {
            https: {
                key: fs.readFileSync('../ssl/localhost.key'),
                cert: fs.readFileSync('../ssl/localhost.crt'),
            },
        }),
        hmr: {
            host: 'localhost',
            port: 5173,
        },
        cors: true,
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
    }
});
