//
//  ViewController.swift
//  AR-TicTacToe
//
//  Created by Bjarne Møller Lundgren on 20/06/2017.
//  Copyright © 2017 Bjarne Møller Lundgren. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

@available(iOS 13.0, *)
class ViewController: UIViewController, ARSCNViewDelegate {

    // UI
    @IBOutlet weak var planeSearchLabel: UILabel!
    @IBOutlet weak var planeSearchOverlay: UIView!
    @IBOutlet weak var gameStateLabel: UILabel!
    @IBAction func didTapStartOver(_ sender: Any) { reset() }
    @IBOutlet weak var sceneView: ARSCNView!
    
//    @IBOutlet weak var hintToggle: UISegmentedControl!
    var hintToggle: UISegmentedControl!

    var hintsEnabled: Bool = false
    
    @objc func didToggle(_ sender: UISegmentedControl) {
        hintsEnabled = sender.selectedSegmentIndex == 1
        if hintsEnabled {
            showHintsIfEnabled()
        } else {
            moveOverlay.clear()
        }
    }
    
    @objc func didTapUndo() {
        // Need at least 2 states in history (undo human + AI move)
        // If human vs human, just undo 1
        let movesToUndo = playerType[game.currentPlayer == .p1 ? .p2 : .p1] == .computer ? 2 : 1
        
        guard gameHistory.count >= movesToUndo else {
            print("Nothing to undo")
            return
        }
        
        // Pop previous 1 or 2 moves
        let targetState = gameHistory[gameHistory.count - movesToUndo]
        gameHistory.removeLast(movesToUndo)
        
        // Find which positions changed between target state and current state
        // and remove those figures from the scene
        let currentBoard = game.board
        let targetBoard = targetState.board
        
        for row in 0..<currentBoard.count {
            for col in 0..<currentBoard[row].count {
                let key = "\(row)x\(col)"
                if currentBoard[row][col] != targetBoard[row][col] {
                    // This cell changed — remove the figure
                    figures[key]?.removeFromParentNode()
                    figures[key] = nil
                }
            }
        }
        
        // Restore game state without triggering history push
        // Use a flag to suppress history recording during undo
        isUndoing = true
        game = targetState
        isUndoing = false
    }
    
    @MainActor
    private func applyAction(
        _ recommendation: GameAction,
        moveValue: String = "tie",
        remoteness: Int = 0,
        moveType: String = "A",
        to state: GameState
    ) {
        guard let newGameState = state.perform(action: recommendation) else { fatalError() }

        switch recommendation {
        case .put(let at):
            put(piece: figure(for: state.currentPlayer), at: at) {
                DispatchQueue.main.async {
                    self.moveOverlay.clear()
                    self.game = newGameState  // triggers game.didSet → showHintsIfEnabled
                }
            }
        case .move(let from, let to):
            move(from: from, to: to) {
                DispatchQueue.main.async {
                    self.moveOverlay.clear()
                    self.game = newGameState
                }
            }
        }
    }
    
//    @MainActor
//    private func applyAction(_ recommendation: GameAction, moveValue: String = "tie", remoteness: Int = 0, moveType: String = "A", to state: GameState) {
//        guard let newGameState = state.perform(action: recommendation) else { fatalError() }
//
//        if hintsEnabled {
//            if moveType == "M" {
//                // Arrow for movement
//                if case .move(let from, let to) = recommendation,
//                   let fromPos = board.squareToPosition["\(from.x)x\(from.y)"],
//                   let toPos = board.squareToPosition["\(to.x)x\(to.y)"] {
//                    let fromWorld = sceneView.scene.rootNode.convertPosition(fromPos, from: board.node)
//                    let toWorld = sceneView.scene.rootNode.convertPosition(toPos, from: board.node)
//                    moveOverlay.showArrow(from: fromWorld, to: toWorld, moveValue: moveValue, remoteness: remoteness, in: sceneView.scene)
//                }
//            } else {
//                // Dot for placement
//                if case .put(let at) = recommendation,
//                   let squarePosition = board.squareToPosition["\(at.x)x\(at.y)"] {
//                    let worldPosition = sceneView.scene.rootNode.convertPosition(squarePosition, from: board.node)
//                    moveOverlay.showDot(at: worldPosition, moveValue: moveValue, remoteness: remoteness, in: sceneView.scene)
//                }
//            }
//        }
//
//        switch recommendation {
//        case .put(let at):
//            put(piece: figure(for: state.currentPlayer), at: at) {
//                DispatchQueue.main.async {
//                    if !self.hintsEnabled { self.moveOverlay.clear() }
//                    self.game = newGameState
//                }
//            }
//        case .move(let from, let to):
//            move(from: from, to: to) {
//                DispatchQueue.main.async {
//                    if !self.hintsEnabled { self.moveOverlay.clear() }
//                    self.game = newGameState
//                }
//            }
//        }
//    }
    
    
    // State
    private func updatePlaneOverlay() {
        DispatchQueue.main.async {
        self.planeSearchOverlay.isHidden = self.currentPlane != nil
        
        if self.planeCount == 0 {
            self.planeSearchLabel.text = "Move around to allow the app the find a plane"
        } else {
            self.planeSearchLabel.text = "Tap on a plane surface to place board"
        }
            
        }
    }
    
    // Use picker view to change this
    var currentGame: GameDefinition = GameRegistry.tictactoe
    
    var playerType = [
        GamePlayer.p1: GamePlayerType.human,
        GamePlayer.p2: GamePlayerType.computer
    ]
    var planeCount = 0 {
        didSet {
            updatePlaneOverlay()
        }
    }
    var currentPlane:SCNNode? {
        didSet {
            updatePlaneOverlay()
            guard game != nil else { return }
            newTurn()
        }
    }
    let board = Board()
    
    var isUndoing = false
    
    var game:GameState! {
        didSet {
            guard game != nil else { return }
            // push previous move to history before processing new move
            if !isUndoing, let old = oldValue { gameHistory.append(old) }
            gameStateLabel.text = game.currentPlayer.rawValue + ": " + playerType[game.currentPlayer]!.rawValue + " to " + game.mode.rawValue
            
            if let winner = game.currentWinner {
                let alert = UIAlertController(title: "Game Over", message: "\(winner.rawValue) has won!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { action in
                    self.reset()
                }))
                alert.addAction(UIAlertAction(title: "Analysis", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                if currentPlane != nil {
                    showHintsIfEnabled()
                    newTurn()
                }
            }
        }
    }
    
    var gameHistory: [GameState] = [] // contains moves to be undone
    
    var figures:[String:SCNNode] = [:]
    var lightNode:SCNNode?
    var floorNode:SCNNode?
    var draggingFrom:GamePosition? = nil
    var draggingFromPosition:SCNVector3? = nil
    
    // from demo APP
    // Use average of recent virtual object distances to avoid rapid changes in object scale.
    var recentVirtualObjectDistances = [CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let splash = UIView(frame: view.bounds)
//        splash.backgroundColor = .black // match your LaunchScreen
//        splash.tag = 999
//        view.addSubview(splash)
        
        let items = ["Values Off", "Values On"]
        let hintToggle = UISegmentedControl(items: items)
        hintToggle.selectedSegmentIndex = 0
        hintToggle.translatesAutoresizingMaskIntoConstraints = false
        hintToggle.addTarget(self, action: #selector(didToggle(_:)), for: .valueChanged)
        view.addSubview(hintToggle)
        
        NSLayoutConstraint.activate([
                hintToggle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                hintToggle.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        
        self.hintToggle = hintToggle
        
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("Undo", for: .normal)
        undoButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.addTarget(self, action: #selector(didTapUndo), for: .touchUpInside)
        view.addSubview(undoButton)

        NSLayoutConstraint.activate([
            undoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            undoButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        ])
        
//        game = GameState()  // create new game
        sceneView.delegate = self
        
        //sceneView.showsStatistics = true
        //sceneView.antialiasingMode = .multisampling4X
        //sceneView.preferredFramesPerSecond = 60
        //sceneView.contentScaleFactor = 1.3
        sceneView.antialiasingMode = .multisampling4X
        
        sceneView.automaticallyUpdatesLighting = false
        
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(didTap))
        sceneView.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer()
        pan.addTarget(self, action: #selector(didPan))
        sceneView.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer()
        pinch.addTarget(self, action: #selector(didPinch))
        sceneView.addGestureRecognizer(pinch)
        
        reset()
        
    }
    
    // from APples app
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Media.scnassets/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    private func reset() {
        let gamePicker = UIAlertController(title: "Select game!", message: nil, preferredStyle: .alert)
        
//        let picker = UIPickerView()
//        picker.delegate = self
//        picker.dataSource = self
//        picker.frame = CGRect(x: 0, y: 50, width: gamePicker.view.bounds.width - 20, height: 120)
//
//        gamePicker.view.addSubview(picker)
//
//        gamePicker.addAction(UIAlertAction(title: "Next", style: .default))
//        gamePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        for gamedef in GameRegistry.all {
            gamePicker.addAction(UIAlertAction(title: gamedef.displayName, style: .default) {
                [weak self] _ in
                self?.currentGame = gamedef
                self?.showPlayerPicker()
            })
        }
        self.present(gamePicker, animated: true)
    }
    
    private func showPlayerPicker() {
        let alert = UIAlertController(title: "Choose players",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Human vs. Human", style: .default) { [weak self] _ in
            self?.beginNewGame([.p1: .human, .p2: .human])
        })
        alert.addAction(UIAlertAction(title: "Human vs. Computer", style: .default) { [weak self] _ in
            self?.beginNewGame([.p1: .human, .p2: .computer])
        })
        alert.addAction(UIAlertAction(title: "Computer vs. Computer", style: .default) { [weak self] _ in
            self?.beginNewGame([.p1: .computer, .p2: .computer])
        })
        present(alert, animated: true)
    }
    
    private func beginNewGame(_ players:[GamePlayer:GamePlayerType]) {
        playerType = players
        gameHistory = []
        game = GameState()
        removeAllFigures()
        figures.removeAll()
    }
    
    // Call this whenever game state changes — add to game didSet and currentPlane didSet
    private func showHintsIfEnabled() {
        guard game != nil else { return }
        guard hintsEnabled, currentPlane != nil else { return }

        let currGameState = game!
        let currGameDef = currentGame
        let turn = currGameState.currentPlayer == .p1 ? 1 : 2

            Task {
                do {
                    let result = try await UWAPIClient.fetchMoves(
                        board: currGameState.board,
                        turn: turn,
                        game: currGameDef
                    )
                    
                    await MainActor.run {
                        // Build dot positions from all moves
                        var dotMoves: [(position: SCNVector3, moveValue: String)] = []
                        for uwMove in result.all {
                            let action = currGameDef.encoder.decode(move: uwMove.move, board: currGameState.board)
                            if case .put(let at) = action,
                               let squarePos = board.squareToPosition["\(at.x)x\(at.y)"] {
                                let worldPos = sceneView.scene.rootNode.convertPosition(squarePos, from: board.node)
                                dotMoves.append((position: worldPos, moveValue: uwMove.moveValue))
                            }
                        }
                        print("Showing \(dotMoves.count) dots") // debugging to confirm dots are being built
                        moveOverlay.showAllDots(moves: dotMoves, in: sceneView.scene)
                    }
                } catch {
                    print("Hints fetch failed: \(error)")
                }
            }
        }
    
    
    private func newTurn() {
        guard game != nil else { return }
        guard playerType[game.currentPlayer]! == .computer else { return }

        let currGameState = game!
        let currGameDef = currentGame
        let turn = currGameState.currentPlayer == .p1 ? 1 : 2

            Task {
                do {
                    let action = try await UWAPIClient.bestAction(
                        board: currGameState.board,
                        turn: turn,
                        game: currGameDef
                    )
                    await applyAction(
                        action.action,
                        moveValue: action.moveValue,
                        remoteness: action.remoteness,
                        moveType: action.moveType,
                        to: currGameState
                    )
                } catch {
                    print("UWAPI unavailable (\(error)) — using local MinMax")
                    let action = UWAPIGameAI(game: currGameState).bestAction
                    await applyAction(action, to: currGameState)
                }
            }
        }
    
    let moveOverlay = MoveOverlay()

//    @MainActor
//    private func applyAction(_ recommendation: GameAction, moveValue: String = "tie", remoteness: Int = 9, to state: GameState) {
//        guard let newGameState = state.perform(action: recommendation) else {
//            fatalError("Action \(recommendation) is invalid for current state")
//        }
//        
//        // Show the overlay above the target cell
//        if case .put(let at) = recommendation,
//           let squarePosition = board.squareToPosition["\(at.x)x\(at.y)"] {
//            let worldPosition = sceneView.scene.rootNode.convertPosition(
//                squarePosition, from: board.node
//            )
//            moveOverlay.show(
//                at: worldPosition,
//                moveValue: moveValue,
//                remoteness: remoteness,
//                in: sceneView.scene
//            )
//        }
//        
//        switch recommendation {
//        case .put(let at): // put piece
//            put(piece: figure(for: state.currentPlayer), at: at) {
//                DispatchQueue.main.async {
//                    self.moveOverlay.clear() // clear remoteness once piece has been placed
//                    self.game = newGameState
//                }
//            }
//        case .move(let from, let to):
//            move(from: from, to: to) {
//                DispatchQueue.main.async {
//                    self.moveOverlay.clear()
//                    self.game = newGameState
//                }
//            }
////        case .undo(at: let at):
////            undo(at: at) {
////                DispatchQueue.main.async {
////                    self.moveOverlay.clear()
////                    self.game = newGameState
////                }
////            }
//        }
//    }
    
    
    /// Generates and retrieves piece for given player
    private func figure(for player: GamePlayer) -> SCNNode {
        let symbol = player == .p1
            ? currentGame.p1
            : currentGame.p2
//        let figurePlayer: GamePlayer = symbol == "Player" ? .p2 : .p1
        let figurePlayer: GamePlayer = symbol == currentGame.p2 ? .p2 : .p1
        return Figure.figure(for: figurePlayer)
    }
    
    
//    private func newTurn() {
//        guard playerType[game.currentPlayer]! == .computer else { return }
//
//        //run AI on background thread
//        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
//            // let the AI determine which action to perform
//            let action = UWAPIGameAI(game: self.game).bestAction
//            
//            // once an action has been determined, perform it on main thread
//            DispatchQueue.main.async {
//                // perform action or crash (game AI should never return an invalid action!)
//                guard let newGameState = self.game.perform(action: action) else { fatalError() }
//                    
//                // block to execute after we have updated/animated the visual state of the game
//                let updateGameState = {
//                    // for some reason we have to put this in a main.async block in order to actually
//                    // get to main thread. It appears that SceneKit animations do not return on mainthread..
//                    DispatchQueue.main.async {
//                        self.game = newGameState
//                    }
//                }
//                
//                // animate action
//                switch action {
//                case .put(let at):
//                    self.put(piece: Figure.figure(for: self.game.currentPlayer),
//                             at: at,
//                             completionHandler: updateGameState)
//                    
//                case .move(let from, let to):
//                    self.move(from: from,
//                              to: to,
//                              completionHandler: updateGameState)
//                }
//                
//            }
//        }
//    }
    
    private func removeAllFigures() {
        for (_, figure) in figures {
            figure.removeFromParentNode()
        }
    }
    
    private func restoreGame(at position:SCNVector3) {
        board.node.position = position
        sceneView.scene.rootNode.addChildNode(board.node)
        
        let light = SCNLight()
        light.type = .directional
        light.castsShadow = true
        light.shadowRadius = 200
        light.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        light.shadowMode = .deferred
        let constraint = SCNLookAtConstraint(target: board.node)
        lightNode = SCNNode()
        lightNode!.light = light
        lightNode!.position = SCNVector3(position.x + 10, position.y + 10, position.z)
        // lightNode!.eulerAngles = SCNVector3(45.0.degreesToRadians, 0, 0)
        lightNode!.constraints = [constraint]
        sceneView.scene.rootNode.addChildNode(lightNode!)
 
        
        for (key, figure) in figures {
            // yeah yeah, I know I should turn GamePosition into a struct and provide it with
            // Equtable and Hashable then this stupid stringy stuff would be gone. Will do this eventually
            let xyComponents = key.components(separatedBy: "x")
            guard xyComponents.count == 2,
                  let x = Int(xyComponents[0]),
                  let y = Int(xyComponents[1]) else { fatalError() }
            put(piece: figure,
                at: (x: x,
                     y: y))
        }
        
        showHintsIfEnabled() //
    }
    
    private func groundPositionFrom(location:CGPoint) -> SCNVector3? {
        let results = sceneView.hitTest(location,
                                        types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        guard results.count > 0 else { return nil }
        
        return SCNVector3.positionFromTransform(results[0].worldTransform)
    }
    
    private func anyPlaneFrom(location:CGPoint) -> (SCNNode, SCNVector3)? {
        let results = sceneView.hitTest(location,
                                        types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        guard results.count > 0,
              let anchor = results[0].anchor,
              let node = sceneView.node(for: anchor) else { return nil }
        
        return (node, SCNVector3.positionFromTransform(results[0].worldTransform))
    }
    
    private func squareFrom(location:CGPoint) -> ((Int, Int), SCNNode)? {
        guard let _ = currentPlane else { return nil }
        
        let hitResults = sceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly: false,
                                                               SCNHitTestOption.rootNode:       board.node])
        
        for result in hitResults {
            if let square = board.nodeToSquare[result.node] {
                return (square, result.node)
            }
        }
        
        return nil
    }
    
    private func revertDrag() {
        if let draggingFrom = draggingFrom {
            
            let restorePosition = sceneView.scene.rootNode.convertPosition(draggingFromPosition!, from: board.node)
            let action = SCNAction.move(to: restorePosition, duration: 0.3)
            figures["\(draggingFrom.x)x\(draggingFrom.y)"]?.runAction(action)
            
            self.draggingFrom = nil
            self.draggingFromPosition = nil
        }
    }
    
    // MARK: - Gestures
    
    @objc func didPan(_ sender:UIPanGestureRecognizer) {
        guard case .move = game.mode,
              playerType[game.currentPlayer]! == .human else { return }
        
        let location = sender.location(in: sceneView)
        
        switch sender.state {
        case .began:
            print("begin \(location)")
            guard let square = squareFrom(location: location) else { return }
            draggingFrom = (x: square.0.0, y: square.0.1)
            draggingFromPosition = square.1.position
            
        case .cancelled:
            print("cancelled \(location)")
            revertDrag()
            
        case .changed:
            print("changed \(location)")
            guard let draggingFrom = draggingFrom,
                  let groundPosition = groundPositionFrom(location: location) else { return }
            
            let action = SCNAction.move(to: SCNVector3(groundPosition.x, groundPosition.y + Float(Dimensions.DRAG_LIFTOFF), groundPosition.z),
                                        duration: 0.1)
            figures["\(draggingFrom.x)x\(draggingFrom.y)"]?.runAction(action)
            
        case .ended:
            print("ended \(location)")
            
            guard let draggingFrom = draggingFrom,
                let square = squareFrom(location: location),
                square.0.0 != draggingFrom.x || square.0.1 != draggingFrom.y,
                let newGameState = game.perform(action: .move(from: draggingFrom,
                                                              to: (x: square.0.0, y: square.0.1))) else {
                    revertDrag()
                    return
            }
            
            
            
            // move in visual model
            let toSquareId = "\(square.0.0)x\(square.0.1)"
            figures[toSquareId] = figures["\(draggingFrom.x)x\(draggingFrom.y)"]
            figures["\(draggingFrom.x)x\(draggingFrom.y)"] = nil
            self.draggingFrom = nil
            
            // copy pasted insert thingie
            let newPosition = sceneView.scene.rootNode.convertPosition(square.1.position,
                                                                       from: square.1.parent)
            let action = SCNAction.move(to: newPosition,
                                        duration: 0.1)
            figures[toSquareId]?.runAction(action) {
                DispatchQueue.main.async {
                    self.game = newGameState
                }
            }
            
        case .failed:
            print("failed \(location)")
            revertDrag()
            
        default: break
        }
    }
    
    @objc func didTap(_ sender:UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        
        // tap to place board..
        guard let _ = currentPlane else {
            guard let newPlaneData = anyPlaneFrom(location: location) else { return }
            
            let floor = SCNFloor()
            floor.reflectivity = 0
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white

            material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
            floor.materials = [material]
            
            floorNode = SCNNode(geometry: floor)
            floorNode!.position = newPlaneData.1
            sceneView.scene.rootNode.addChildNode(floorNode!)
            
            self.currentPlane = newPlaneData.0
            restoreGame(at: newPlaneData.1)
            
            return
        }
        
        // otherwise tap to place board piece.. (if we're in "put" mode)
        guard case .put = game.mode,
              playerType[game.currentPlayer]! == .human else { return }
        
        if let squareData = squareFrom(location: location),
           let newGameState = game.perform(action: .put(at: (x: squareData.0.0,
                                                             y: squareData.0.1))) {
            
            put(piece: figure(for: game.currentPlayer),
                at: squareData.0) {
                    DispatchQueue.main.async {
                        self.game = newGameState
                    }
            }
            
            
        }
    }
    
    @objc func didPinch(_ sender:UIPinchGestureRecognizer) {
        guard currentPlane != nil else { return }
        
        switch sender.state {
        case .changed:
            let scale = Float(sender.scale)
            board.node.scale = SCNVector3(x: board.node.scale.x * scale, y: board.node.scale.y * scale, z: board.node.scale.z * scale)
            sender.scale = 1.0
        default:
            break
        }
    }
    
    /// animates AI moving a piece
    private func move(from:GamePosition,
                      to:GamePosition,
                      completionHandler: (() -> Void)? = nil) {
        
        let fromSquareId = "\(from.x)x\(from.y)"
        let toSquareId = "\(to.x)x\(to.y)"
        guard let piece = figures[fromSquareId],
              let rawDestinationPosition = board.squareToPosition[toSquareId]  else { fatalError() }
        
        // this stuff will change once we stop putting nodes directly in world space..
        let destinationPosition = sceneView.scene.rootNode.convertPosition(rawDestinationPosition,
                                                                           from: board.node)
        
        // update visual game state
        figures[toSquareId] = piece
        figures[fromSquareId] = nil
        
        // create drag and drop animation
        let pickUpAction = SCNAction.move(to: SCNVector3(piece.position.x, piece.position.y + Float(Dimensions.DRAG_LIFTOFF), piece.position.z),
                                          duration: 0.25)
        let moveAction = SCNAction.move(to: SCNVector3(destinationPosition.x, destinationPosition.y + Float(Dimensions.DRAG_LIFTOFF), destinationPosition.z),
                                        duration: 0.5)
        let dropDownAction = SCNAction.move(to: destinationPosition,
                                            duration: 0.25)
        
        // run drag and drop animation
        piece.runAction(pickUpAction) {
            piece.runAction(moveAction) {
                piece.runAction(dropDownAction,
                                completionHandler: completionHandler)
            }
        }
    }
    
    /// renders user and AI insert of piece
    private func put(piece:SCNNode,
                     at position:GamePosition,
                     completionHandler: (() -> Void)? = nil) {
        let squareId = "\(position.x)x\(position.y)"
        guard let squarePosition = board.squareToPosition[squareId] else { fatalError() }
        
        piece.opacity = 0  // initially invisible
        // // https://stackoverflow.com/questions/30392579/convert-local-coordinates-to-scene-coordinates-in-scenekit
        piece.position = sceneView.scene.rootNode.convertPosition(squarePosition,
                                                                  from: board.node)
        sceneView.scene.rootNode.addChildNode(piece)
        figures[squareId] = piece
        
        let action = SCNAction.fadeIn(duration: 0.5)
        piece.runAction(action,
                        completionHandler: completionHandler)
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // from apples app
        DispatchQueue.main.async {
            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            if let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate {
                
                // Apple divived the ambientIntensity by 40, I find that, at least with the materials used
                // here that it's a bit too bright, so I increased it to 50.
                self.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 50)
            } else {
                self.enableEnvironmentMapWithIntensity(25)
            }
        }
    }
    
    // did at plane(?)
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        planeCount += 1
    }
    
    // did update plane?
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {

    }
    
    // did remove plane?
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if node == currentPlane {
            removeAllFigures()
            lightNode?.removeFromParentNode()
            lightNode = nil
            floorNode?.removeFromParentNode()
            floorNode = nil
            board.node.removeFromParentNode()
            currentPlane = nil
        }
        
        if planeCount > 0 {
            planeCount -= 1
        }
    }
    
}

