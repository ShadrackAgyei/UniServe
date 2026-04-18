<?php
// Temporary script to set up database tables
// DELETE THIS FILE AFTER SETUP

require_once __DIR__ . '/config/database.php';

$db = new Database();
$conn = $db->getConnection();

if (!$conn) {
    echo json_encode(['success' => false, 'message' => 'Could not connect to database']);
    exit;
}

$results = [];

$statements = [
    "CREATE TABLE IF NOT EXISTS uniserve_users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        student_id VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        phone VARCHAR(20),
        department VARCHAR(100),
        program VARCHAR(100),
        profile_photo_url VARCHAR(255),
        auth_token VARCHAR(255) UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )",
    "CREATE TABLE IF NOT EXISTS uniserve_campus_issues (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        category VARCHAR(50) NOT NULL,
        image_url VARCHAR(255),
        status ENUM('Pending','In Progress','Resolved') DEFAULT 'Pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES uniserve_users(id)
    )",
    "CREATE TABLE IF NOT EXISTS uniserve_lost_found_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        type ENUM('lost','found') NOT NULL,
        image_url VARCHAR(255),
        location VARCHAR(255) NOT NULL,
        contact_info VARCHAR(255) NOT NULL,
        is_resolved TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES uniserve_users(id)
    )",
    "CREATE TABLE IF NOT EXISTS uniserve_notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        category VARCHAR(50) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )",
    "CREATE TABLE IF NOT EXISTS uniserve_notification_reads (
        notification_id INT NOT NULL,
        user_id INT NOT NULL,
        read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (notification_id, user_id),
        FOREIGN KEY (notification_id) REFERENCES uniserve_notifications(id),
        FOREIGN KEY (user_id) REFERENCES uniserve_users(id)
    )",
    "CREATE TABLE IF NOT EXISTS uniserve_emergency_contacts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        department VARCHAR(100) NOT NULL,
        icon VARCHAR(50) NOT NULL,
        sort_order INT DEFAULT 0,
        is_active TINYINT(1) DEFAULT 1
    )"
];

foreach ($statements as $sql) {
    try {
        $conn->exec($sql);
        // Extract table name
        preg_match('/TABLE IF NOT EXISTS (\w+)/', $sql, $m);
        $results[] = ['table' => $m[1] ?? 'unknown', 'status' => 'created'];
    } catch (PDOException $e) {
        preg_match('/TABLE IF NOT EXISTS (\w+)/', $sql, $m);
        $results[] = ['table' => $m[1] ?? 'unknown', 'status' => 'error', 'message' => $e->getMessage()];
    }
}

// Seed emergency contacts (only if empty)
try {
    $count = $conn->query("SELECT COUNT(*) FROM uniserve_emergency_contacts")->fetchColumn();
    if ($count == 0) {
        $conn->exec("INSERT INTO uniserve_emergency_contacts (name, phone, department, icon, sort_order) VALUES
            ('Campus Security', '+233302610330', 'Security', 'security', 1),
            ('Medical Center', '+233302610331', 'Health Services', 'medical', 2),
            ('Fire Emergency', '193', 'Fire Service', 'fire', 3),
            ('Maintenance Office', '+233302610332', 'Facilities', 'maintenance', 4),
            ('Student Affairs', '+233302610333', 'Administration', 'admin', 5),
            ('IT Help Desk', '+233302610334', 'IT Support', 'it', 6),
            ('Counseling Center', '+233302610335', 'Wellness', 'counseling', 7),
            ('National Emergency', '112', 'Emergency', 'emergency', 8)
        ");
        $results[] = ['table' => 'uniserve_emergency_contacts', 'status' => 'seeded'];
    } else {
        $results[] = ['table' => 'uniserve_emergency_contacts', 'status' => 'already seeded'];
    }
} catch (PDOException $e) {
    $results[] = ['table' => 'uniserve_emergency_contacts_seed', 'status' => 'error', 'message' => $e->getMessage()];
}

// Seed notifications (only if empty)
try {
    $count = $conn->query("SELECT COUNT(*) FROM uniserve_notifications")->fetchColumn();
    if ($count == 0) {
        $conn->exec("INSERT INTO uniserve_notifications (title, message, category) VALUES
            ('Welcome to UniServe', 'Your campus service app is ready to use. Explore all features from the home screen.', 'General'),
            ('Shuttle Schedule Update', 'The campus shuttle will run extended hours this week due to exams. Last departure at 10 PM.', 'Transport'),
            ('Library Maintenance', 'The main library will be closed for maintenance on Saturday. The annex library remains open.', 'Maintenance'),
            ('Campus Safety Drill', 'A fire safety drill will take place on Friday at 2 PM. Please follow evacuation procedures.', 'Safety')
        ");
        $results[] = ['table' => 'uniserve_notifications', 'status' => 'seeded'];
    } else {
        $results[] = ['table' => 'uniserve_notifications', 'status' => 'already seeded'];
    }
} catch (PDOException $e) {
    $results[] = ['table' => 'uniserve_notifications_seed', 'status' => 'error', 'message' => $e->getMessage()];
}

header('Content-Type: application/json');
echo json_encode(['success' => true, 'results' => $results], JSON_PRETTY_PRINT);
