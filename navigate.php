<?php
// =======================
// navigate.php for Render
// =======================

$log = function ($msg) {
    file_put_contents(__DIR__ . "/debug_log.txt", "[" . date("Y-m-d H:i:s") . "] $msg\n", FILE_APPEND);
};

// ✅ Require stealth cookie
if (!isset($_COOKIE['stealth_access']) || $_COOKIE['stealth_access'] !== 'valid') {
    http_response_code(403);
    exit("Access Denied");
}

// ✅ Clean virtual path
$request = $_SERVER['REQUEST_URI'];
$virtualPath = parse_url($request, PHP_URL_PATH);

// ✅ If base call to /navigate.php or /navigate.php/
if (preg_match("#^/navigate\.php/?$#", $virtualPath)) {
    if (file_exists(__DIR__ . "/cache_site/index.html")) {
        $log("🧭 Redirecting to cache_site/index.html");
        header("Location: /cache_site/index.html");
    } elseif (file_exists(__DIR__ . "/cache_site/index.php")) {
        $log("🧭 Redirecting to cache_site/index.php");
        header("Location: /cache_site/index.php");
    } else {
        $log("❌ No index file to redirect to.");
        http_response_code(404);
        exit("404 Not Found");
    }
    exit;
}

// ✅ Otherwise serve file inside cache_site
$relativePath = str_replace("/navigate.php", "", $virtualPath);
$relativePath = ltrim($relativePath, "/");
$base = __DIR__ . "/cache_site";
$targetPath = realpath($base . "/" . $relativePath);

$log("Requested URI: $request");
$log("Resolved virtual path: $relativePath");
$log("Resolved physical path: $targetPath");

// ✅ Directory check — serve index fallback
if (!$relativePath || is_dir($targetPath)) {
    if (file_exists("$base/index.html")) {
        $targetPath = "$base/index.html";
    } elseif (file_exists("$base/index.php")) {
        $targetPath = "$base/index.php";
    } else {
        $log("❌ No index file found in directory.");
        http_response_code(404);
        exit("404 Not Found");
    }
}

// ✅ Security check — prevent path traversal
if (!file_exists($targetPath) || strpos(realpath($targetPath), realpath($base)) !== 0) {
    $log("❌ File not found or invalid access.");
    http_response_code(404);
    exit("404 Not Found");
}

// ✅ Set Content-Type
$ext = strtolower(pathinfo($targetPath, PATHINFO_EXTENSION));
$mimeTypes = [
    'html' => 'text/html',
    'php'  => 'text/html',
    'css'  => 'text/css',
    'js'   => 'application/javascript',
    'json' => 'application/json',
    'png'  => 'image/png',
    'jpg'  => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'gif'  => 'image/gif',
    'svg'  => 'image/svg+xml',
    'txt'  => 'text/plain',
];
header("Content-Type: " . ($mimeTypes[$ext] ?? 'application/octet-stream'));

// ✅ Serve file
readfile($targetPath);
exit;
?>
