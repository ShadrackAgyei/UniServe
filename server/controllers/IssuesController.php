<?php
class IssuesController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function list($user, $params = []) {
        $sql = "SELECT * FROM uniserve_campus_issues WHERE user_id = ? ORDER BY created_at DESC";
        $bindings = [$user['id']];

        if (!empty($_GET['status'])) {
            $sql = "SELECT * FROM uniserve_campus_issues WHERE user_id = ? AND status = ? ORDER BY created_at DESC";
            $bindings[] = $_GET['status'];
        }

        $stmt = $this->db->prepare($sql);
        $stmt->execute($bindings);
        $issues = $stmt->fetchAll();

        echo json_encode(['success' => true, 'issues' => $issues]);
    }

    public function create($user, $params = []) {
        $title = $_POST['title'] ?? '';
        $description = $_POST['description'] ?? '';
        $category = $_POST['category'] ?? '';

        if (!$title || !$description || !$category) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Title, description, and category are required']);
            return;
        }

        $imageUrl = null;
        if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $ext = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
            $filename = 'issue_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
            $uploadDir = __DIR__ . '/../uploads/issues/';
            move_uploaded_file($_FILES['image']['tmp_name'], $uploadDir . $filename);
            $imageUrl = '/uploads/issues/' . $filename;
        }

        $stmt = $this->db->prepare("INSERT INTO uniserve_campus_issues (user_id, title, description, category, image_url) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$user['id'], $title, $description, $category, $imageUrl]);

        $id = $this->db->lastInsertId();
        $stmt = $this->db->prepare("SELECT * FROM uniserve_campus_issues WHERE id = ?");
        $stmt->execute([$id]);
        $issue = $stmt->fetch();

        http_response_code(201);
        echo json_encode(['success' => true, 'issue' => $issue]);
    }

    public function updateStatus($user, $params = []) {
        $data = json_decode(file_get_contents('php://input'), true);
        $id = $params['id'];

        $stmt = $this->db->prepare("SELECT * FROM uniserve_campus_issues WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $user['id']]);
        if (!$stmt->fetch()) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Issue not found']);
            return;
        }

        $stmt = $this->db->prepare("UPDATE uniserve_campus_issues SET status = ? WHERE id = ?");
        $stmt->execute([$data['status'], $id]);

        $stmt = $this->db->prepare("SELECT * FROM uniserve_campus_issues WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['success' => true, 'issue' => $stmt->fetch()]);
    }
}
