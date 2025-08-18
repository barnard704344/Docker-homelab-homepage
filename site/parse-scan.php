<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Manually trigger the parse-scan script
$parseScript = '/app/parse-scan.sh';

if (!file_exists($parseScript)) {
    http_response_code(500);
    echo json_encode(['error' => 'Parse script not found']);
    exit;
}

// Execute the parser
$output = [];
$returnCode = 0;
exec("$parseScript 2>&1", $output, $returnCode);

echo json_encode([
    'success' => $returnCode === 0,
    'output' => implode("\n", $output),
    'return_code' => $returnCode,
    'services_file_exists' => file_exists('/var/www/site/services.json'),
    'services_file_size' => file_exists('/var/www/site/services.json') ? filesize('/var/www/site/services.json') : 0
]);
?>
