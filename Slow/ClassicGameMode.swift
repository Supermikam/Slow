//
//  ClassicGameMode.swift
//  Slow
//
//  Created by Ruohan Liu on 19/03/17.
//  Copyright © 2017 Ruohan Liu. All rights reserved.
//

import Foundation

enum BasicBoardState{
    case hasAreaSelected
    case waitingForUserInput
    case levelEnded
}

//This should be moved into controller maybe?
enum UserInput {
    case UnitSelection ((Int,Int))
    case ToolSelection
    case MenuSelection
}


class ClassicGameMode {
    
    //MARK: Property
    let finalLevel : Int = 20
    let targetDic : [Int] = [1000,3100,6500,11500,18300,27100,38100,
                             51500,67500,86300,108100,133100,161500,
                             193500,229300,269100,308900,352900,
                             401300,500000]
    let clearBoardScoreDic : [Int] = [20000,13000,10400,8200,6300,4800,3600,2600,1800,1200,820,510,300,160,80]
    var currentLevel : Int = 1
    var currentScore : Int = 0
    var levelTarget: Int
    var levelScore: Int = 0
    var clearBoardScore : Int = 0
    var selectionScore : Int = 0
    var numOfUnitsSelected: Int = 0
    var gameBoard : BasicBoard
    var boardState: BasicBoardState {didSet{if oldValue == .levelEnded{ levelEnded()}}}
            
    var userInput : UserInput?
    
    
    
    //MARK: Initializer
    init(){
        levelTarget = targetDic[0]
        gameBoard = BasicBoard(column: 10, row: 10, numOfTypes: 5)
        boardState = .waitingForUserInput

    }
    
    //MARK: API
    
    
    
    //MARK: State Function
    
    func waitingForUserInputState(input:UserInput) {
        if case .UnitSelection(let position) = input {
            if gameBoard.isValidSelectionAtIndex(position){
                gameBoard.selectUnitsTriggeredAtIndex(position)
                numOfUnitsSelected = gameBoard.countOfSelectedArea
                calculateSelectionScore()
                boardState = .hasAreaSelected
            }
        }
    }
    
    func hasAreaSelectedState(input: UserInput) {
        if case .UnitSelection(let position) = input{
            if (gameBoard.selection.contains{$0 == position}){
                gameBoard.removeUnitsFromBoard()
                levelScore += selectionScore
                currentScore += selectionScore
                selectionScore = 0
                numOfUnitsSelected = 0
                if gameBoard.hasActiveUnitsInBoard(){boardState = .waitingForUserInput}else{boardState = .levelEnded}
            }else{
                selectionScore = 0
                numOfUnitsSelected = 0
                gameBoard.cancelSelection()
                boardState = .waitingForUserInput
            }
        }
    }
    
    func levelEnded(){
        calculateClearBoardScore()
        levelScore += clearBoardScore
        clearBoardScore += clearBoardScore
        if currentScore >= levelTarget{
            if currentLevel < finalLevel{
                currentLevel += 1
                levelTarget = targetDic[currentLevel]
                levelScore = 0
                gameBoard.setMatrix()
            }else{
                // Player Cleared classicMode
            }
            
        }else{
            //gameOver
        }
        
        
    }
    
    
    
    //MARK: Helper Function
   
    
    func calculateClearBoardScore(){
        let numOfUnitsLeft = gameBoard.countOfBoard
        switch numOfUnitsLeft{
        case 0...14:
            clearBoardScore = clearBoardScoreDic[numOfUnitsLeft]
        default:
            clearBoardScore = 0
        }
        
    }
    
    func calculateSelectionScore(){
        var score : Int
        let base = numOfUnitsSelected * numOfUnitsSelected
        switch numOfUnitsSelected {
        case 2...5: score = base * 5
        case 6...8: score = base * 10
        case 9...11: score = base * 15
        case 12...14: score = base * 20
        case 15...17: score = base * 25
        default: score = base * 30
        }
        selectionScore = score
    }

}
