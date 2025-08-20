<?php
header('Content-Type: text/plain');

echo "=== Setup Debug Information ===\n";
echo "Date: " . date('Y-m-d H:i:s') . "\n\n";

// Check multiple possible data directories
$possibleDirs = [
    '/var/www/site/data',
    '/var/www/site/data/writable',
    '/tmp/homepage-data'
];

echo "=== Available Data Directories ===\n";
$writableDir = null;
foreach ($possibleDirs as $dir) {
    echo "Directory: $dir\n";
    if (is_dir($dir)) {
        echo "  Exists: YES\n";
        echo "  Permissions: " . substr(sprintf('%o', fileperms($dir)), -4) . "\n";
        echo "  Owner: " . posix_getpwuid(fileowner($dir))['name'] . "\n";
        echo "  Group: " . posix_getgrgid(filegroup($dir))['name'] . "\n";
        echo "  Writable: " . (is_writable($dir) ? 'YES' : 'NO') . "\n";
        
        if (is_writable($dir) && !$writableDir) {
            $writableDir = $dir;
            echo "  *** SELECTED FOR USE ***\n";
        }
    } else {
        echo "  Exists: NO\n";
    }
    echo "\n";
}

if (!$writableDir) {
    echo "❌ NO WRITABLE DIRECTORY FOUND\n";
} else {
    echo "✅ Using directory: $writableDir\n";
}

// Check current user
echo "\n=== Process Information ===\n";
echo "Current user: " . posix_getpwuid(posix_geteuid())['name'] . "\n";
echo "Current group: " . posix_getgrgid(posix_getegid())['name'] . "\n";

// Test write capability on selected directory
if ($writableDir) {
    echo "\n=== Write Tests ===\n";
    $testFile = "$writableDir/test-write.txt";
    if (file_put_contents($testFile, "test") !== false) {
        echo "Write test: SUCCESS\n";
        unlink($testFile);
    } else {
        echo "Write test: FAILED\n";
        echo "Last error: " . (error_get_last()['message'] ?? 'No error details') . "\n";
    }

    // Check existing files
    echo "\n=== Existing Data Files ===\n";
    $files = ['categories.json', 'service-assignments.json', 'services.json'];
    foreach ($files as $file) {
        $fullPath = "$writableDir/$file";
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
        $testFile = "$writableDir/test-categories.json";
        
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
}
?>
