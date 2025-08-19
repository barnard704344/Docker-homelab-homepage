<?php
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

// Ensure data directory exists
$dataDir = '/var/www/site/data';
if (!is_dir($dataDir)) {
    mkdir($dataDir, 0755, true);
}

$portSelectionsFile = $dataDir . '/port-selections.json';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Handle sync request
    $input = json_decode(file_get_contents('php://input'), true);
    
    if ($input && isset($input['action']) && $input['action'] === 'sync') {
        $selections = $input['selections'] ?? [];
        
        // Save to file
        if (file_put_contents($portSelectionsFile, json_encode($selections, JSON_PRETTY_PRINT)) !== false) {
            echo json_encode(['success' => true]);
        } else {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to save port selections']);
        }
    } else {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid request']);
    }
} else {
    // Handle GET request - return stored port selections
    if (file_exists($portSelectionsFile)) {
        $content = file_get_contents($portSelectionsFile);
        $selections = json_decode($content, true);
        
        if ($selections !== null) {
            echo json_encode($selections);
        } else {
            echo json_encode([]);
        }
    } else {
        echo json_encode([]);
    }
}
?>
