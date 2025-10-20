import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private lazy var presenter = MovieQuizPresenter(viewController: self)
    private var alertPresenter = AlertPresenter()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        
        showLoadingIndicator()
        setupImageView()
    }
    
    // MARK: - Setup UI
    
    private func setupImageView() {
        let layer = imageView.layer
        layer.masksToBounds = true
        layer.borderWidth = 8
        layer.borderColor = UIColor.clear.cgColor
    }
    
    // MARK: - Loading
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    // MARK: - Game Flow
    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let model = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            guard let self = self else { return }
            self.presenter.restartGame()
        }
        alertPresenter.show(in: self, model: model)
    }
    
    // MARK: - Error Handling
    
    func showNetworkErrorAlert(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка", message: message, buttonText: "Попробовать еще раз") { [weak self] in
        guard let self = self else { return }
            
            self.presenter.retryLoadData()
        }
        alertPresenter.show(in: self, model: model)
    }
    
    // MARK: - UI Helpers
    
    func highlightImageBorder(isCorrect: Bool) {
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    func resetImageBorder() {
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func setButtonsEnabled(_ value: Bool) {
           yesButton.isEnabled = value
           noButton.isEnabled = value
       }
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter.noButtonClicked()
    }
}
