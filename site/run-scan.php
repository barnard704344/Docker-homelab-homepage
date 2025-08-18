<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Path to the scan script
$scanScript = '/opt/scan.sh';

// Check if scan script exists
if (!file_exists($scanScript)) {
    http_response_code(500);
    echo json_encode(['error' => 'Scan script not found']);
    exit;
}

// Execute the scan script in the background
// The scan script will automatically run the parser when complete
$command = "nohup $scanScript > /dev/null 2>&1 &";
$result = shell_exec($command);

// Return success response
echo json_encode([
    'status' => 'started',
    'message' => 'Network scan has been initiated - services will be auto-discovered',
    'timestamp' => date('c')
]);
?>
