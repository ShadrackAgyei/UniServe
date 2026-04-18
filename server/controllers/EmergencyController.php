<?php
class EmergencyController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function list($user, $params = []) {
        $stmt = $this->db->prepare("SELECT * FROM uniserve_emergency_contacts WHERE is_active = 1 ORDER BY sort_order ASC");
        $stmt->execute();
        echo json_encode(['success' => true, 'contacts' => $stmt->fetchAll()]);
    }
}
