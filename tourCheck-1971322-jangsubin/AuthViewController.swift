import UIKit
import FirebaseAuth

class AuthViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var siginupButton: UIButton!

    // Segue 진행 중인지 확인하기 위한 상태 변수
    private var isPerformingSegue = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        print("Login button tapped")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }
            if let error = error {
                print("Login error: \(error.localizedDescription)")
                return
            }
            print("Login successful")
            // 로그인 성공 시 Segue 호출 (중복 방지)
            if !self.isPerformingSegue {
                self.isPerformingSegue = true
                print("Performing segue from login")
                self.performSegue(withIdentifier: "goToMain", sender: sender)
            } else {
                print("Segue already performing from login")
            }
        }
    }

    @IBAction func signupButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        print("Signup button tapped")
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }
            if let error = error {
                print("Signup error: \(error.localizedDescription)")
                return
            }
            print("Signup successful")
            // 회원가입 성공 시 알림 표시
            let alertController = UIAlertController(title: "회원가입 완료", message: "회원가입이 성공적으로 완료되었습니다.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: .default) { _ in
                // 알림 닫힌 후 Segue 호출 (중복 방지)
                if !self.isPerformingSegue {
                    self.isPerformingSegue = true
                    print("Performing segue from signup")
                    self.performSegue(withIdentifier: "goToMain", sender: self)
                } else {
                    print("Segue already performing from signup")
                }
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMain" {
            // 필요한 경우 데이터를 전달하거나 추가 작업 수행
            print("Prepare for segue to goToMain")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isPerformingSegue = false
    }
}
