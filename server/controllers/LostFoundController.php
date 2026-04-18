<?php
class LostFoundController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function list($user, $params = []) {
        $sql = "SELECT lf.*, u.name as user_name FROM uniserve_lost_found_items lf JOIN uniserve_users u ON lf.user_id = u.id";
        $bindings = [];

        if (!empty($_GET['type'])) {
            $sql .= " WHERE lf.type = ?";
            $bindings[] = $_GET['type'];
        }

        $sql .= " ORDER BY lf.created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($bindings);
        echo json_encode(['success' => true, 'items' => $stmt->fetchAll()]);
    }

    public function create($user, $params = []) {
        $title = $_POST['title'] ?? '';
        $description = $_POST['description'] ?? '';
        $type = $_POST['type'] ?? '';
        $location = $_POST['location'] ?? '';
        $contactInfo = $_POST['contact_info'] ?? '';

        if (!$title || !$description || !$type || !$location || !$contactInfo) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'All fields are required']);
            return;
        }

        $imageUrl = null;
        if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $ext = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
            $filename = 'lf_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
            $uploadDir = __DIR__ . '/../uploads/lost-found/';
            move_uploaded_file($_FILES['image']['tmp_name'], $uploadDir . $filename);
            $imageUrl = '/uploads/lost-found/' . $filename;
        }

        $stmt = $this->db->prepare("INSERT INTO uniserve_lost_found_items (user_id, title, description, type, image_url, location, contact_info) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([$user['id'], $title, $description, $type, $imageUrl, $location, $contactInfo]);

        $id = $this->db->lastInsertId();
        $stmt = $this->db->prepare("SELECT * FROM uniserve_lost_found_items WHERE id = ?");
        $stmt->execute([$id]);

        http_response_code(201);
        echo json_encode(['success' => true, 'item' => $stmt->fetch()]);
    }

    public function resolve($user, $params = []) {
        $id = $params['id'];
        $stmt = $this->db->prepare("SELECT * FROM uniserve_lost_found_items WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $user['id']]);
        if (!$stmt->fetch()) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Item not found or not yours']);
            return;
        }

        $stmt = $this->db->prepare("UPDATE uniserve_lost_found_items SET is_resolved = 1 WHERE id = ?");
        $stmt->execute([$id]);

        $stmt = $this->db->prepare("SELECT * FROM uniserve_lost_found_items WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['success' => true, 'item' => $stmt->fetch()]);
    }

    public function delete($user, $params = []) {
        $id = $params['id'];
        $stmt = $this->db->prepare("SELECT * FROM uniserve_lost_found_items WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $user['id']]);
        if (!$stmt->fetch()) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Item not found or not yours']);
            return;
        }

        $stmt = $this->db->prepare("DELETE FROM uniserve_lost_found_items WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['success' => true]);
    }
}
