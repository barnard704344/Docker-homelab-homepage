<?php
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

// Data files - should work with proper host directory permissions
$categoriesFile = '/var/www/site/data/categories.json';
$assignmentsFile = '/var/www/site/data/service-assignments.json';
$servicesFile = '/var/www/site/data/services.json';
$servicesCompatFile = '/var/www/site/services.json';

// Ensure data directory exists with proper permissions
if (!is_dir('/var/www/site/data')) {
    mkdir('/var/www/site/data', 0777, true);
}

// Data directory should already have 777 permissions from host setup
// If not, there's a setup problem that needs to be fixed at the host level

// Default categories
$defaultCategories = [
    'network' => 'Network',
    'media' => 'Media',
    'home-automation' => 'Home Automation',
    'web-service' => 'Web Service', 
    'server' => 'Server',
    'development' => 'Development',
    'monitoring' => 'Monitoring',
    'nas' => 'NAS & Storage',
    'ai' => 'AI & Machine Learning',
    'other' => 'Other'
];

// Helper functions
function loadJsonFile($file, $default = []) {
    if (file_exists($file)) {
        $content = file_get_contents($file);
        $data = json_decode($content, true);
        return $data !== null ? $data : $default;
    }
    return $default;
}

function saveJsonFile($filename, $data) {
    $dataDir = '/var/www/site/data';
    
    // Ensure directory exists with maximum permissions
    if (!is_dir($dataDir)) {
        mkdir($dataDir, 0777, true);
        chmod($dataDir, 0777);
    }
    
    // Ensure directory is writable
    if (!is_writable($dataDir)) {
        // Try to fix permissions
        chmod($dataDir, 0777);
        
        // If still not writable, return detailed error
        if (!is_writable($dataDir)) {
            $perms = substr(sprintf('%o', fileperms($dataDir)), -4);
            $owner = function_exists('posix_getpwuid') ? posix_getpwuid(fileowner($dataDir))['name'] : 'unknown';
            return ["error" => "Directory not writable. Permissions: $perms, Owner: $owner, Current user: " . (function_exists('posix_getpwuid') ? posix_getpwuid(posix_geteuid())['name'] : 'unknown')];
        }
    }
    
    $filepath = "$dataDir/$filename";
    
    // Create file if it doesn't exist
    if (!file_exists($filepath)) {
        touch($filepath);
        chmod($filepath, 0666);
    }
    
    $json = json_encode($data, JSON_PRETTY_PRINT);
    
    // Try multiple write approaches
    $success = false;
    
    // Method 1: Direct file_put_contents
    if (file_put_contents($filepath, $json, LOCK_EX) !== false) {
        $success = true;
    } 
    // Method 2: Open file handle
    else if (($handle = fopen($filepath, 'w')) !== false) {
        if (flock($handle, LOCK_EX)) {
            if (fwrite($handle, $json) !== false) {
                $success = true;
            }
            flock($handle, LOCK_UN);
        }
        fclose($handle);
    }
    
    if ($success) {
        // Ensure file permissions are correct after writing
        chmod($filepath, 0666);
        return ["success" => true];
    } else {
        $error = error_get_last();
        $perms = file_exists($filepath) ? substr(sprintf('%o', fileperms($filepath)), -4) : 'not exists';
        $dirWritable = is_writable($dataDir) ? 'yes' : 'no';
        return ["error" => "Failed to write file: $filepath (Directory writable: $dirWritable, File permissions: $perms, PHP error: " . ($error['message'] ?? 'none') . ")"];
    }
}

// Handle requests
try {
    $method = $_SERVER['REQUEST_METHOD'];
    
    if ($method === 'GET') {
        $action = $_GET['action'] ?? '';
        
        switch ($action) {
            case 'get_categories':
                $categories = loadJsonFile($categoriesFile, $defaultCategories);
                echo json_encode($categories);
                break;
                
            case 'get_assignments':
                $assignments = loadJsonFile($assignmentsFile, []);
                echo json_encode($assignments);
                break;
                
            case 'get_services':
                $services = loadJsonFile($servicesFile, []);
                echo json_encode($services);
                break;
                
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Invalid action']);
        }
        
    } elseif ($method === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if ($input === null) {
            throw new Exception('Invalid JSON input');
        }
        
        $action = $input['action'] ?? '';
        
        switch ($action) {
            case 'save_categories':
                if (!isset($input['categories']) || !is_array($input['categories'])) {
                    throw new Exception('Invalid categories data');
                }
                
                $result = saveJsonFile('categories.json', $input['categories']);
                if (isset($result['error'])) {
                    echo json_encode($result);
                } else {
                    echo json_encode(['success' => true, 'message' => 'Categories saved']);
                }
                break;
                
            case 'save_assignments':
                if (!isset($input['assignments']) || !is_array($input['assignments'])) {
                    throw new Exception('Invalid assignments data');
                }
                
                saveJsonFile($assignmentsFile, $input['assignments']);
                echo json_encode(['success' => true, 'message' => 'Assignments saved']);
                break;
                
            case 'save_services':
                if (!isset($input['services']) || !is_array($input['services'])) {
                    throw new Exception('Invalid services data');
                }
                
                // Load current categories and assignments
                $categories = loadJsonFile($categoriesFile, $defaultCategories);
                $assignments = loadJsonFile($assignmentsFile, []);
                
                // Update services with current category assignments
                $updatedServices = [];
                foreach ($input['services'] as $service) {
                    $serviceName = $service['title'] ?? '';
                    
                    // Apply category assignment if exists
                    if (isset($assignments[$serviceName])) {
                        $categoryKey = $assignments[$serviceName];
                        $categoryName = $categories[$categoryKey] ?? $service['group'] ?? 'Other';
                        $service['group'] = $categoryName;
                    }
                    
                    $updatedServices[] = $service;
                }
                
                // Save both files
                saveJsonFile($servicesFile, $updatedServices);
                saveJsonFile($servicesCompatFile, $updatedServices);
                
                echo json_encode(['success' => true, 'message' => 'Services saved']);
                break;
                
            case 'reset_categories':
                saveJsonFile($categoriesFile, $defaultCategories);
                saveJsonFile($assignmentsFile, []);
                echo json_encode(['success' => true, 'message' => 'Categories reset to defaults']);
                break;
                
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Invalid action']);
        }
        
    } else {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
