import Messages
import UIKit

class MessagesViewController: MSMessagesAppViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func willBecomeActive(with _: MSConversation) {}

    override func didResignActive(with _: MSConversation) {}

    override func didReceive(_: MSMessage, conversation _: MSConversation) {}

    override func didStartSending(_: MSMessage, conversation _: MSConversation) {}

    override func didCancelSending(_: MSMessage, conversation _: MSConversation) {}

    override func willTransition(to _: MSMessagesAppPresentationStyle) {}

    override func didTransition(to _: MSMessagesAppPresentationStyle) {}
}
