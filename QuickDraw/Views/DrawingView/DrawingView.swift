//
//  DrawingView.swift
//  QuickDraw
//
//  Created by Max Chuquimia on 5/3/19.
//  Copyright © 2019 Max Chuquimia. All rights reserved.
//

import Cocoa

class DrawingView: NSView, Watcher {

    private let model = DrawingViewResponder()
    private let colorsRadioGroup = RadioButtonGroup(options: [
        ColorRadioButton(item: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1), title: "1"),
        ColorRadioButton(item: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), title: "2"),
        ColorRadioButton(item: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1), title: "3"),
        ColorRadioButton(item: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), title: "4"),
        ColorRadioButton(item: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1), title: "5"),
    ])
    private let shapesRadioGroup = RadioButtonGroup<DrawingViewResponder.Shape, ShapeRadioButton>(options: [
        ShapeRadioButton(item: .line),
        ShapeRadioButton(item: .arrow),
        ShapeRadioButton(item: .rect),
        ShapeRadioButton(item: .circle),
    ])
    private let brush: InteractionDisabledView = create {
        $0.setFrameSize(NSSize(width: 6, height: 6))
        $0.wantsLayer = true
        $0.layer?.cornerRadius = $0.frame.size.height / 2.0
    }

    override var mouseDownCanMoveWindow: Bool { return false }
    override var acceptsFirstResponder: Bool { return true }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        model.drawings += weak(Function.redraw(renderables:))
        model.colorKeyboardKeyHandler += weak(Function.keyboard(selectedColor:))
        model.shapeKeyboardKeyHandler += weak(Function.keyboard(selectedShape:))
        model.isTracking += weak(Function.model(isTracking:))
        colorsRadioGroup.selectedItem += weak(Function.update(selectedColor:))
        shapesRadioGroup.selectedItem += weak(Function.update(selectedShape:))
        createLayout()

        becomeFirstResponder()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        NSTrackingArea.setup(in: self)

        guard let undoManager = window?.undoManager else { return }
        model.undoManager = undoManager
    }

    private func createLayout() {
        addSubview(brush)

        colorsRadioGroup.translatesAutoresizingMaskIntoConstraints = false
        addSubview(colorsRadioGroup)

        shapesRadioGroup.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shapesRadioGroup)

        NSLayoutConstraint.activate(
            colorsRadioGroup.leftAnchor.constraint(equalTo: leftAnchor, constant: 30),
            colorsRadioGroup.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),

            shapesRadioGroup.leftAnchor.constraint(equalTo: colorsRadioGroup.rightAnchor, constant: 50),
            shapesRadioGroup.bottomAnchor.constraint(equalTo: colorsRadioGroup.bottomAnchor)
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        model.drawings.value.forEach { $0.render() }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        model.mouseDown(with: event, in: self)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        model.mouseDragged(with: event, in: self)
        updateBrush(for: event)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        updateBrush(for: event)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        model.mouseUp(with: event)
    }

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        model.keyDown(with: event)
    }

    // Stop the bell sound from playing on known key presses that the system doesn't know we will handle
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        return model.canHandle(key: event.keyCode)
    }
}

// MARK: - Bindings
extension DrawingView {

    func redraw(renderables: [Renderable]) {
        needsDisplay = true
    }

    func model(isTracking: Bool) {
        brush.isHidden = isTracking
        Log("Updated Brush", brush.isHidden)
        needsDisplay = true
    }

    func keyboard(selectedColor index: Int) {
        colorsRadioGroup.select(item: index)
    }

    func keyboard(selectedShape index: Int) {
        shapesRadioGroup.select(item: index)
    }

    func update(selectedColor: NSColor) {
        model.selectedColor = selectedColor
        brush.layer?.backgroundColor = selectedColor.cgColor
        shapesRadioGroup.buttons.forEach({ $0.tintColor = selectedColor })
    }

    func update(selectedShape: DrawingViewResponder.Shape) {
        model.selectedShape = selectedShape
    }
}

// MARK: - Private
private extension DrawingView {

    func updateBrush(for event: NSEvent) {
        let location = event.locationInWindow.offset(x: -brush.frame.width / 2, y: -brush.frame.width / 2)
        brush.setFrameOrigin(location)
    }
}
