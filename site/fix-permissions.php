<?php
header('Content-Type: application/json');

$response = ['status' => 'starting', 'actions' => []];

try {
    $dataDir = '/var/www/site/data';
    
    // Check if directory exists
    if (!is_dir($dataDir)) {
        mkdir($dataDir, 0777, true);
        $response['actions'][] = "Created directory: $dataDir";
    }
    
    // Try to change permissions
    if (chmod($dataDir, 0777)) {
        $response['actions'][] = "Changed directory permissions to 0777";
    } else {
        $response['actions'][] = "Failed to change directory permissions";
    }
    
    // Try to change ownership (this might fail in some containers)
    $currentUser = posix_getpwuid(posix_geteuid());
    if ($currentUser && chown($dataDir, $currentUser['name'])) {
        $response['actions'][] = "Changed directory owner to: " . $currentUser['name'];
    } else {
        $response['actions'][] = "Could not change directory owner";
    }
    
    // Check final permissions
    $perms = substr(sprintf('%o', fileperms($dataDir)), -4);
    $response['final_permissions'] = $perms;
    $response['writable'] = is_writable($dataDir);
    
    // Test write
    $testFile = "$dataDir/test-write.txt";
    if (file_put_contents($testFile, "test") !== false) {
        unlink($testFile);
        $response['write_test'] = 'SUCCESS';
        $response['status'] = 'success';
    } else {
        $response['write_test'] = 'FAILED';
        $response['status'] = 'failed';
    }
    
} catch (Exception $e) {
    $response['status'] = 'error';
    $response['error'] = $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT);
?>
