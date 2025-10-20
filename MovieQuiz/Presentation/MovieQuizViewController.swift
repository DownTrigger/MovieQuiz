import UIKit

final class MovieQuizViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private var presenter: MovieQuizPresenter!
    private let statisticService: StatisticServiceProtocol = StatisticService()
    private var alertPresenter = AlertPresenter()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        
        showLoadingIndicator()
        setupImageView()
    }
    
    // MARK: - Network & Loading
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    // MARK: - Error Handling
    
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка", message: message, buttonText: "Попробовать еще раз") { [weak self] in
        guard let self = self else { return }
            
            self.presenter.restartGame()
            
//            self.presenter.resetQuestionIndex()
//            self.presenter.correctAnswers = 0
//            
//            self.questionFactory?.loadData() //requestNextQuestion()?
        }
        alertPresenter.show(in: self, model: model)
    }
    
    // MARK: - Setup UI
    
    private func setupImageView() {
        let layer = imageView.layer
        layer.masksToBounds = true
        layer.borderWidth = 8
        layer.borderColor = UIColor.clear.cgColor
    }
    
    private func highlightImageBorder(isCorrect: Bool) {
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    private func resetImageBorder() {
        imageView.layer.borderColor = UIColor.clear.cgColor
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
    
    func showAnswerResult(isCorrect: Bool) {
        let delayInSeconds: TimeInterval = 1
        presenter.didAnswer(isCorrectAnswer: isCorrect)
        highlightImageBorder(isCorrect: isCorrect)
        
        Timer.scheduledTimer(withTimeInterval: delayInSeconds, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.presenter.showNextQuestionOrResults()
            self.resetImageBorder()
        }
        
    }
    
    // MARK: - UI Helpers
    
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
