import UIKit

final class AlertPresenter {
    func show(in ViewController: UIViewController, model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert
        )

        let action = UIAlertAction(title: model.buttonText, style: .default) { _ in
            model.completion()
        }

        alert.addAction(action)

        ViewController.present(alert, animated: true, completion: nil)
    }
}
