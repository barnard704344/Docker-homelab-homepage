<?php
header('Content-Type: application/json');

// Simple endpoint to trigger a network scan
$response = array();

try {
    // Execute the scan script
    $command = '/usr/local/bin/scan.sh 2>&1';
    $output = array();
    $return_code = 0;
    
    exec($command, $output, $return_code);
    
    if ($return_code === 0) {
        $response['status'] = 'success';
        $response['message'] = 'Scan completed successfully';
        $response['output'] = implode("\n", $output);
    } else {
        $response['status'] = 'error';
        $response['message'] = 'Scan failed';
        $response['output'] = implode("\n", $output);
        $response['return_code'] = $return_code;
    }
    
} catch (Exception $e) {
    $response['status'] = 'error';
    $response['message'] = 'Failed to execute scan: ' . $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT);
?>
