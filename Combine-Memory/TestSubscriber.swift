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


/// 应当遵守官方备注: 在 cancel 释放内存(引用).
/// 对于自定义的 Subscriber 应该和官方的 `Sink` 类似, 遵守 `Cancellable`
/// 在传入 `Publisher` 的 `receiver(subscriber:)` 后
/// 必须在适合的时机调用 `cancel`, 如 `store(in: )`
final class TestSubscriber: Combine.Subscriber, Combine.Cancellable {

    typealias Input = String
    typealias Failure = Never

    // FIXED: - 需要强引用一次 subscription, 保证其生命周期内 subscriptin 一直存在
    var subscription: Subscription?

    deinit {
        subscription?.cancel()
        print("TestSubscriber deinit! ____#")
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription
        // @note: - 这里可以限制请求次数
        subscription.request(.unlimited)
    }

    func receive(_ input: String) -> Subscribers.Demand {
        print("TestSubscriber 接收到值: \(input)")
        return .none
    }

    func receive(completion: Subscribers.Completion<Never>) {
        print("TestSubscriber 结束订阅! ____&")
    }

    func cancel() {
        // FIXED: - 对于 `Publishers/Share` 或者 `Publishers/Multicast` 必须调用 cancel
        // Tips: - Share 实现参考官方注释
        subscription?.cancel()
        subscription = nil
    }
}
