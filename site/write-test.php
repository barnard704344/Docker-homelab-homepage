<?php
header('Content-Type: text/plain');

echo "=== PHP Write Test ===\n";
echo "Date: " . date('Y-m-d H:i:s') . "\n\n";

$testDir = '/var/www/site/data';
$testFile = "$testDir/php-write-test.txt";

echo "Test directory: $testDir\n";

// Check if directory exists
if (is_dir($testDir)) {
    echo "Directory exists: YES\n";
    
    // Check permissions from PHP perspective
    $perms = substr(sprintf('%o', fileperms($testDir)), -4);
    echo "Directory permissions: $perms\n";
    
    // Check ownership
    if (function_exists('posix_getpwuid')) {
        $owner = posix_getpwuid(fileowner($testDir));
        $group = posix_getgrgid(filegroup($testDir));
        echo "Directory owner: " . ($owner['name'] ?? 'unknown') . "\n";
        echo "Directory group: " . ($group['name'] ?? 'unknown') . "\n";
    }
    
    // Check if writable
    echo "Is writable: " . (is_writable($testDir) ? 'YES' : 'NO') . "\n";
    
    // Test actual write
    echo "\n=== Write Test ===\n";
    $success = file_put_contents($testFile, "PHP write test at " . date('Y-m-d H:i:s'));
    
    if ($success !== false) {
        echo "Write test: SUCCESS ($success bytes written)\n";
        if (file_exists($testFile)) {
            echo "File exists after write: YES\n";
            echo "File contents: " . file_get_contents($testFile) . "\n";
            unlink($testFile); // Clean up
        }
    } else {
        echo "Write test: FAILED\n";
        $error = error_get_last();
        echo "Error: " . ($error['message'] ?? 'No error details') . "\n";
    }
    
} else {
    echo "Directory exists: NO\n";
}

// Check current PHP user
echo "\n=== PHP Process Info ===\n";
if (function_exists('posix_geteuid')) {
    $uid = posix_geteuid();
    $gid = posix_getegid();
    $user = posix_getpwuid($uid);
    $group = posix_getgrgid($gid);
    echo "PHP running as user: " . ($user['name'] ?? 'unknown') . " (UID: $uid)\n";
    echo "PHP running as group: " . ($group['name'] ?? 'unknown') . " (GID: $gid)\n";
} else {
    echo "POSIX functions not available\n";
}

// Test writing to /tmp for comparison
echo "\n=== /tmp Write Test (comparison) ===\n";
$tmpFile = '/tmp/php-write-test.txt';
$tmpSuccess = file_put_contents($tmpFile, "PHP tmp test");
echo "/tmp write test: " . ($tmpSuccess !== false ? "SUCCESS ($tmpSuccess bytes)" : "FAILED") . "\n";
if ($tmpSuccess !== false) {
    unlink($tmpFile);
}
?>
