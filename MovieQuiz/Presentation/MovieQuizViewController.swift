import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    // MARK: - Properties
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    
    private let statisticService: StatisticServiceProtocol = StatisticService()
    private var alertPresenter = AlertPresenter()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        questionFactory = QuestionFactory(delegate: self)
        questionFactory?.requestNextQuestion()
        
        setupImageView()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Setup UI
    
    private func setupImageView() {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    // MARK: - Game Flow
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    private func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
        disableButtons(false)
    }
    
    private func makeResultsMessage() -> QuizResultsViewModel {
        let bestGame = statisticService.bestGame.correct
        let dateString = statisticService.bestGame.date.dateTimeString
        let accuracyString = String(format: "%.2f%%", statisticService.totalAccuracy)
        
        let result = correctAnswers == questionsAmount ? "Поздравляем, вы ответили на 10 из 10!" : "Ваш результат: \(correctAnswers)/\(questionsAmount)"
        
        let text = """
            \(result)
            Количество сыгранных квизов: \(statisticService.gamesCount)
            Рекорд: \(bestGame)/\(questionsAmount) (\(dateString))
            Средняя точность: \(accuracyString)
            """
        
        return QuizResultsViewModel(title: "Этот раунд окончен!", text: text, buttonText: "Сыграть еще раз")
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
    
    private func showAnswerResult(isCorrect: Bool) {
        let delayInSeconds: TimeInterval = 1
        if isCorrect { correctAnswers += 1 }
        highlightImageBorder(isCorrect: isCorrect)
        
        Timer.scheduledTimer(withTimeInterval: delayInSeconds, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            self.resetImageBorder()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1  {
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            let viewModel = makeResultsMessage()
            show(quiz: viewModel)
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
            disableButtons(false)
        }
    }
    
    // MARK: - UI Helpers
    
    private func disableButtons(_ value: Bool) {
        yesButton.isEnabled = !value
        noButton.isEnabled = !value
    }
    
    private func highlightImageBorder(isCorrect: Bool) {
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    private func resetImageBorder() {
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        disableButtons(true)
        guard let currentQuestion = currentQuestion else {
            return
        }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        disableButtons(true)
        guard let currentQuestion = currentQuestion else {
            return
        }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }
}
