//
//  LevelViewController+Controls.swift
//  NotPeggle
//
//  Created by Ying Gao on 27/2/21.
//

import UIKit

extension LevelViewController {

    // ======================== //
    // MARK: Text Field Methods
    // ======================== //

    /// Sets the text field to hide the keyboard after hitting return.
    /// Taken from Apple's Storyboard tutorial (Connect the UI to Code)
    /// https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    /// Sets the model's name after the user has finished typing.
    /// Taken from Apple's Storyboard tutorial (Connect the UI to Code)
    /// https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        guard
            let newName = textField.text,
            model.levelName != newName
        else {
            return
        }

        if !newName.contains("/") {
            model.levelName = newName
        } else {
            alertOnInvalidName()
            textField.text = model.levelName
        }
    }

    private func alertOnInvalidName() {
        let alert = UIAlertController(
            title: "Invalid name!",
            message: "Level titles should not have \"/\" characters.\nPlease try again",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    /// Moves the display up to show the user what they have added into the text field.
    /// Credit: https://fluffy.es/move-view-when-keyboard-is-shown/
    @objc func keyboardWillShow(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo,
            let keyBoardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else {
           return
        }
        let keyboardSize = keyBoardFrame.cgRectValue
        view.frame.origin.y = 0 - keyboardSize.height
    }

    /// Moves the display back down when no longer needed.
    /// Credit: https://fluffy.es/move-view-when-keyboard-is-shown/
    @objc func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }

}

extension LevelViewController {

    // ============== //
    // MARK: Gestures
    // ============== //

    /// Detects a tap on the peg board and either creates or deletes a peg centered on the location of the tap.
    @IBAction private func managePegsOnBoard(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: gameArea)
        switch mode {
        case .addBlue:
            addNewPeg(color: .blue, at: location)
        case .addOrange:
            addNewPeg(color: .orange, at: location)
        case .addGreen:
            addNewPeg(color: .green, at: location)
        case .addBlock:
            addBlock(at: location)
        case .delete:
            deletePeg(at: location)
        case .none:
            fatalError("View Controller should always load with a mode")
        }
    }

    func addNewPeg(color: Color, at location: CGPoint) {
        let peg = Converter.pegFromCGPoint(color: color, at: location)
        model.insert(peg: peg)
    }

    func deletePeg(at location: CGPoint) {
        let coordinates = Converter.pointFromCGPoint(point: location)
        let pegtoRemove = model.firstPeg(where: { $0.contains(point: coordinates) })
        let blocktoRemove = model.firstBlock(where: { $0.contains(point: coordinates) })
        if let deletedPeg = pegtoRemove {
            model.delete(peg: deletedPeg)
        } else if let deletedBlock = blocktoRemove {
            model.delete(block: deletedBlock)
        }
    }

    func addBlock(at location: CGPoint) {
        let block = Block(center: Converter.pointFromCGPoint(point: location))
        model.insert(block: block)
    }

}

extension LevelViewController {

    // ================================ //
    // MARK: Level Object View Handlers
    // ================================ //

    /// Deletes a peg from data after a long press has been applied to and refreshes UI to show the deletion.
    func holdToDeletePeg(_ gesture: UILongPressGestureRecognizer) {
        guard let view = gesture.view as? PegView else {
            fatalError("Gesture should target a PegView")
        }
        let peg = Converter.pegFromView(view)
        model.delete(peg: peg)
    }

    /// Drags a peg to a position that does not clash with pegs and saves its position.
    func dragPeg(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? PegView else {
            fatalError("Gesture should be attached to a PegView")
        }
        let peg = Converter.pegFromView(view)
        let location = gesture.location(in: gameArea)
        let newCenter = Converter.pointFromCGPoint(point: location)
        let newPeg = peg.recenterTo(newCenter)

        if model.canAccommodate(newPeg, excluding: peg) {
            view.center = location
            model.replace(peg, with: newPeg)
        }
    }

    /// Deletes a peg from data after a long press has been applied to and refreshes UI to show the deletion.
    func holdToDeleteBlock(_ gesture: UILongPressGestureRecognizer) {
        guard let view = gesture.view as? BlockView else {
            fatalError("Gesture should target a PegView")
        }
        let block = Converter.blockFromView(view)
        model.delete(block: block)
    }

    /// Drags a peg to a position that does not clash with pegs and saves its position.
    func dragBlock(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view as? BlockView else {
            fatalError("Gesture should be attached to a PegView")
        }
        let block = Converter.blockFromView(view)
        let location = gesture.location(in: gameArea)
        let newCenter = Converter.pointFromCGPoint(point: location)
        let newBlock = block.recenterTo(newCenter)

        if model.canAccommodate(newBlock, excluding: block) {
            view.center = location
            model.replace(block, with: newBlock)
        }
    }

    func rotateBlock(_ gesture: UIRotationGestureRecognizer) {
        guard let view = gesture.view as? BlockView else {
            fatalError("Gesture should be attached to a BlockView")
        }
        let block = Converter.blockFromView(view)
        let angle = gesture.rotation
        let newBlock = block.rotate(angle: angle.native)

        if model.canAccommodate(newBlock, excluding: block) {
            print(angle)
            view.rotate(to: angle)
            model.replace(block, with: newBlock)
        }
    }

}
