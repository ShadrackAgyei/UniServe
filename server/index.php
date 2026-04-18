<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/middleware/auth.php';

$database = new Database();
$db = $database->getConnection();

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri = rtrim($uri, '/');
// Remove base path if deployed in a subdirectory
$basePath = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
if ($basePath && strpos($uri, $basePath) === 0) {
    $uri = substr($uri, strlen($basePath));
}
$method = $_SERVER['REQUEST_METHOD'];

// Route matching
$routes = [
    'POST /api/register' => ['AuthController', 'register'],
    'POST /api/login' => ['AuthController', 'login'],
    'GET /api/profile' => ['ProfileController', 'get'],
    'PUT /api/profile' => ['ProfileController', 'update'],
    'POST /api/profile/photo' => ['ProfileController', 'uploadPhoto'],
    'GET /api/issues' => ['IssuesController', 'list'],
    'POST /api/issues' => ['IssuesController', 'create'],
    'GET /api/lost-found' => ['LostFoundController', 'list'],
    'POST /api/lost-found' => ['LostFoundController', 'create'],
    'GET /api/notifications' => ['NotificationsController', 'list'],
    'GET /api/emergency-contacts' => ['EmergencyController', 'list'],
    'GET /api/sync' => ['SyncController', 'sync'],
];

$routeKey = "$method $uri";
$params = [];

// Check for parameterized routes
if (preg_match('#^/api/issues/(\d+)$#', $uri, $m) && $method === 'PUT') {
    $routeKey = 'PUT /api/issues/:id';
    $routes[$routeKey] = ['IssuesController', 'updateStatus'];
    $params['id'] = $m[1];
} elseif (preg_match('#^/api/lost-found/(\d+)$#', $uri, $m)) {
    if ($method === 'PUT') {
        $routeKey = 'PUT /api/lost-found/:id';
        $routes[$routeKey] = ['LostFoundController', 'resolve'];
        $params['id'] = $m[1];
    } elseif ($method === 'DELETE') {
        $routeKey = 'DELETE /api/lost-found/:id';
        $routes[$routeKey] = ['LostFoundController', 'delete'];
        $params['id'] = $m[1];
    }
} elseif (preg_match('#^/api/notifications/(\d+)/read$#', $uri, $m) && $method === 'POST') {
    $routeKey = 'POST /api/notifications/:id/read';
    $routes[$routeKey] = ['NotificationsController', 'markRead'];
    $params['id'] = $m[1];
}

if (!isset($routes[$routeKey])) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Route not found']);
    exit;
}

[$controllerName, $action] = $routes[$routeKey];
require_once __DIR__ . "/controllers/$controllerName.php";
$controller = new $controllerName($db);

// Auth-required routes (everything except register and login)
$publicRoutes = ['POST /api/register', 'POST /api/login', 'GET /api/emergency-contacts'];
$user = null;
if (!in_array($routeKey, $publicRoutes)) {
    $user = authenticate($db);
}

$controller->$action($user, $params);
