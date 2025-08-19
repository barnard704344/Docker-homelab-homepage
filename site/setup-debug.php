<?php
header('Content-Type: text/plain');

echo "=== Setup Debug Information ===\n";
echo "Date: " . date('Y-m-d H:i:s') . "\n\n";

// Check directory permissions
$dataDir = '/var/www/site/data';
echo "Data Directory: $dataDir\n";

if (is_dir($dataDir)) {
    echo "Directory exists: YES\n";
    echo "Directory permissions: " . substr(sprintf('%o', fileperms($dataDir)), -4) . "\n";
    echo "Directory owner: " . posix_getpwuid(fileowner($dataDir))['name'] . "\n";
    echo "Directory group: " . posix_getgrgid(filegroup($dataDir))['name'] . "\n";
    echo "Is writable: " . (is_writable($dataDir) ? 'YES' : 'NO') . "\n";
} else {
    echo "Directory exists: NO\n";
}

// Test write capability
echo "\n=== Write Tests ===\n";

$testFile = "$dataDir/test-write.txt";
if (file_put_contents($testFile, "test") !== false) {
    echo "Write test: SUCCESS\n";
    unlink($testFile);
} else {
    echo "Write test: FAILED\n";
    echo "Last error: " . (error_get_last()['message'] ?? 'No error details') . "\n";
}

// Check current user
echo "\n=== Process Information ===\n";
echo "Current user: " . posix_getpwuid(posix_geteuid())['name'] . "\n";
echo "Current group: " . posix_getgrgid(posix_getegid())['name'] . "\n";

// Check existing files
echo "\n=== Existing Data Files ===\n";
$files = ['categories.json', 'service-assignments.json', 'services.json'];
foreach ($files as $file) {
    $fullPath = "$dataDir/$file";
    if (file_exists($fullPath)) {
        echo "$file: EXISTS (" . filesize($fullPath) . " bytes)\n";
        echo "  Permissions: " . substr(sprintf('%o', fileperms($fullPath)), -4) . "\n";
        echo "  Owner: " . posix_getpwuid(fileowner($fullPath))['name'] . "\n";
        echo "  Writable: " . (is_writable($fullPath) ? 'YES' : 'NO') . "\n";
    } else {
        echo "$file: NOT EXISTS\n";
    }
}

// Test save categories function
echo "\n=== Test Category Save ===\n";
try {
    $testCategories = ['test' => 'Test Category'];
    $testFile = "$dataDir/test-categories.json";
    
    $json = json_encode($testCategories, JSON_PRETTY_PRINT);
    if (file_put_contents($testFile, $json) !== false) {
        echo "Category save test: SUCCESS\n";
        unlink($testFile);
    } else {
        echo "Category save test: FAILED\n";
    }
} catch (Exception $e) {
    echo "Category save test: ERROR - " . $e->getMessage() . "\n";
}
?>
