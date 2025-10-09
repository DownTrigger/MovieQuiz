//
//  GameResult.swift
//  MovieQuiz
//
//  Created by Андрей Рузавин on 7/10/25.
//
import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetterThan(_ another: GameResult) -> Bool {
        correct > another.correct
    }
}

