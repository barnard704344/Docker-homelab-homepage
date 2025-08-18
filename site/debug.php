<?php
header('Content-Type: application/json');

$servicesFile = '/var/www/site/services.json';
$scanFile = '/var/www/site/scan/last-scan.txt';

echo json_encode([
    'services_exists' => file_exists($servicesFile),
    'services_size' => file_exists($servicesFile) ? filesize($servicesFile) : 0,
    'services_content' => file_exists($servicesFile) ? file_get_contents($servicesFile) : null,
    'scan_exists' => file_exists($scanFile),
    'scan_size' => file_exists($scanFile) ? filesize($scanFile) : 0
]);
?>
