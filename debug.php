<?php
header('Content-Type: application/json');

$debug_info = array();
$debug_info['timestamp'] = date('Y-m-d H:i:s');
$debug_info['server_ip'] = $_SERVER['SERVER_ADDR'] ?? 'unknown';

// Check scan file
$scan_file = '/var/www/site/scan/last-scan.txt';
$debug_info['scan_file'] = array(
    'path' => $scan_file,
    'exists' => file_exists($scan_file),
    'size' => file_exists($scan_file) ? filesize($scan_file) : 0,
    'readable' => file_exists($scan_file) ? is_readable($scan_file) : false
);

// Check services file  
$services_file = '/var/www/site/services.json';
$debug_info['services_file'] = array(
    'path' => $services_file,
    'exists' => file_exists($services_file),
    'size' => file_exists($services_file) ? filesize($services_file) : 0,
    'readable' => file_exists($services_file) ? is_readable($services_file) : false
);

if (file_exists($services_file) && is_readable($services_file)) {
    $services_content = file_get_contents($services_file);
    $debug_info['services_file']['content_preview'] = substr($services_content, 0, 500);
    
    $services_data = json_decode($services_content, true);
    if (json_last_error() === JSON_ERROR_NONE) {
        $debug_info['services_file']['valid_json'] = true;
        $debug_info['services_file']['service_count'] = count($services_data);
    } else {
        $debug_info['services_file']['valid_json'] = false;
        $debug_info['services_file']['json_error'] = json_last_error_msg();
    }
}

// Check directory permissions
$debug_info['directories'] = array();
$dirs_to_check = array('/var/www/site', '/var/www/site/scan');
foreach ($dirs_to_check as $dir) {
    $debug_info['directories'][$dir] = array(
        'exists' => is_dir($dir),
        'writable' => is_writable($dir),
        'permissions' => is_dir($dir) ? substr(sprintf('%o', fileperms($dir)), -4) : 'n/a'
    );
}

// Check if scripts exist
$scripts = array(
    '/usr/local/bin/scan.sh',
    '/usr/local/bin/parse-scan.sh',
    '/usr/local/bin/debug-parser.sh'
);

$debug_info['scripts'] = array();
foreach ($scripts as $script) {
    $debug_info['scripts'][basename($script)] = array(
        'path' => $script,
        'exists' => file_exists($script),
        'executable' => file_exists($script) ? is_executable($script) : false
    );
}

echo json_encode($debug_info, JSON_PRETTY_PRINT);
?>
