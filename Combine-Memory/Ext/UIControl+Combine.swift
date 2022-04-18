//
/*
* ****************************************************************
*
* 文件名称 : UIControl+Combine
* 作   者 : Created by 坤
* 创建时间 : 2022/4/18 14:44
* 文件描述 : 
* 注意事项 : 
* 版权声明 : 
* 修改历史 : 2022/4/18 初始版本
*
* ****************************************************************
*/

import Foundation
import UIKit
import Combine


extension UIButton {

    public func subscriber(forTitle state: UIControl.State) -> Subscribers.Sink<String, Never> {
        Subscribers.Sink<String, Never> { _ in
            print("Subscriber<Button.title> finished! ____&")
        } receiveValue: { [weak self] value in
            self?.setTitle(value, for: state)
        }
    }
}


extension UIControl {

    public func publisher1(forAction event: UIControl.Event) -> AnyPublisher<UIControl, Never> {
        #if true
        let publisher = ControlPublisher1(control: self, event: event)
            .eraseToAnyPublisher()
        return publisher

        #else

        let eventKey = event.publisherActionKey
        if let publisher = objc_getAssociatedObject(self, eventKey) as? AnyPublisher<UIControl, Never> {
            return publisher
        } else {
            let publisher = ControlPublisher1(control: self, event: event)
                .eraseToAnyPublisher()
            objc_setAssociatedObject(self, eventKey, publisher, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return publisher
        }
        #endif
    }
}

fileprivate final class ControlPublisher1<Control: UIControl>: Publisher {

    typealias Failure = Never
    typealias Output = Control

    private weak var control: Control?
    private let event: UIControl.Event

    private var cancelStore: [(() -> Void)] = []

    init(control: Control, event: UIControl.Event) {
        self.control = control
        self.event = event
    }

    deinit {
        cancelStore.forEach { $0() }
        Swift.print("ControlPublisher1<\(type(of: control))> deinit! ____#")
    }

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Control == S.Input {
        let subscription = ControlSubscription(subscriber: subscriber, control: control, event: event)
        //cancelStore.append({ subscription.cancel() })
        subscriber.receive(subscription: subscription)
    }
}

fileprivate final class ControlSubscription<S: Subscriber, Control: UIControl>: Combine.Subscription where S.Input == Control, S.Failure == Never {

    private weak var control: Control?
    private var subscriber: S?

    init(subscriber: S, control: Control?, event: UIControl.Event) {
        print("ControlSubscription<\(type(of: control))> init! ____^")
        self.control = control
        self.subscriber = subscriber
        control?.addTarget(self, action: #selector(doAction(sender:)), for: event)
    }

    deinit {
        Swift.print("ControlSubscription<\(type(of: control))> deinit! ____#")
    }

    func request(_ demand: Subscribers.Demand) {
        guard demand > 0 else {
            cancel()
            return
        }
    }

    /// 释放内存
    func cancel() {
        subscriber = nil
        print("ControlSubscription<\(type(of: control))> cancel! ____@")
    }

    @objc private func doAction(sender: UIControl) {
        if let control = control {
            _ = subscriber?.receive(control)
        }
    }
}


extension UIControl {

    func publisher2(forAction event: UIControl.Event) -> AnyPublisher<UIControl, Never> {
        let eventKey = event.publisherActionKey
        if let publisher = objc_getAssociatedObject(self, eventKey) as? AnyPublisher<UIControl, Never> {
            return publisher
        } else {
            let publisher = ControlPublisher2(control: self, event: event)
                .eraseToAnyPublisher()
            objc_setAssociatedObject(self, eventKey, publisher, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return publisher
        }
    }
}

fileprivate final class ControlPublisher2: Publisher {

    typealias Failure = Never
    typealias Output = UIControl

    private weak var control: UIControl?

    // 经典类型摸除, 更多请参考:
    // https://www.swiftbysundell.com/articles/type-erasure-using-closures-in-swift/
    // https://www.swiftbysundell.com/articles/different-flavors-of-type-erasure-in-swift/
    private var sendControls: [((UIControl) -> Void)] = []
    private var sendFinished: [(() -> Void)] = []

    init(control: UIControl, event: UIControl.Event) {
        self.control = control
        control.addTarget(self, action: #selector(doAction(sender:)), for: event)
    }

    deinit {
        sendFinished.forEach { $0() }

        sendControls.removeAll()
        sendFinished.removeAll()

        Swift.print("ControlPublisher2<\(type(of: control))> deinit! ____#")
    }

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, UIControl == S.Input {
        sendControls.append({ ctr in _ = subscriber.receive(ctr) })
        sendFinished.append({ subscriber.receive(completion: .finished) })
        subscriber.receive(subscription: Subscriptions.empty)
    }

//    func share() -> ControlPublisher2 {
//        return self
//    }

    @objc private func doAction(sender: UIControl) {
        if let control = control {
            sendControls.forEach { $0(control) }
        }
    }
}



@available(iOS 13.0, *)
fileprivate struct AssociatedActionKeys {
    static var kDefaultKey: Void?

    static var touchDown: Void?
    static var touchDownRepeat: Void?
    static var touchDragInside: Void?
    static var touchDragOutside: Void?
    static var touchDragEnter: Void?
    static var touchDragExit: Void?
    static var touchUpInside: Void?
    static var touchUpOutside: Void?
    static var touchCancel: Void?
    static var valueChanged: Void?
    static var primaryActionTriggered: Void?

    @available(iOS 14.0, *)
    static var menuActionTriggered: Void?

    static var editingDidBegin: Void?
    static var editingChanged: Void?
    static var editingDidEnd: Void?
    static var editingDidEndOnExit: Void?
    static var allTouchEvents: Void?
    static var allEditingEvents: Void?
    static var applicationReserved: Void?
    static var systemReserved: Void?
    static var allEvents: Void?
}

@available(iOS 13.0, *)
fileprivate extension UIControl.Event {

    var publisherActionKey: UnsafeRawPointer {

        if #available(iOS 14.0, *) {
            if case .menuActionTriggered = self {
                return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.valueChanged))
            }
        }

        switch self {
        case .touchDown:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchDown))
        case .touchDownRepeat:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchDownRepeat))
        case .touchDragInside:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchDragInside))
        case .touchDragOutside:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchDragOutside))
        case .touchDragEnter:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchDragEnter))
        case .touchDragExit:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchDragExit))
        case .touchUpInside:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchUpInside))
        case .touchUpOutside:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchUpOutside))
        case .touchCancel:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.touchCancel))
        case .valueChanged:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.valueChanged))
        case .primaryActionTriggered:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.primaryActionTriggered))
        case .editingDidBegin:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.editingDidBegin))
        case .editingChanged:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.editingChanged))
        case .editingDidEnd:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.editingDidEnd))
        case .editingDidEndOnExit:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.editingDidEndOnExit))
        case .allTouchEvents:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.allTouchEvents))
        case .allEditingEvents:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.allEditingEvents))
        case .applicationReserved:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.applicationReserved))
        case .systemReserved:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.systemReserved))
        case .allEvents:
            return .init(UnsafeMutableRawPointer(&AssociatedActionKeys.allEvents))
        default:
            return UnsafeRawPointer(UnsafeMutableRawPointer(&AssociatedActionKeys.kDefaultKey))
        }
    }
}


extension UIControl {

    public func publisher3(forAction event: UIControl.Event) -> AnyPublisher<UIControl, Never> {
        let eventKey = event.publisherActionKey
        if let publisher = objc_getAssociatedObject(self, eventKey) as? AnyPublisher<UIControl, Never> {
            return publisher
        } else {
            let publisher = ControlPublisher3(control: self, event: event)
                .eraseToAnyPublisher()
            objc_setAssociatedObject(self, eventKey, publisher, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return publisher
        }
    }
}

fileprivate final class ControlPublisher3: Publisher  {
    typealias Failure = Never
    typealias Output = UIControl

    private let subject = PassthroughSubject<UIControl, Never>()

    private weak var control: UIControl?

    init(control: UIControl, event: UIControl.Event) {
        self.control = control

        control.addTarget(self, action: #selector(doAction(sender:)), for: event)
    }

    deinit {
        subject.send(completion: .finished)
        Swift.print("ControlPublisher3<\(type(of: control))> deinit! ____#")
    }

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, UIControl == S.Input {
        subject.receive(subscriber: subscriber)
    }

    @objc private func doAction(sender: UIControl) {
        if let control = control {
            subject.send(control)
        }
    }
}

