import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewController?
    
    init(viewController: MovieQuizViewController) {
            self.viewController = viewController
            
            questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
            questionFactory?.loadData()
            viewController.showLoadingIndicator()
        }
    
    var currentQuestion: QuizQuestion?
    var correctAnswers = 0
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private var buttonsEnabled = true
    private let statisticService: StatisticServiceProtocol = StatisticService()
    
    func disableButtons() {
        buttonsEnabled = false
        viewController?.setButtonsEnabled(false)
    }
    
    func enableButtons() {
        buttonsEnabled = true
        viewController?.setButtonsEnabled(true)
    }
    
    func didLoadDataFromServer() {
            viewController?.hideLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    
    func didFailToLoadData(with error: Error) {
            let message = error.localizedDescription
            viewController?.showNetworkError(message: message)
        }
    
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    func didAnswer(isCorrectAnswer: Bool) {
        if isCorrectAnswer { correctAnswers += 1 }
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        disableButtons()
        let givenAnswer = isYes
        viewController?.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    func restartGame() {
        resetQuestionIndex()
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
        enableButtons()
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
            guard let question = question else {
                return
            }
            
            currentQuestion = question
            let viewModel = convert(model: question)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.viewController?.show(quiz: viewModel)
                self.enableButtons()
            }
        }
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion()  {
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            let viewModel = makeResultsMessage()
            viewController?.show(quiz: viewModel)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    func makeResultsMessage() -> QuizResultsViewModel {
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
        
        return QuizResultsViewModel(title: "Этот раунд окончен!", text: text, buttonText: "Сыграть ещё раз")
    }
    
}
