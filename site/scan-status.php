<?php
header('Content-Type: text/plain');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

// Check if scan process is running
$processes = shell_exec('ps aux | grep -E "(nmap|scan\.sh)" | grep -v grep');

if (!empty($processes) && strpos($processes, 'nmap') !== false) {
    echo 'running';
} else {
    echo 'idle';
}
?>
