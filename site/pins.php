<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

// Use persistent data directory
$pins_file = '/var/www/site/data/pins.json';

// Ensure data directory exists
if (!is_dir('/var/www/site/data')) {
    mkdir('/var/www/site/data', 0755, true);
}

// Ensure pins file exists
if (!file_exists($pins_file)) {
    file_put_contents($pins_file, '[]');
}

function getPins() {
    global $pins_file;
    $data = file_get_contents($pins_file);
    return json_decode($data, true) ?: [];
}

function savePins($pins) {
    global $pins_file;
    file_put_contents($pins_file, json_encode($pins, JSON_PRETTY_PRINT));
}

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Return all pins
        echo json_encode(getPins());
        break;
        
    case 'POST':
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid input']);
            exit;
        }
        
        // Handle sync action - replace all pins with provided array
        if (isset($input['action']) && $input['action'] === 'sync') {
            if (isset($input['pins']) && is_array($input['pins'])) {
                savePins($input['pins']);
                echo json_encode(['success' => true, 'pins' => $input['pins']]);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid pins data']);
            }
            break;
        }
        
        // Handle adding a single pin
        if (!isset($input['title'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid input']);
            exit;
        }
        
        $pins = getPins();
        
        // Check if already pinned
        $exists = false;
        foreach ($pins as $pin) {
            if ($pin['title'] === $input['title']) {
                $exists = true;
                break;
            }
        }
        
        if (!$exists) {
            $pins[] = [
                'title' => $input['title'],
                'url' => $input['url'],
                'group' => $input['group'] ?? 'Pinned',
                'desc' => $input['desc'] ?? '',
                'tags' => $input['tags'] ?? ['pinned'],
                'selectedPort' => $input['selectedPort'] ?? null,
                'pinned_at' => date('c')
            ];
            savePins($pins);
        }
        
        echo json_encode(['success' => true, 'pins' => $pins]);
        break;
        
    case 'DELETE':
        // Remove a pin
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input || !isset($input['title'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid input']);
            exit;
        }
        
        $pins = getPins();
        $pins = array_filter($pins, function($pin) use ($input) {
            return $pin['title'] !== $input['title'];
        });
        $pins = array_values($pins); // Reindex array
        
        savePins($pins);
        echo json_encode(['success' => true, 'pins' => $pins]);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
}
?>
