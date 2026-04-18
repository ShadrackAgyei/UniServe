<?php
class NotificationsController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function list($user, $params = []) {
        $sql = "SELECT n.*, CASE WHEN nr.user_id IS NOT NULL THEN 1 ELSE 0 END as is_read
                FROM uniserve_notifications n
                LEFT JOIN uniserve_notification_reads nr ON n.id = nr.notification_id AND nr.user_id = ?
                ORDER BY n.created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$user['id']]);
        echo json_encode(['success' => true, 'notifications' => $stmt->fetchAll()]);
    }

    public function markRead($user, $params = []) {
        $id = $params['id'];
        $stmt = $this->db->prepare("INSERT IGNORE INTO uniserve_notification_reads (notification_id, user_id) VALUES (?, ?)");
        $stmt->execute([$id, $user['id']]);
        echo json_encode(['success' => true]);
    }
}
