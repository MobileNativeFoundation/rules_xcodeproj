import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
    }
    
    override func didResignActive(with conversation: MSConversation) {
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    }
}
