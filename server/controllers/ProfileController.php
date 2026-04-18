<?php
class ProfileController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function get($user, $params = []) {
        echo json_encode(['success' => true, 'user' => $user]);
    }

    public function update($user, $params = []) {
        $data = json_decode(file_get_contents('php://input'), true);
        $allowed = ['name', 'phone', 'department', 'program'];
        $updates = [];
        $values = [];

        foreach ($allowed as $field) {
            if (isset($data[$field])) {
                $updates[] = "$field = ?";
                $values[] = $data[$field];
            }
        }

        if (empty($updates)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'No fields to update']);
            return;
        }

        $values[] = $user['id'];
        $sql = "UPDATE uniserve_users SET " . implode(', ', $updates) . " WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($values);

        $stmt = $this->db->prepare("SELECT id, student_id, name, email, phone, department, program, profile_photo_url FROM uniserve_users WHERE id = ?");
        $stmt->execute([$user['id']]);
        $updated = $stmt->fetch();

        echo json_encode(['success' => true, 'user' => $updated]);
    }

    public function uploadPhoto($user, $params = []) {
        if (!isset($_FILES['photo'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'No photo uploaded']);
            return;
        }

        $file = $_FILES['photo'];
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $allowed = ['jpg', 'jpeg', 'png', 'gif'];

        if (!in_array($ext, $allowed)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid file type']);
            return;
        }

        $filename = 'profile_' . $user['id'] . '_' . time() . '.' . $ext;
        $uploadDir = __DIR__ . '/../uploads/profiles/';
        $filepath = $uploadDir . $filename;

        if (!move_uploaded_file($file['tmp_name'], $filepath)) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Upload failed']);
            return;
        }

        $photoUrl = '/uploads/profiles/' . $filename;
        $stmt = $this->db->prepare("UPDATE uniserve_users SET profile_photo_url = ? WHERE id = ?");
        $stmt->execute([$photoUrl, $user['id']]);

        echo json_encode(['success' => true, 'photo_url' => $photoUrl]);
    }
}
