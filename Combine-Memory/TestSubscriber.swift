//
/*
* ****************************************************************
*
* 文件名称 : TestSubscriber
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
import Combine
import UIKit


/// 应当遵守官方备注: 在 cancel 释放内存(引用).
/// 对于自定义的 Subscriber 应该和官方的 `Sink` 类似, 遵守 `Cancellable`
/// 在传入 `Publisher` 的 `receiver(subscriber:)` 后
/// 必须在适合的时机调用 `cancel`, 如 `store(in: )`
final class TestSubscriber: Combine.Subscriber, Combine.Cancellable {

    typealias Input = String
    typealias Failure = Never

    // FIXED: - 需要强引用一次 subscription, 保证其生命周期内 subscription 一直存在
    // var subscription: Subscription?
    // FIXED: - 使用 cancelAction 代替
    var cancelAction: (() -> Void)?

    // FIXED: - 这里不强引用, 防止测试阶段 Button 不释放,并且 demo 忽略性能损失. 可强引用, 注意 cancel 释放
    private weak var button: UIButton?
    private var state: UIButton.State

    convenience init() {
        self.init(button: nil, state: .normal)
    }

    init(button: UIButton?, state: UIButton.State) {
        self.button = button
        self.state = state
    }

    deinit {
        print("TestSubscriber deinit! ____#")
    }

    func receive(subscription: Subscription) {
        // FIXED: - 测试多次订阅不同 publisher, 只对最后一个订阅生效, 可不调用 cancel
        cancelAction?()
        cancelAction = subscription.cancel
        // @note: - 这里可以限制请求次数
        subscription.request(.unlimited)
    }

    func receive(_ input: String) -> Subscribers.Demand {
        print("TestSubscriber 接收到值: \(input)")
        button?.setTitle(input, for: state)
        return .none
    }

    func receive(completion: Subscribers.Completion<Never>) {
        // FIXED: - 对 Subject 转换来的 publisher, 接收到 completion 后不需要特殊处理
        // 但是对 TestSubscriber 实例调用 receive(completion:) 无法释放内存
        cancelAction = nil
        print("TestSubscriber 结束订阅! ____&")
    }

    func cancel() {
        // FIXED: - 对于自定义 `Publisher` 转换为 `Publishers/Share` 或者 `Publishers/Multicast` 必须调用 cancel
        // FIXED: - 对于 `Subject` 无此要求
        // Tips: - Share 实现参考官方注释
        cancelAction?()
        cancelAction = nil
    }
}
