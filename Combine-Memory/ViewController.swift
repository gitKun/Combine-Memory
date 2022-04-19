//
/*
* ****************************************************************
*
* 文件名称 : ViewController
* 作   者 : Created by 坤
* 创建时间 : 2022/4/18 14:39
* 文件描述 : 
* 注意事项 : 
* 版权声明 : 
* 修改历史 : 2022/4/18 初始版本
*
* ****************************************************************
*/

import UIKit
import Combine

class ViewController: UIViewController {

// MARK: - 成员变量

    var canShow = false

    private var count = 0

    private var cancellable: Set<AnyCancellable> = []

    private let receiveSubject = PassthroughSubject<String, Never>()

// MARK: - 生命周期 & override

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeUI()
        eventListen()
        bindViewModel()
    }

    deinit {
        receiveSubject.send(completion: .finished)
        print("ViewController deinit! ____#")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

// MARK: - 计算属性 & lazy

    var buttonSubscriber: Subscribers.Sink<String, Never>!

// MARK: - UI 属性

    private var showDemoButton: UIButton!
    private var addButton: UIButton!
    private var countButton: UIButton!

}

// MARK: - 绑定 viewModel

extension ViewController {

    func bindViewModel() {

        if !canShow {

            showDemoButton.publisher1(forAction: .touchUpInside)
                .sink { [weak self] _ in
                    let vc = ViewController()
                    vc.canShow = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
                .store(in: &cancellable)
        } else {

            let addPublisher = addButton.publisher3(forAction: .touchUpInside)
                .map { [weak self] _ -> String in
                    self?.count += 1
                    return "\(self?.count ?? 0)"
                }
                .share()

            // TEST: - 多次订阅
            addPublisher.receive(subscriber: countButton.subscriber(forTitle: .normal))
            addPublisher.receive(subscriber: TestSubscriber())

//            let testSubscriber3 = TestSubscriber(button: countButton, state: .normal)
            // testSubscriber3.store(in: &cancellable)

            // TEST: - subjet 转换的 AnySubscriber 订阅后的问题
//            addPublisher.receive(subscriber: AnySubscriber(testSubscriber3))

//            receiveSubject.receive(subscriber: testSubscriber3)

            // TEST: - 直接 receiver(subscriber:)
//            addPublisher
//                .receive(subscriber: countButton.subscriber(forTitle: .normal))

//            let testSubscriber = TestSubscriber()
//            testSubscriber.store(in: &cancellable)

//            addPublisher
//                .receive(subscriber: testSubscriber)

//            let testSubscriber2 = TestSubscriber(button: countButton, state: .normal)
//            testSubscriber2.store(in: &cancellable)
//
//            addPublisher
//                .receive(subscriber: testSubscriber2)

//            addPublisher
//                .sink { value in
//                    print("多次订阅 - 1 - 接收到值: \(value)")
//                }
//                .store(in: &cancellable)

//            addPublisher
//                .sink { value in
//                    print("多次订阅 - 2 - 接收到值:\(value)")
//                }
//                .store(in: &cancellable)
        }
    }
}

// MARK: - 事件处理

extension ViewController {

    func eventListen() {

        // 模仿
//        testSubject
//            .map { _ in Bool.random() }
//            .receive(subscriber: TestSubscriber())
    }
}

// MARK: - 布局UI元素

extension ViewController {

    func initializeUI() {

        view.backgroundColor = canShow ? .systemTeal : .systemBrown
        navigationItem.title = canShow ? "计数器页面" : "首页"

        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.spacing = 10

        if !canShow {
            showDemoButton = createButton(with: "显示Demo页面")
            stackView.addArrangedSubview(showDemoButton)
        } else {
            addButton = createButton(with: "计数加一")
            countButton = createButton(with: "0", titleColor: .systemRed)
            stackView.addArrangedSubview(addButton)
            stackView.addArrangedSubview(countButton)
        }

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalToConstant: 240),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func createButton(with title: String, titleColor: UIColor = .systemBrown) -> UIButton {
        let button = TestButton(type: .custom)
        button.setTitleColor(titleColor, for: .normal)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 22.5
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.heightAnchor.constraint(equalToConstant: 45)])
        // button.layer.masksToBounds = true
        return button
    }
}
