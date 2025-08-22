<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Path to the progress file
$progressFile = '/var/www/site/data/scan-progress.json';

// Check if progress file exists
if (!file_exists($progressFile)) {
    echo json_encode([
        'status' => 'idle',
        'progress' => 0,
        'message' => 'No scan in progress',
        'timestamp' => date('c')
    ]);
    exit;
}

// Read progress data
$progressData = file_get_contents($progressFile);
if ($progressData === false) {
    echo json_encode([
        'status' => 'error',
        'progress' => 0,
        'message' => 'Could not read progress file',
        'timestamp' => date('c')
    ]);
    exit;
}

// Parse JSON and validate
$progress = json_decode($progressData, true);
if ($progress === null) {
    echo json_encode([
        'status' => 'error',
        'progress' => 0,
        'message' => 'Invalid progress data',
        'timestamp' => date('c')
    ]);
    exit;
}

// Check if progress is stale (older than 5 minutes)
if (isset($progress['timestamp'])) {
    $progressTime = strtotime($progress['timestamp']);
    $currentTime = time();
    if ($currentTime - $progressTime > 300) { // 5 minutes
        echo json_encode([
            'status' => 'idle',
            'progress' => 0,
            'message' => 'No recent scan activity',
            'timestamp' => date('c')
        ]);
        exit;
    }
}

// Return progress data
echo json_encode($progress);
?>
