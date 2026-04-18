<?php
class AuthController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function register($user = null, $params = []) {
        $data = json_decode(file_get_contents('php://input'), true);

        $required = ['student_id', 'name', 'email', 'password'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => "$field is required"]);
                return;
            }
        }

        // Check if student_id or email already exists
        $stmt = $this->db->prepare("SELECT id FROM uniserve_users WHERE student_id = ? OR email = ?");
        $stmt->execute([$data['student_id'], $data['email']]);
        if ($stmt->fetch()) {
            http_response_code(409);
            echo json_encode(['success' => false, 'message' => 'Student ID or email already registered']);
            return;
        }

        $token = bin2hex(random_bytes(32));
        $passwordHash = password_hash($data['password'], PASSWORD_DEFAULT);

        $stmt = $this->db->prepare("INSERT INTO uniserve_users (student_id, name, email, password_hash, phone, department, program, auth_token) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['student_id'],
            $data['name'],
            $data['email'],
            $passwordHash,
            $data['phone'] ?? null,
            $data['department'] ?? null,
            $data['program'] ?? null,
            $token,
        ]);

        $userId = $this->db->lastInsertId();
        $stmt = $this->db->prepare("SELECT id, student_id, name, email, phone, department, program, profile_photo_url, created_at FROM uniserve_users WHERE id = ?");
        $stmt->execute([$userId]);
        $newUser = $stmt->fetch();

        echo json_encode(['success' => true, 'user' => $newUser, 'token' => $token]);
    }

    public function login($user = null, $params = []) {
        $data = json_decode(file_get_contents('php://input'), true);

        if (empty($data['email']) || empty($data['password'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Email and password are required']);
            return;
        }

        $stmt = $this->db->prepare("SELECT * FROM uniserve_users WHERE email = ?");
        $stmt->execute([$data['email']]);
        $foundUser = $stmt->fetch();

        if (!$foundUser || !password_verify($data['password'], $foundUser['password_hash'])) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Invalid email or password']);
            return;
        }

        // Generate new token on each login
        $token = bin2hex(random_bytes(32));
        $stmt = $this->db->prepare("UPDATE uniserve_users SET auth_token = ? WHERE id = ?");
        $stmt->execute([$token, $foundUser['id']]);

        unset($foundUser['password_hash'], $foundUser['auth_token']);
        echo json_encode(['success' => true, 'user' => $foundUser, 'token' => $token]);
    }
}
