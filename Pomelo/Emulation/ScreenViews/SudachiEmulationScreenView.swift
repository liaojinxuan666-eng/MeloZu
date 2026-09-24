//
//  SudachiEmulationScreenView.swift
//  Pomelo-V2
//
//  Created by Stossy11 on 16/7/2024.
//

import SwiftUI
import Sudachi
import MetalKit

class SudachiScreenView: UIView {
    var primaryScreen: UIView!
    var portraitconstraints = [NSLayoutConstraint]()
    var landscapeconstraints = [NSLayoutConstraint]()
    var fullscreenconstraints = [NSLayoutConstraint]()
    let sudachi = Sudachi.shared
    let userDefaults = UserDefaults.standard
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if userDefaults.bool(forKey: "isfullscreen") {
            // setupSudachiScreenforcools()
            setupSudachiScreen2()
        } else if userDefaults.bool(forKey: "isairplay") {
            setupSudachiScreen2()
        } else if userDefaults.bool(forKey: "169fullscreen") { // this is for the 16/9 aspect ratio full screen
            setupSudachiScreenforcools()
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            setupSudachiScreenforiPad()
        } else {
            setupSudachiScreen()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if userDefaults.bool(forKey: "isfullscreen") {
            setupSudachiScreen2()
        } else if userDefaults.bool(forKey: "isairplay") {
            setupSudachiScreen2()
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            setupSudachiScreenforiPad()
        } else {
            setupSudachiScreen()
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        if !userDefaults.bool(forKey: "disabletouch") {
            print("Location: \(touch.location(in: primaryScreen))")
            sudachi.touchBegan(at: touch.location(in: primaryScreen), for: 0)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if !userDefaults.bool(forKey: "disabletouch") {
            print("Touch Ended")
            sudachi.touchEnded(for: 0)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        if !userDefaults.bool(forKey: "disabletouch") {
            let location = touch.location(in: primaryScreen)
            print("Location Moved: \(location)")
            sudachi.touchMoved(at: location, for: 0)
        }
    }
    
    func setupSudachiScreen2() {
        primaryScreen = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        primaryScreen.translatesAutoresizingMaskIntoConstraints = false
        primaryScreen.clipsToBounds = true
        if userDefaults.bool(forKey: "isairplay") {
            primaryScreen.layer.backgroundColor = UIColor.black.cgColor
        } else {
            primaryScreen.layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
        }
        addSubview(primaryScreen)

        fullscreenconstraints = [
            primaryScreen.topAnchor.constraint(equalTo: topAnchor),
            primaryScreen.leadingAnchor.constraint(equalTo: leadingAnchor),
            primaryScreen.trailingAnchor.constraint(equalTo: trailingAnchor),
            primaryScreen.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        addConstraints(fullscreenconstraints)
    }
    
    func setupSudachiScreenforcools() { // oh god this took a long time, im going insane
        primaryScreen = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        primaryScreen.translatesAutoresizingMaskIntoConstraints = false
        primaryScreen.clipsToBounds = true
        
        addSubview(primaryScreen)
        
        primaryScreen.layer.cornerRadius = 5
        primaryScreen.layer.masksToBounds = true

        
        NSLayoutConstraint.activate([
            primaryScreen.centerXAnchor.constraint(equalTo: centerXAnchor),
            primaryScreen.centerYAnchor.constraint(equalTo: centerYAnchor),
            primaryScreen.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            primaryScreen.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        ])
        
        let aspectRatio: CGFloat = 16.0/9.0
        let aspectRatioConstraint = NSLayoutConstraint(
            item: primaryScreen ?? UIView(),
            attribute: .width,
            relatedBy: .equal,
            toItem: primaryScreen,
            attribute: .height,
            multiplier: aspectRatio,
            constant: 0
        )
        aspectRatioConstraint.priority = .required - 1
        primaryScreen.addConstraint(aspectRatioConstraint)
        
        let heightConstraint = primaryScreen.heightAnchor.constraint(equalTo: heightAnchor)
        heightConstraint.priority = .defaultHigh
        let widthConstraint = primaryScreen.widthAnchor.constraint(equalTo: widthAnchor)
        widthConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([heightConstraint, widthConstraint])
        
        // Make primaryScreen fill container
        fullscreenconstraints = [
            primaryScreen.topAnchor.constraint(equalTo: primaryScreen.topAnchor),
            primaryScreen.bottomAnchor.constraint(equalTo: primaryScreen.bottomAnchor),
            primaryScreen.leadingAnchor.constraint(equalTo: primaryScreen.leadingAnchor),
            primaryScreen.trailingAnchor.constraint(equalTo: primaryScreen.trailingAnchor)
        ]
        
        NSLayoutConstraint.activate(fullscreenconstraints)
    }
    
    func setupSudachiScreenforiPad() {
        primaryScreen = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        primaryScreen.translatesAutoresizingMaskIntoConstraints = false
        primaryScreen.clipsToBounds = true
        primaryScreen.layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
        primaryScreen.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        primaryScreen.layer.borderWidth = 3
        primaryScreen.layer.cornerCurve = .continuous
        primaryScreen.layer.cornerRadius = 10
        addSubview(primaryScreen)
        
        
        portraitconstraints = [
            primaryScreen.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            primaryScreen.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
            primaryScreen.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
            primaryScreen.heightAnchor.constraint(equalTo: primaryScreen.widthAnchor, multiplier: 9 / 16),
        ]
        
        landscapeconstraints = [
            primaryScreen.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 50),
            primaryScreen.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -100),
            primaryScreen.widthAnchor.constraint(equalTo: primaryScreen.heightAnchor, multiplier: 16 / 9),
            primaryScreen.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
        ]

        
        updateConstraintsForOrientation()
    }
    
    
    
    func setupSudachiScreen() {
        primaryScreen = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        primaryScreen.translatesAutoresizingMaskIntoConstraints = false
        primaryScreen.clipsToBounds = true
        primaryScreen.layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
        primaryScreen.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        primaryScreen.layer.borderWidth = 3
        primaryScreen.layer.cornerCurve = .continuous
        primaryScreen.layer.cornerRadius = 10
        addSubview(primaryScreen)
        
        
        portraitconstraints = [
            primaryScreen.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            primaryScreen.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
            primaryScreen.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
            primaryScreen.heightAnchor.constraint(equalTo: primaryScreen.widthAnchor, multiplier: 9 / 16),
        ]
        
        landscapeconstraints = [
            primaryScreen.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            primaryScreen.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            primaryScreen.widthAnchor.constraint(equalTo: primaryScreen.heightAnchor, multiplier: 16 / 9),
            primaryScreen.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
        ]
        
        updateConstraintsForOrientation()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateConstraintsForOrientation()
    }
    
    private func updateConstraintsForOrientation() {
        
        if userDefaults.bool(forKey: "isfullscreen") {
            removeConstraints(portraitconstraints)
            removeConstraints(landscapeconstraints)
            removeConstraints(fullscreenconstraints)
            addConstraints(fullscreenconstraints)
        } else {
            removeConstraints(portraitconstraints)
            removeConstraints(landscapeconstraints)
            
            let isPortrait = getInterfaceOrientation().isPortrait
            addConstraints(isPortrait ? portraitconstraints : landscapeconstraints)
        }
    }
    
    func getInterfaceOrientation() -> UIInterfaceOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let orientation = windowScene.keyWindow?.windowScene?.interfaceOrientation
        else {
            return .unknown
        }
        return orientation
    }
}
