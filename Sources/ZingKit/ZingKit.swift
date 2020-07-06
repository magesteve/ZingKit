//
//  ZingKit.swift
//  ZingKitLab
//
//  Created by Steve Sheets on 5/21/19.
//  Copyright © 2020 Steve Sheets. All rights reserved.
//  Website: http://github.com/magesteve/zingkit
//

/// MARK: Structure

/// Abstract Structure for ZingKit
public struct ZingKit {
    
    /// Zing Version number
    public static let kitVersion = 1
    
}

#if !os(macOS)

import UIKit

/// Swift based Animation Sequencer for UIView style animation.
///
/// Using chained dot notation, a developer can create a sequence of animation commands (internally called a cell).
/// Once created, the sequence can be executed (start the animation running), and once running, the sequence can be
/// safely canceled.
///
/// Most cells are executed in a sequential manner, where each cell is started and finished before the next cell is
/// started. Thus a list of cells (the Zing object) starts when the first cell starts, and ends when the last cell
/// finishes. Most cells have associated closures.
///
/// UIView style animation involves changing animatable properties of a UIVIew within an UIView.animate() call.
/// Apple's documentation describes this in more detail.  An animation cell defined by the thenAnimate() call invokes
/// the associated closure within a UIView.animate() call.
///
/// Other cells can be timed delays (nothing happening until the delay is over), non-animated immediate actions
/// (ie. not within UIView.animate call) or immediate animated actions (called within UIView.animate). Both of the
/// last two immediate actions do not wait for the animation to complete but immediately calls the next cell in
/// the sequence.
///
/// Zing is well suited for simple sequence of UIView animation. It is not designed for interactive animations,
/// thought it can animate background views within game.
///
public class Zing: NSObject {
    
    /// Simple closure definition (no parameters, no return results) to define closures for animation actions.
    public typealias ZingActionClosure = () -> Void
    
    /// Internal private enum type to define type of cells
    ///
    /// - thenAnimation: Normal animation. Has a closure and duration associated with the animation. The next cell starts
    /// the animation is completed.
    /// - thenDelay: Delay action, with a duraction, but not closure associated.
    /// - withAction: Non-animated immediate action, with no duraction, and next cell is immediately invoked.
    /// - withAnimate: Animated immediate action, with a duraction for the animation, but the next cell is immediately invoked.
    private enum ZingType {
        case thenAnimation
        case thenDelay
        case withAction
        case withAnimate
    }
    
    /// Internal private structure to define a cell.
    private struct ZingCell {
        /// Type of Cell (thenAnimation, thenDelay, withAction, withAnimate)
        let type: ZingType
        /// Optional Duraction of time in seconds (Double value). Zero or negative value means no duraction.
        let duration: TimeInterval
        /// Optional Closure associated with cell.
        let action: ZingActionClosure?
    }
    
    /// Internal storage of all currently executing Zings.
    ///
    /// Since a zing is stored here when executiong starts, and removed when execution ends, it is posisble to define
    /// and then execute a Zing, and not keep reference to it (ie. fire and forget).
    private static var zingBag =  Set<Zing>()
    
    /// Internal state boolean to track if Zing is exdecuting.
    private(set) var zingExecuting = false;
    
    /// Internal position of current cell within the zing (zero-count, -1 indicating not executing).
    private var zingPositon = -1
    
    /// Optional Title of the Zing. Since the zing is stored with the bag, while executing, this title can be used
    /// to fetch the zing from the bag, or cancel the zing.
    private var zingTitle: String?
    
    /// If this private flag is set, when the last cells has completed it's animation, the sequence is started over from the
    /// beginning. The default value is false. Use the autoloop() method to set or unset this value.
    private var zingAutoloop = false
    
    /// When a zing is canceled (using either cancel methods), this closure is invoked. It is a good idea to set the
    /// modified properties of the views to their final stats.
    private var zingCancelAction: Zing.ZingActionClosure?
    
    /// Optionally to using zingCancelAction, when this flag is set (using the cancelReset() method), all the animated cells
    /// are quickly invoked. This should set the modified properties of the views to their final stats.
    private var zingCancelReset = false
    
    /// Private duraction of the cancel actions (using zingCancelAction style or zingCancelReset styles). If the duraction
    /// is more than zero (0.0), the action is invoked within a UIView.animation() method. If it is zero or less, than the
    /// cancel action happens immediately (without animation).
    private var zingCancelDuration = 0.0
    
    /// Regardless if the sequence finishes or is canceled, this closure is invoked as the last step of the animation.
    /// It is not called within a UIView.animation() method.
    private var zingFinishAction: Zing.ZingActionClosure?
    
    /// Private list of cells
    private var zingItems = [ZingCell]();
    
    /// Public static method to create a Zing sequence.
    ///
    /// If a Zing sequence with the given title already exists, it will be canceled.
    ///
    /// - Parameter title: Optional string title of the sequence.
    /// - Returns: Returns newly created Zing.
    public static func start(title: String? = nil) -> Zing {
        if let title = title {
            Zing.cancel(title: title)
        }
        
        return Zing(title: title)
    }
    
    /// Public static method to find the executing Zing sequence with this title.
    ///
    /// - Parameter title: String title to find
    /// - Returns: Zing sequence with the given title found. The Zing will continue to execute.
    private static func find(title: String) -> Zing? {
        guard !title.isEmpty else { return nil }
        
        for z in Zing.zingBag {
            if let t = z.zingTitle {
                if t == title {
                    return z
                }
            }
        }
        
        return nil;
    }
    
    /// Public static method to cancel the executing Zing sequence with this title.
    ///
    /// Note: canceling a excecuting Zing removes it from the bag (and may unload the object).
    ///
    /// - Parameter title: String title to find
    public static func cancel(title: String) {
        if let z = Zing.find(title: title) {
            z.cancel()
        }
    }
    
    /// Default Init method for Zing
    ///
    /// - Parameter title: Optional Title for Zing.
    public init(title: String?) {
        super.init()
        
        self.zingTitle = title
    }
    
    /// Privaet method to add cell with given properties into the list of cells at the end.
    ///
    /// - Parameters:
    ///   - type: Type of Cell
    ///   - duration: Duraction of action of cell
    ///   - action: Optional Action of cell
    /// - Returns: The current Zing (allowing dot notation chaining).
    private func addCell(type: ZingType, duration: TimeInterval, action: Zing.ZingActionClosure?) -> Zing {
        let cell = ZingCell(type: type, duration: duration, action: action)
        
        zingItems.append(cell)
        
        return self
    }
    
    /// Add Cell to Zing that handles delay of given time.
    ///
    /// - Parameter duration: Amount of time, in seconds, of the delay.
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func thenDelay(duration: TimeInterval) -> Zing {
        return self.addCell(type: .thenDelay, duration: duration, action: nil)
    }
    
    /// Add cell to Zing with animation closure and given delay
    ///
    /// - Parameters:
    ///   - duration: Amount of time, in seconds, of the animation.
    ///   - action: Closure to be invoked within a UIView.animation() call.
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func thenAnimate(duration: TimeInterval, action: Zing.ZingActionClosure?) -> Zing {
        return self.addCell(type: .thenAnimation, duration: duration, action: action)
    }
    
    /// Add cell to Zing with animation closure and given delay, in the immediate style (no delay
    /// before invoking the next cell).
    ///
    /// - Parameters:
    ///   - duration: Amount of time, in seconds, of the animation (but not delay before invoking next cell).
    ///   - action: Closure to be invoked within UIView.animation() call.
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func withAnimate(duration: TimeInterval, action: Zing.ZingActionClosure?) -> Zing {
        return self.addCell(type: .withAnimate, duration: duration, action: action)
    }
    
    /// Add cell to Zing with closure to be invoked immediately (no delay before invoking next cell), but
    /// not within a UIView.animation() call. This method is used to set non UIView animatable properties.
    ///
    /// - Parameter action: Closure to be invoked (not within a UIView.animation() call).
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func withAction(action: Zing.ZingActionClosure?) -> Zing {
        return self.addCell(type: .withAction, duration: 0.0, action: action)
    }
    
    /// Defing closure to be invoked when Zing is cancled.
    ///
    /// - Parameter action: Standard closure (no parameters, no results) to be invovked.
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func onCancel(action: Zing.ZingActionClosure?) -> Zing {
        zingCancelAction = action
        
        return self
    }
    
    /// Defing closure to be invoked when Zing is finished.
    ///
    /// - Parameter action: Standard closure (no parameters, no results) to be invovked.
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func onFinish(action: Zing.ZingActionClosure?) -> Zing {
        zingFinishAction = action
        
        return self
    }
    
    /// Set the zingAutoloop property with this method.
    ///
    /// - Parameter flag: Bool setting for the flag, default is true.
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func autoloop(flag: Bool = true) -> Zing {
        zingAutoloop = flag
        
        return self
    }
    
    /// Set cancel properties of the Zing sequence
    ///
    /// - Parameters:
    ///   - flag: Bool setting for then zingCancelReset property. Default is true.
    ///   - duraction: Duration setting for the zingCancelDuration property. Default is 0.0 (no animation on cancel).
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func cancelReset(flag: Bool = true, duraction: TimeInterval = 0.0) -> Zing {
        zingCancelReset = flag
        zingCancelDuration = duraction
        
        return self
    }
    
    /// Copy the cells of the given Zing at the end of the list of cells of this Zing.
    ///
    /// - Parameter zing: Zing object to copy.
    /// - Returns: The current Zing (allowing dot notation chaining).
    public func splice(zing: Zing) -> Zing {
        for cell in zing.zingItems {
            zingItems.append(cell)
        }
        
        return self
    }
    
    /// Public method to start execution of the sequence.
    ///
    /// Only starts if sequence is not running. Also add Zing to the bag for duraction of animiaton.
    ///
    /// - Returns: The current Zing (allowing dot notation chaining). This value is Discarable.
    @discardableResult
    public func execute() -> Zing {
        if !zingExecuting {
            zingExecuting = true
            
            Zing.zingBag.insert(self)
            
            nextCell()
        }
        
        return self
    }
    
    /// Public method to clean up sequence to initial blank state.
    ///
    /// This function will only clean up if the sequence is not running.
    public func cleanup() {
        if !zingExecuting {
            zingExecuting = false
            zingPositon = -1
            zingTitle = ""
            zingCancelDuration = 0.0
            zingAutoloop = false
            zingCancelReset = false
            zingCancelAction = nil
            zingFinishAction = nil
            zingItems.removeAll()
        }
    }
    
    /// Public method to cancel a executing Zing sequence.
    ///
    /// If defined, the cancel actions and/or the finish closure will be invoked.
    public func cancel() {
        if zingExecuting {
            let start = zingPositon
            let end = zingItems.count
            
            if zingCancelReset {
                if zingCancelDuration<=0.0 {
                    for n in start..<end {
                        if let action = self.zingItems[n].action {
                            action()
                        }
                    }
                }
                else {
                    let listItems = zingItems;
                    
                    UIView.animate(withDuration: zingCancelDuration) {
                        for n in start..<end {
                            if let action = listItems[n].action {
                                action()
                            }
                        }
                    }
                }
            }
            
            if let zingCancelAction = zingCancelAction {
                if zingCancelDuration<=0.0 {
                    zingCancelAction()
                }
                else {
                    UIView.animate(withDuration: zingCancelDuration) {
                        zingCancelAction()
                    }
                }
            }
            
            if let zingFinishAction = zingFinishAction {
                zingFinishAction()
            }
            
            Zing.zingBag.remove(self)
            
            zingExecuting = false
            zingPositon = -1
        }
    }
    
    /// Private method to invoke next cell after given time.
    ///
    /// Techincally any negative or zero value will still create a timer, just one with a very small value.
    /// For all practical purpose, this mean an immediate starting of the next cell.
    ///
    /// - Parameter time: TimeInterval duration of timer. The default is 0.0.
    private func nextCellTimer(withDuration time: TimeInterval = 0.0) {
        var duraction = time
        if duraction<=0.001 {
            duraction = 0.001
        }
        
        Timer.scheduledTimer(withTimeInterval: duraction, repeats: false) { [weak self] timer in
            if let strongSelf = self {
                strongSelf.nextCell()
            }
        }
    }
    
    /// Private internal method to actually parse next Cell.
    private func nextCell() {
        if zingExecuting {
            zingPositon = zingPositon + 1
            
            if zingPositon<zingItems.count {
                var duration = zingItems[zingPositon].duration
                duration = duration<0.001 ? 0.001 : duration
                let action = zingItems[zingPositon].action
                let type = zingItems[zingPositon].type
                
                switch type {
                case .thenAnimation:
                    if let action = action {
                        UIView.animate(withDuration: duration,
                                       animations: {
                                        action()
                        },
                                       completion:{ [weak self] flag in
                                        if let strongSelf = self {
                                            strongSelf.nextCell()
                                        }
                            }
                        )
                    }
                    else {
                        nextCellTimer(withDuration: duration)
                    }
                    
                case .thenDelay:
                    nextCellTimer(withDuration: duration)
                    
                case .withAnimate:
                    if let action = action {
                        UIView.animate(withDuration: duration) {
                            action()
                        }
                    }
                    
                    nextCellTimer()
                    
                case .withAction:
                    if let action = action {
                        action()
                    }
                    
                    nextCellTimer()
                }
            }
            else {
                if zingAutoloop {
                    zingPositon = -1
                    
                    nextCellTimer()
                }
                else {
                    if let zingFinishAction = zingFinishAction {
                        zingFinishAction()
                    }
                    
                    Zing.zingBag.remove(self)
                }
            }
        }
    }
    
}

#endif
