/*:
 # Intro to Reactive Cocoa 4 with Swift
 
 This Playground aims to give a quick overview of the basics of ReactiveCocoa SignalProducers, Signals, Events and Values.
 */
import Result
import ReactiveCocoa
import UIKit
import XCPlayground
/*:
 ## Signals, Events, Values
 Say you want to send an ```Int``` somewhere. In ReactiveCocoa 4 speak, that ```Int``` is a value, that is sent along a ```Signal```. A ```Signal``` can be used to send any number of values, so it's best to think about it as a continuous stream that values flow down.
 
 To manually send a value down a ```Signal```, you need to use the ```Signal```'s ```Observer``` object. The naming of the ```Observer``` object is a little confusing, since it can really only be used to send stuff down a ```Signal```, but that's what the Reactive Cocoa guys chose. Anyway, a ```Signal``` and it's corresponding ```Observer``` are created at the same time with the ```pipe``` func.
 
 That's a bit to take in, so let's set up a ```Signal``` to demonstrate:
 */
do {
    let (signal, observer) = Signal<Int, NoError>.pipe()
    signal.observeNext { number in
        let x = number
    }
    
    observer.sendNext(10)
    observer.sendNext(5)
    observer.sendNext(12)
}
/*:
 So what's going on here? First, we use ```pipe``` to get our ```Signal``` ```Observer``` pair. Our ```Signal``` has been set up to have ```Int```s flow along it. We then set up a closure on the ```Signal``` to fire every time a value is sent. Finally, we send some ```Int```s down the ```Signal```.
 
 As you can see from the graph, the ```observeNext``` closure has fired once for each ```Int``` sent, in the order that we sent them 🎉
 
 But what's with the *Next* stuff? Well, values are actually sent down a ```Signal``` wrapped in *Next* ```Event```s. There are a few different types of ```Event```s that can be sent down a ```Signal``` - more on this shortly.
 
 So the cool thing about ```Signal```s is that they can be observed by any number of closures (and in turn, any number of objects). So one the value of one```sendNext``` can be received and used in many different ways and contexts.
 */
do {
    let (signal, observer) = Signal<Int, NoError>.pipe()
    signal.observeNext { number in
        let x = number
    }
    signal.observeNext { number in
        let x = 1.0 / Float(number)
    }
    signal.observeNext { number in
        let x = "The number is \(number)"
    }
    
    observer.sendNext(10)
    observer.sendNext(5)
    observer.sendNext(12)
}
/*:
 ### Event Types
 As mentioned before, values sent down a ```Signal``` are actually wrapped in a *Next* ```Event```. There are other ```Event``` types too.
 
 First, there's the *Failed* ```Event```. The *Failed* ```Event``` carries an ```ErrorType``` and when sent causes the stream to stop. So if we encounter a situation where we want the ```Signal``` to stop, and to inform anything observing the ```Signal``` what went wrong, we can simply ```sendFailed``` with an ```ErrorType```
 */
do {
    enum IntError: ErrorType {
        case SomeErrorHappened
    }
    
    let (signal, observer) = Signal<Int, IntError>.pipe()
    signal.observeNext { number in
        let x = number
    }
    
    signal.observeFailed { error in
        let e = error
    }
    
    observer.sendNext(10)
    observer.sendNext(5)
    observer.sendFailed(.SomeErrorHappened)
    observer.sendNext(12)
}
/*:
 The last value (12) didn't send, because the ```Signal``` had already failed with the *Failed* ```Event``` carrying the ```SomeErrorHappened``` Error. Perfect.
 
 We also have a *Completed* ```Event```. This also causes the ```Signal``` to stop, but without sending an *Error* ```Event```. We use this to indicate the ```Signal``` is finished and we don't need it anymore. Even if we're clumsy with our code and try to send a *Next* ```Event``` after a ```Signal``` has completed, it won't send - the ```Signal``` is already stopped.
 */
do {
    let (signal, observer) = Signal<Int, NoError>.pipe()
    signal.observeNext { number in
        let x = number
    }
    
    observer.sendNext(10)
    observer.sendNext(5)
    observer.sendCompleted()
    observer.sendNext(12)
}
/*:
 And finally there is the *Interrupted* ```Event```, which is very similar to the *Completed* ```Event```, but happens automatically. So you know how you call the ```observe``` methods on the ```Signal``` to add closures that fire when different ```Event```s flow down the ```Signal```? We can stop observing by using the ```Disposable``` object returned. When we call ```dispose``` on this object, the observation stops. And when all the ```Disposable```s have been ```disposed```, the ```Signal``` stops with the *Interrupted* ```Event```, since there's no use in a ```Signal``` if nothing is observing the ```Event```s.
 */
do {
    let (signal, observer) = Signal<Int, NoError>.pipe()
    let disposable = signal.observeNext { number in
        let x = number
    }
    
    observer.sendNext(10)
    observer.sendNext(5)
    disposable?.dispose()
    observer.sendNext(12)
}