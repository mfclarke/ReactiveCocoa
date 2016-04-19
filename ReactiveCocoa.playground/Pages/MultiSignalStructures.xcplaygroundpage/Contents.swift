//: [Previous](@previous)
import Result
import ReactiveCocoa
import UIKit
import XCPlayground
/*:
 ## Building Multi-Signal Structures
 
 ```Signal```s can be joined together to form a kind of flow structure. A ```Signal``` can fire which causes another to fire and another and so on. You can set up very simple and very complex decision structures, value transform structures and anything in between, with all parts observable by anything. Woah 🎇
 
 A simple demonstration: Say you have a ```Signal``` that has ```String``` values on it. Now, whenever that ```Signal``` has a ```String``` on it that contains the word "cat", you want to be notified. Well, you'd set up a new ```Signal``` and observe this one, then fire this one whenever "cat" is mentioned on the original ```Signal```. Sounds a little complicated...
 */
do {
    let catString = "cat"
    
    let (stringSignal, stringObserver) = Signal<String, NoError>.pipe()
    
    let catSignal = stringSignal.filter { string in
        string.containsString(catString)
    }
    
    stringSignal.observeNext { string in
        let x = string
    }
    
    catSignal.observeNext { stringContainingCat in
        let x = stringContainingCat
    }
    
    stringObserver.sendNext("I have a dog")
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
}
/*:
 Or not. We can just ```filter``` the ```stringSignal```. In ReactiveCococa 4, the ```filter``` operator creates a new ```Signal``` which sends a *Next* ```Event``` whenever the ```filter``` closure returns ```true```. In other words: "receive events from the previous ```Signal```, and when one matches my ```filter``` predicate, forward it on".
 
 And since ```filter``` returns a new ```Signal```, we can observe *Next* ```Event```s on this ```Signal``` alone.
 
 But what if we don't really want to get notified per se, but just want to replace the word "cat" with a 😺 emoji?
 */
do {
    let catString = "cat"
    
    let (stringSignal, stringObserver) = Signal<String, NoError>.pipe()
    let catEmojiSignal = stringSignal
        .filter { string in
            string.containsString(catString)
        }
        .map { stringContainingCat in
            (stringContainingCat as NSString).stringByReplacingOccurrencesOfString("cat", withString: "😺")
        }
    
    stringSignal.observeNext { string in
        let x = string
    }
    
    catEmojiSignal.observeNext { catEmojiString in
        let x = catEmojiString
    }
    
    stringObserver.sendNext("I have a dog")
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
}
/*:
 Pretty simple - it turns out ```map``` works the same way. So, our ```map``` creates a new ```Signal``` using the string containing "cat" as an input and fires a *Next* ```Event``` with a new string where "cat" is replaced by 😺. Or in other words: "it receives the string containing the word 'cat' from the previous ```Signal``` in, and sends the replaced string out"
 
 There's also something else going on here. Since ```map``` and ```filter``` take a ```Signal``` and return a ```Signal```, they can be connected to each other like pipes. Streams of events flow through these pipes, being transformed or filtered to be sent any which way in exactly the format we want to anything that wants to observe them. What we're seeing here is function composition.

 What happens if a ```Signal``` in the chain fails? Let's see.
 */
do {
    enum DogError: ErrorType {
        case StringHasADog
    }
    
    let catString = "cat"
    
    let (stringSignal, stringObserver) = Signal<String, NoError>.pipe()
    let catEmojiSignal = stringSignal
        .promoteErrors(DogError)
        .attempt { string -> Result<(), (DogError)> in
            string.containsString("dog") ? .Failure(.StringHasADog) : .Success()
        }
        .filter { string in
            string.containsString(catString)
        }
        .map { stringContainingCat in
            (stringContainingCat as NSString).stringByReplacingOccurrencesOfString("cat", withString: "😺")
        }
    
    stringSignal.observeNext { string in
        let x = string
    }
    
    catEmojiSignal.observeFailed { error in
        let x = error
    }
    
    catEmojiSignal.observeNext { catEmojiString in
        let x = catEmojiString
    }
    
    stringObserver.sendNext("I have a dog")
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
}
/*:
 So first we have to ```promote``` our ```Signal``` so it can throw the error we want. Then, we can use the ```attempt``` function to check for the error case and throw if it's met. Even though ```Success``` doesn't pass any value, it indicates that all is well and ```Event```s can continue down the chain. Then it's just business as usual. You can see that the dog ruined all the fun 😾. *Failed* ```Event```s cause ```Signal```s to stop, so once the ```attempt``` fails it's game over.
 
 Another function Reactive Cocoa excells at is waiting for a bunch of things to happen and then continuing. Imagine this UX: User is at a login page. They enter their username and password then tap login. The login network request kicks off and a fancy animation happens to show that they're being logged in. Simple right? But, the designer says they want the animation to finish at least once before the user enters the app, and we can only enter the app at the end of an animation cycle (and of course the user can't enter the app until the back end has confirmed the login).
 
 I can see this in vanilla Swift/UIKit now: a bunch of bools to say what has completed, a bool to say "waiting for animation to finish", everytime something happens (network request completed, animation finishes) all these bools are checked again. Ugly. And then what happens if later we also want to prefetch some images if the login happens really quickly, with a timeout since it's a non-essential step? (remember to still maintain the end of animation cycle timing. Oh and error handling). I'm cringing already...
 */
do {
    let loginTime: NSTimeInterval = 0.2
    let animateCycleTime: NSTimeInterval = 1
    let prefetchTime: NSTimeInterval = 1.5
    let prefetchTimeout: NSTimeInterval = 3
    
    enum LoginError: ErrorType {
        case LoginFailed
    }
    
    enum PrefetchError: ErrorType {
        case PrefetchFailed
        case PrefetchTimedOut
    }
    
    func login(username: String) -> SignalProducer<Bool, LoginError> {
        return SignalProducer<Bool, LoginError> { observer, disposable in
            executeAfter(seconds: 0.2) {
                if username == "" {
                    observer.sendFailed(.LoginFailed)
                } else {
                    observer.sendNext(true)
                }
            }
        }
    }
    
    func startAnimation() -> SignalProducer<Bool, NoError> {
        return SignalProducer<Bool, NoError> { observer, disposable in
            func animate() {
                executeAfter(seconds: 1) {
                    observer.sendNext(true)
                    observer.sendNext(false)
                    animate()
                }
            }
            animate()
        }
    }
    
    func prefetch() -> SignalProducer<Bool, PrefetchError> {
        return SignalProducer<Bool, PrefetchError> { observer, disposable in
            executeAfter(seconds: 1.2) {
                observer.sendNext(true)
            }
        }
    }
    
    
}


//: [Next](@next)
