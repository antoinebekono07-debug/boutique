<?php

/**
 * Laravel - A PHP Framework For Web Artisans
 *
 * @package  Laravel
 * @author   Taylor Otwell <taylor@laravel.com>
 */

$uri = urldecode(
    parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH)
);

$requestedPath = realpath(__DIR__.$uri);
$publicPath = realpath(__DIR__.'/public');

$allowedRootFiles = array_filter([
    realpath(__DIR__.'/favicon.ico'),
    realpath(__DIR__.'/robots.txt'),
    realpath(__DIR__.'/sitemap.xml'),
]);

// This file allows us to emulate Apache's "mod_rewrite" functionality from the
// built-in PHP web server. This provides a convenient way to test a Laravel
// application without having installed a "real" web server software here.
if (
    $uri !== '/'
    && $requestedPath !== false
    && is_file($requestedPath)
    && (
        ($publicPath !== false && str_starts_with($requestedPath, $publicPath.DIRECTORY_SEPARATOR))
        || in_array($requestedPath, $allowedRootFiles, true)
    )
) {
    return false;
}

require_once __DIR__.'/index.php';
