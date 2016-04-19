//: [Previous](@previous)
import Result
import ReactiveCocoa
import UIKit
import XCPlayground
/*:
 ## Real World Signal Usage (WIP)
 This whole time we've used the ```pipe``` function, but most of the time we'll be getting ```Signal```s back from the ```rac_``` extensions we get for free from ReactiveCocoa, and interacting with those. However, sometimes we might need to bridge between the two worlds of ReactiveCocoa and the rest of your codebase. This is what ```pipe``` is really for. Here's an example of the kind of bridging we're talking about.
 */
extension UIView {
    static func animate(duration: NSTimeInterval, animations: () -> ()) -> Signal<Void, NoError> {
        let (signal, observer) = Signal<Void, NoError>.pipe()
        animateWithDuration(duration, animations: animations) { completed in
            observer.sendNext()
        }
        return signal
    }
}
/*:
 Can you guess what it does? 😜
 
 So now we can use this in our chains. How about a multi step animation without a pyramid of doom? And let's use the built in UIButton rac func to fire it all off.
 */
let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 500))
let button = UIButton(type: .System)
button.setTitle("Go", forState: UIControlState.Normal)
button.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
button.backgroundColor = UIColor.whiteColor()
let aView1 = UIView(frame: CGRect(x: 0, y: 100, width: 200, height: 100))
aView1.backgroundColor = UIColor.blueColor()
let aView2 = UIView(frame: CGRect(x: 0, y: 200, width: 200, height: 100))
aView2.backgroundColor = UIColor.redColor()
let aView3 = UIView(frame: CGRect(x: 0, y: 300, width: 200, height: 100))
aView3.backgroundColor = UIColor.greenColor()
let aView4 = UIView(frame: CGRect(x: 0, y: 400, width: 200, height: 100))
aView4.backgroundColor = UIColor.yellowColor()
view.addSubview(button)
view.addSubview(aView1)
view.addSubview(aView2)
view.addSubview(aView3)
view.addSubview(aView4)

button
    .rac_signalForControlEvents(.TouchUpInside).toSignalProducer()
    .flatMapError { _ in SignalProducer<AnyObject?, NoError>.empty }
    .flatMap(.Latest) { _ in
        UIView.animate(0.5) {
            aView1.frame.origin = CGPoint(x: -200, y: 100)
            aView1.alpha = 0
        }
    }
    .flatMap(.Latest) {
        UIView.animate(0.5) {
            aView2.frame.origin = CGPoint(x: 200, y: 200)
            aView2.alpha = 0
        }
    }
    .flatMap(.Latest) {
        UIView.animate(0.5) {
            aView3.frame.origin = CGPoint(x: -200, y: 300)
            aView3.alpha = 0
        }
    }
    .delay(1, onScheduler: QueueScheduler(queue: dispatch_get_main_queue()))
    .flatMap(.Latest) {
        UIView.animate(0.5) {
            aView4.transform = CGAffineTransformMakeScale(1, 8)
            aView4.alpha = 0
        }
    }
    .start()

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
XCPlaygroundPage.currentPage.liveView = view

/*:
 Ignoring the ugly translation of the Reactive Cococa 2 ```RACSignal``` to Reactive Cocoa 4's ```SignalProducer``` with the correct ```NoError``` type, it looks very straight forward. In fact, if you think of each ```.flatMap(.Latest)``` as the word "then", it reads almost like how you would describe the animation verbally: "It animates the first view to -200 x while fading it out, then it animates the second view to 200 x while fading it out etc."
 
 Funnily enough, for these kinds of things, we could use the ReactiveCocoa ```then``` operator, which waits until the *Completed* ```Event``` has been sent from the previous ```SignalProducer```s ```Signal```. Unfortunately, ```then``` doesn't pass any ```Value```s in, but for stuff like this that doesn't matter. And of course, it's just a simple convenience extension away from having this semantic, if you so choose.
 
 This kind of stuff is a bit like promises, which are discussed in detail on the [Next Page](@next).
 */

/*:
 ### A More Detailed Scenario
 Imagine this UX: User is at a login page. They enter their username and password then tap login. The login network request kicks off and a fancy animation happens to show that they're being logged in. Simple right? But, the designer says they want the animation to finish at least once before the user enters the app, and we can only enter the app at the end of an animation cycle (and of course the user can't enter the app until the back end has confirmed the login).
 
 I can see this in vanilla Swift/UIKit now: a bunch of bools to say what has completed, a bool to say "waiting for animation to finish", everytime something happens (network request completed, animation finishes) all these bools are checked again. Ugly. And then what happens if later we also want to prefetch some images if the login happens really quickly, with a timeout since it's a non-essential step? (remember to still maintain the end of animation cycle timing. Oh and error handling). I'm cringing already...
 
 Let's try it in Reactive Cocoa:
 */
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

do {
    enum LoginError: ErrorType {
        case BadUsername
    }
    
    enum PrefetchError: ErrorType {
        case PrefetchFailed
        case PrefetchTimedOut
    }
    
    enum ProcessError: ErrorType {
        case LoginErrorHappened(type: LoginError)
        case PrefetchErrorHappened(type: PrefetchError)
    }
    
    var username = "max"
    var loginTime: NSTimeInterval = 0.2
    var animateCycleTime: NSTimeInterval = 1
    var prefetchTime: NSTimeInterval = 4.5
    var prefetchTimeout: NSTimeInterval = 2
    
    var prefetchTimedOut = false
    var isAnimating = false
    
    func login(username: String) -> SignalProducer<Bool, LoginError> {
        return SignalProducer<Bool, LoginError> { observer, disposable in
            executeAfter(seconds: loginTime) {
                if username == "" {
                    observer.sendFailed(.BadUsername)
                } else {
                    observer.sendNext(true)
                    observer.sendCompleted()
                }
            }
        }
    }
    
    func startAnimation() -> SignalProducer<Bool, NoError> {
        return SignalProducer<Bool, NoError> { observer, disposable in
            func animate() {
                observer.sendNext(false)
                executeAfter(seconds: animateCycleTime) {
                    observer.sendNext(true)
                    if isAnimating {
                        animate()
                    } else {
                        observer.sendCompleted()
                    }
                }
            }
            isAnimating = true
            animate()
        }
    }
    
    func prefetch() -> SignalProducer<Bool, PrefetchError> {
        return SignalProducer<Bool, PrefetchError> { observer, disposable in
            executeAfter(seconds: prefetchTime) {
                observer.sendNext(true)
                observer.sendCompleted()
            }
        }
    }
    
    //: Play with these values to try out different scenarios
    username = "max"
    loginTime = 0.2
    animateCycleTime = 2
    prefetchTime = 0.5
    prefetchTimeout = 3
    
    combineLatest([
        login(username)
            .on(next: { _ in print("Login successful") })
            .mapError(ProcessError.LoginErrorHappened),
        startAnimation()
            .on(next: { finished in if finished { print("Animation finished") } })
            .promoteErrors(ProcessError),
        prefetch()
            .on(next: { _ in print("Prefetch finished") })
            .timeoutWithError(.PrefetchTimedOut, afterInterval: prefetchTimeout, onScheduler: QueueScheduler.mainQueueScheduler)
            .on(failed: { error in
                prefetchTimedOut = true
            })
            .flatMapError { error in
                if error == .PrefetchTimedOut {
                    return SignalProducer<Bool, ProcessError>(value: true)
                } else {
                    return SignalProducer<Bool, ProcessError>(error: ProcessError.PrefetchErrorHappened(type: error))
                }
            }
        ])
        .map { values in
            let x = values
            return values.reduce(true) { $0 && $1 }
        }
        .filter { completed in
            return completed
        }
        .on(
            started: {
                print("Login starting")
            },
            next: { begin in
                isAnimating = false
            },
            failed: { error in
                isAnimating = false
        })
        .startWithSignal { signal, disposable in
            signal.observeNext { finished in
                print("Login Process Complete!" + (prefetchTimedOut ? "... with prefetch timeout" : ""))
            }
            signal.observeFailed { error in
                print("Login failed: \(error)")
            }
        }
}

/*:
 About 100 lines, including the SignalProducer definitions (which to be fair would normally reside in their own single responsibility classes/structs). We use our ```combineLatest``` operator to wait until all ```Signal```s have fired, and then forward all the latest events on every time one fires again. Then make sure we only fire if all three values are true. It's beautiful: all the logic to determine what happens when is all in one place, including error handling!
 
 Some notes: Errors have to be promoted or mapped to one unified type. I opted for a nested enum for this. I also opted to treat the prefetch timeout as a non-fatal error by ```flatMapError```ing it and setting a ```Bool```. You may want to handle this differently (for example, fire an ```Event``` to a different ```Signal```)
 
 Try adding a login timeout failure. I think you'll find it almost too easy... 😃 Then think about how you'd have to do that in vanilla Swift without breaking anything... 🙃
 */