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
 
 For other Signal manipulations, including aggregation, merging, zipping and combining, see the ReactiveCocoa documentation on [Basic Operators](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/Documentation/BasicOperators.md).
 */
