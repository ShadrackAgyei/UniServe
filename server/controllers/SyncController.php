<?php
class SyncController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function sync($user, $params = []) {
        $since = $_GET['since'] ?? '1970-01-01T00:00:00';

        // Get updated lost & found items (shared)
        $stmt = $this->db->prepare("SELECT lf.*, u.name as user_name FROM uniserve_lost_found_items lf JOIN uniserve_users u ON lf.user_id = u.id WHERE lf.updated_at > ?");
        $stmt->execute([$since]);
        $lostFound = $stmt->fetchAll();

        // Get new notifications
        $stmt = $this->db->prepare("SELECT n.*, CASE WHEN nr.user_id IS NOT NULL THEN 1 ELSE 0 END as is_read FROM uniserve_notifications n LEFT JOIN uniserve_notification_reads nr ON n.id = nr.notification_id AND nr.user_id = ? WHERE n.created_at > ?");
        $stmt->execute([$user['id'], $since]);
        $notifications = $stmt->fetchAll();

        // Get emergency contacts (if any updated)
        $stmt = $this->db->prepare("SELECT * FROM uniserve_emergency_contacts WHERE is_active = 1 ORDER BY sort_order ASC");
        $stmt->execute();
        $contacts = $stmt->fetchAll();

        echo json_encode([
            'success' => true,
            'server_time' => date('c'),
            'changes' => [
                'lost_found_items' => $lostFound,
                'notifications' => $notifications,
                'emergency_contacts' => $contacts,
            ],
        ]);
    }
}
