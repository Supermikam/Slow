//Basic Board model
//All other boards inherit this basic board model

import Foundation

//These two enum declaration needs to be moved to level control class declaration file
enum BasicBoardStateEnum{
    case hasAreaSelected
    case waitingForUserInput
    case levelEnded
}

enum UserInput {
    case UnitSelection ((Int,Int))
    case ToolSelection
    case MenuSelection
}

protocol BoardStateChangeDelegate: class {
    func changeBoardStateTo(changeStateTo state: BasicBoardStateEnum)
}

protocol BasicBoardState : class{
    func handleUserInput(board: BasicBoard, input: UserInput)
}

class WaitingForUserInput: BasicBoardState{
    weak var stateChangeDelegate: BoardStateChangeDelegate?
    func handleUserInput(board: BasicBoard, input: UserInput) {
        if case .UnitSelection(let position) = input {
            if board.isValidSelectionAtIndex(position){
                board.selectUnitsTriggeredAtIndex(position)
                stateChangeDelegate?.changeBoardStateTo(changeStateTo: .hasAreaSelected)
            }
        }
    }
}

class HasAreaSelected: BasicBoardState{
    weak var stateChangeDelegate: BoardStateChangeDelegate?
    internal func handleUserInput(board: BasicBoard, input: UserInput) {
        if case .UnitSelection(let position) = input{
            if (board.selection.contains{$0 == position}){
                board.removeUnitsFromBoard()
                if board.hasActiveUnitsInBoard(){
                    stateChangeDelegate?.changeBoardStateTo(changeStateTo: .waitingForUserInput)
                }else{
                    stateChangeDelegate?.changeBoardStateTo(changeStateTo: .levelEnded)
                }
            }else{
                stateChangeDelegate?.changeBoardStateTo(changeStateTo: .waitingForUserInput)
                // need something here to pass the UserInput to the new state to handle
            }
        }
       
    }
}

class BasicBoard {
    
    // MARK: Typealias
    
    typealias MatrixArray = [[Int?]]
    typealias SelectionArray = [(Int,Int)]
    typealias UnitIndex = (Int,Int)
    typealias PositionDictionary = [Int:UnitIndex]
    
    // MARK: property
    var column : Int
    var row : Int
    var numOfTypes : Int
    // matrix stores the map
    var matrix = MatrixArray()
    
    weak var boardState : BasicBoardState?
    
    // selection stores what area of the map has been selected
    var selection = SelectionArray()
    // All the unit in the matrix has a unique index number.
    // Index of a unit stays the same through out the level. 
    // The indexMatrix and positionDic extist because one the selection algorism uses
    // set data structure to get the selection area
    // and set requires its member to be hashable. UnitIndex tuple is not hashable. 
    // And two the controller uses it to keep track of the position of sprites
    var indexMatrix = MatrixArray()
    // Recored the position of the units. Keys are the index of the unit.
    var positionDic = PositionDictionary()
    
    // MARK: computed property
    var countOfSelectedArea : Int {
        get{
            return selection.count
        }
    }
    var countOfBoard: Int {
        get{
            var total=0
            for i in 0..<column{
                for j in 0..<row {
                    if matrix[i][j] != nil {
                        total += 1
                    }
                }
            }
            return total
        }
    }
    
    // MARK: initializer
    init (column: Int = 10, row: Int = 10, numOfTypes: Int = 5){
        self.column = column
        self.row = row
        self.numOfTypes = numOfTypes
        setMatrix();
        
    }
    
    // MARK: API
    func setMatrix () {
        matrix = []
        let uint32TypeOfBubbles = UInt32(numOfTypes)
        for _ in 1...column {
            var oneColumn = [Int?]()
            for _ in 1...row {
                oneColumn.append(Int(arc4random_uniform(uint32TypeOfBubbles)))
            }
            matrix.append(oneColumn)
        }
        
        setIndexMatrix()
        setPositionDic()
    }
    
    func removeUnitsFromBoard(){
        
        
        for (i,j) in selection{
            matrix[i][j] = nil
            indexMatrix[i][j] = nil
        }

        
            //by explicitly passing in the propety as an inout peramiter makes clear
            //that this method aims to change the propety
            rearrangeTargetMatrix(&self.matrix)
            rearrangeTargetMatrix(&self.indexMatrix)
            setPositionDic()
            cancelSelection()
    }
    
    func cancelSelection(){
        selection = []
    }

    func isValidSelectionAtIndex(_ index:UnitIndex) -> Bool{
        
        // a unit is touched, given the positon of the unit
        // judging whether it is a valid selection
        // return true if any nabour is of the same type
        // return false if none of the nabours are of the same type
        
        var isValid = false
        
        // locate all the index of neighbor bubbles
        let indexOfNeighbors = getTheIndexArrayOfAllNeighbors(index)
        
        // check whether any neighbor has the same colour as the bublle selected
        for neighborIndex in indexOfNeighbors {
            if matrix[neighborIndex.0][neighborIndex.1] == matrix[index.0][index.1]{
                isValid = true
            }
        }
        
        return isValid
    }
    
    func selectUnitsTriggeredAtIndex(_ index:UnitIndex){
        /* check which neighbour is of the same type as the unit selected
           the neighbours of the same type need to be explored, so put them into toCheck
           when all neighbours are checked, add the unit checked into the set checked.
           subtract checked from toCheck
           and repeat this procedure until toCheck is empty
           I really like this algorism
        */
        
        var toCheck : Set<Int> = []
        var checked : Set<Int> = []
        
        if isValidSelectionAtIndex(index){
            toCheck.insert(indexMatrix[index.0][index.1]!)
        }
        
        while !toCheck.isEmpty{
            for unitToCheck in toCheck{
                let targetUnitIndex = positionDic[unitToCheck]
                let allNeighbors = getTheIndexArrayOfAllNeighbors(targetUnitIndex!)
                
                for eachNeighbor in allNeighbors{
                    if matrix[index.0][index.1] == matrix[eachNeighbor.0][eachNeighbor.1]{
                        toCheck.insert(indexMatrix[eachNeighbor.0][eachNeighbor.1]!)
                    }
                }
                
                checked.insert(unitToCheck)
            }
            
            toCheck = toCheck.subtracting(checked)
        }
        
        for eachUnit in checked{
            selection.append(positionDic[eachUnit]!)
        }
    }
    
    func hasActiveUnitsInBoard() -> Bool {
        
        // return true if no bubbles could be busted
        // return false if otherwise
        
        var hasValidUnitsLeft : Bool = false
        if countOfBoard <= 1 {
            return hasValidUnitsLeft
        }else{
            for columnIndex in 0..<column {
                for rowIndex in 0..<row{
                    if matrix[columnIndex][rowIndex] != nil{
                        if isValidSelectionAtIndex((columnIndex,rowIndex)){
                            hasValidUnitsLeft = true
                            return hasValidUnitsLeft
                        }
                    }
                }
            }
        }
        
        return hasValidUnitsLeft
    }
    
    //helper function
    fileprivate func getTheIndexArrayOfAllNeighbors(_ index:UnitIndex) -> SelectionArray {
        
        var resultArray = SelectionArray()
        if index.0 > 0 { resultArray.append((index.0-1,index.1))}
        if index.0 < column-1 { resultArray.append((index.0+1,index.1))}
        if index.1 > 0 { resultArray.append((index.0,index.1-1))}
        if index.1 < row-1 { resultArray.append((index.0, index.1+1))}
        
        return resultArray
    }
    
    func rearrangeTargetMatrix(_ targetMatrix: inout MatrixArray){
        
        
        //shift all the units down to the bottom
        //by copying all the none-nil value into a new array
        //and adding nil to the end of row if nessessary
        for i in 0..<column{
            var newColumn = [Int?]()
            for j in 0..<row{
                if targetMatrix[i][j] != nil{
                    newColumn.append(targetMatrix[i][j])
                }
            }
            targetMatrix[i] = newColumn
            
            if targetMatrix[i].count < row{
                for _ in 1...(row - targetMatrix[i].count){
                    targetMatrix[i].append(nil)
                }
            }
        }
        
        //shift rows to the left is empty rows exits
        //by copying all the none-empty rows
        //and adding rows of nils at the end of the matrix if nessesary
        var newMatrix = MatrixArray()
        for i in 0..<column{
            var hasElement = false
            for element in targetMatrix[i]{
                if element != nil{
                    hasElement = true
                }
            }
            if hasElement{
                newMatrix.append(targetMatrix[i])
            }
        }
        targetMatrix = newMatrix
        if targetMatrix.count < column{
            let emptyColumn = [Int?](repeating: nil, count: row)
            for _ in 1...(column - targetMatrix.count){
                targetMatrix.append(emptyColumn)
            }
        }
    }

    func setIndexMatrix(){
        indexMatrix = []
        for i in 0..<column{
            var columnArray = [Int?]()
            for j in 0..<row{
                columnArray.append(i*column + j)
            }
            indexMatrix.append(columnArray)
        }
    }
    
    func setPositionDic(){
        positionDic = [:]
        for i in 0..<column{
            for j in 0..<row{
                if let position = indexMatrix[i][j]{
                    positionDic[position] = (i,j)
                }
            }
        }
    }
}

