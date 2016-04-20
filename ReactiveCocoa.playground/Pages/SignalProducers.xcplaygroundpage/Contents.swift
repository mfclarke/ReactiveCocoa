//: [Previous](@previous)
import Result
import ReactiveCocoa
import UIKit
import XCPlayground
/*:
 ## SignalProducers (WIP)
 
 So we have ```Signal```s, which are streams that ```Event```s flow down. Something we haven't talked about yet is how a ```Signal``` is "always on". You never start it: it's already flowing when you ```init``` it (you just haven't sent any ```Event```s yet). So what about circumstances where you have a ```Signal``` with a definite start? Welcome to ```SignalProducer```s [3]
 
 ```SignalProducer```s do exactly what their name says: they produce ```Signal```s. When you create one, you implement the ```send``` behaviour in a block that gives an ```Observer``` and a ```Disposable``` in. Once created, you use one of the ```start``` methods, which literally create a new ```Signal``` for you to observe. In this way, they're kind of like a factory of ```Signal```s with a specific behavour.
 
 It's important to understand that each time you ```start``` a ```SignalProducer```, you get an entirely new ```Signal```. So in this way, two ```Signal```s from the same ```SignalProducer``` will have totally different ```Event``` streams.
 
 A ```SignalProducer``` by itself isn't very useful. Most of the time you will be creating them via a function, or as part of a chain.
 */
do {
    enum TrueIfDogError: ErrorType {
        case NoText
    }
    
    func trueIfDog(text: String) -> SignalProducer<Bool, TrueIfDogError> {
        return SignalProducer { observer, disposable in
            if text == "" {
                observer.sendFailed(.NoText)
            } else {
                observer.sendNext(text.lowercaseString == "dog")
            }
        }
    }

    let disposable1 = trueIfDog("cat").startWithNext {
        let x = $0
    }
    
    let disposable2 = trueIfDog("dog").startWithNext {
        let x = $0
    }
    
    trueIfDog("").startWithSignal { signal, disposable in
        signal.observeNext {
            let x = $0
        }
        signal.observeFailed {
            let x = $0
        }
    }
}
/*:
 As you can see, the logic for when different events get sent is contained inside the ```SignalProducer```s ```init``` closure. This forces you to create your producer in a logical order: ```SignalProducer```, ```Event``` firing logic, ```Signal``` observation.
 
 What's also cool about this is you can define a ```SignalProducer``` that will fire off different ```Event```s for different circumstances, and then use this producer over and over to create new ```Signal```s for different contexts.
 
 ```SignalProducer```s also make wrapping async code very easy.
 */

// Async example goes here

/*:
## SignalProducer chaining, or how I learned to stop worrying and love ```flatMap(.Latest)```
```flatMap``` is one of the more powerful functions of Reactive Cocoa. It enables things like promises, which let you chain all sorts of async code into a synchronous looking structure all in 1 place (and no pyramids of doom).
*/
// Code and more explaination goes here

//: [3] In older RAC speak, a ```Signal``` is a *hot* ```RACSignal``` and a ```SignalProducer``` is a *cold* ```RACSignal```

//: [Next](@next)
