import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private let presenter = MovieQuizPresenter()
    
    private var correctAnswers = 0
    
    private var questionFactory: QuestionFactoryProtocol?
    
    private let statisticService: StatisticServiceProtocol = StatisticService()
    private var alertPresenter = AlertPresenter()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.viewController = self
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        
        showLoadingIndicator()
        questionFactory?.loadData()
        setupImageView()
    }
    
    // MARK: - Network & Loading
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    func didLoadDataFromServer() {
        hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    // MARK: - Error Handling
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка", message: message, buttonText: "Попробовать еще раз") { [weak self] in
        guard let self = self else { return }
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            
            self.questionFactory?.loadData() //requestNextQuestion()?
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
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        presenter.currentQuestion = question
        let viewModel = presenter.convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Game Flow
    
    
    
    private func restartGame() {
        presenter.resetQuestionIndex()
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
        disableButtons(false)
    }
    
    private func makeResultsMessage() -> QuizResultsViewModel {
        let bestGame = statisticService.bestGame.correct
        let dateString = statisticService.bestGame.date.dateTimeString
        let accuracyString = String(format: "%.2f%%", statisticService.totalAccuracy)
        
        let result = correctAnswers == presenter.questionsAmount ? "Поздравляем, вы ответили на 10 из 10!" : "Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)"
        
        let text = """
        \(result)
        Количество сыгранных квизов: \(statisticService.gamesCount)
        Рекорд: \(bestGame)/\(presenter.questionsAmount) (\(dateString))
        Средняя точность: \(accuracyString)
        """
        
        return QuizResultsViewModel(title: "Этот раунд окончен!", text: text, buttonText: "Сыграть ещё раз")
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let model = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            guard let self = self else { return }
            self.restartGame()
        }
        alertPresenter.show(in: self, model: model)
    }
    
    func showAnswerResult(isCorrect: Bool) {
        let delayInSeconds: TimeInterval = 1
        if isCorrect { correctAnswers += 1 }
        highlightImageBorder(isCorrect: isCorrect)
        
        Timer.scheduledTimer(withTimeInterval: delayInSeconds, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.showNextQuestionOrResults()
            self.resetImageBorder()
        }
        
    }
    
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion()  {
            statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
            let viewModel = makeResultsMessage()
            show(quiz: viewModel)
        } else {
            presenter.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
            disableButtons(false)
        }
    }
    
    // MARK: - UI Helpers
    
    func disableButtons(_ value: Bool) {
        yesButton.isEnabled = !value
        noButton.isEnabled = !value
    }
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter.noButtonClicked()
    }
}
