<?php
// Test parser manually
header('Content-Type: text/plain');

echo "=== Manual Parser Test ===\n";
echo "Date: " . date('Y-m-d H:i:s') . "\n\n";

// Check if scan file exists
$scanFile = '/var/www/site/data/scan/last-scan.txt';
echo "Checking scan file: $scanFile\n";

if (!file_exists($scanFile)) {
    echo "ERROR: Scan file does not exist!\n";
    exit(1);
}

echo "Scan file size: " . filesize($scanFile) . " bytes\n";

// Check if parser exists
$parser = '/usr/local/bin/parse-scan.sh';
echo "\nChecking parser: $parser\n";

if (!file_exists($parser)) {
    echo "ERROR: Parser does not exist!\n";
    exit(1);
}

if (!is_executable($parser)) {
    echo "ERROR: Parser is not executable!\n";
    exit(1);
}

echo "Parser exists and is executable\n";

// Check output directory permissions
$outputDir = '/var/www/site/data';
echo "\nChecking output directory: $outputDir\n";
echo "Directory permissions: " . substr(sprintf('%o', fileperms($outputDir)), -4) . "\n";
echo "Directory owner: " . posix_getpwuid(filestat($outputDir)['uid'])['name'] ?? 'unknown' . "\n";

// Test if we can write to output directory
$testFile = "$outputDir/test-write.txt";
if (file_put_contents($testFile, "test") !== false) {
    echo "Write test: SUCCESS\n";
    unlink($testFile);
} else {
    echo "Write test: FAILED\n";
}

// Try to run the parser
echo "\n=== Running Parser ===\n";
$output = [];
$return_var = 0;
exec("$parser 2>&1", $output, $return_var);

echo "Parser exit code: $return_var\n";
echo "Parser output:\n";
foreach ($output as $line) {
    echo "  $line\n";
}

// Check if services.json was created/updated
$servicesFile = '/var/www/site/data/services.json';
echo "\n=== Services File Status ===\n";
echo "Services file: $servicesFile\n";

if (file_exists($servicesFile)) {
    echo "Services file size: " . filesize($servicesFile) . " bytes\n";
    echo "Services file content:\n";
    $content = file_get_contents($servicesFile);
    echo $content . "\n";
    
    $services = json_decode($content, true);
    if (is_array($services)) {
        echo "Number of services: " . count($services) . "\n";
    } else {
        echo "ERROR: Invalid JSON in services file\n";
    }
} else {
    echo "Services file does not exist\n";
}
?>
