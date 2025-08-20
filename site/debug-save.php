<?php
header('Content-Type: application/json');

$dataDir = '/var/www/site/data';
$assignmentsFile = '/var/www/site/data/service-assignments.json';

// Test data
$testData = ["Test Service" => "network"];

echo "=== Debug Save Test ===\n";
echo "Data directory: $dataDir\n";
echo "Target file: $assignmentsFile\n";
echo "Directory exists: " . (is_dir($dataDir) ? 'YES' : 'NO') . "\n";
echo "Directory writable: " . (is_writable($dataDir) ? 'YES' : 'NO') . "\n";

if (file_exists($assignmentsFile)) {
    echo "File exists: YES\n";
    echo "File writable: " . (is_writable($assignmentsFile) ? 'YES' : 'NO') . "\n";
    echo "Current contents: " . file_get_contents($assignmentsFile) . "\n";
} else {
    echo "File exists: NO\n";
}

// Try to save
$json = json_encode($testData, JSON_PRETTY_PRINT);
echo "\nAttempting to save: $json\n";

$result = file_put_contents($assignmentsFile, $json, LOCK_EX);
if ($result !== false) {
    echo "Write result: SUCCESS ($result bytes)\n";
    
    // Check if file exists and read it back
    if (file_exists($assignmentsFile)) {
        echo "File exists after write: YES\n";
        echo "File contents: " . file_get_contents($assignmentsFile) . "\n";
    } else {
        echo "File exists after write: NO\n";
    }
} else {
    echo "Write result: FAILED\n";
    $error = error_get_last();
    echo "Last error: " . ($error['message'] ?? 'none') . "\n";
}
?>
