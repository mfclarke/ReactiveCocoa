//: [Previous](@previous)
import Result
import ReactiveCocoa
import UIKit
import XCPlayground
/*:
 ## SignalProducers
 
 So we have ```Signal```s, which are streams that ```Event```s flow down. Something we haven't talked about yet is how a ```Signal``` is "always on". You never start it: it's already flowing when you ```init``` it (you just haven't sent any ```Event```s yet). So what about circumstances where you have a ```Signal``` with a definite start? Welcome to ```SignalProducer```s [3]
 
 ```SignalProducer```s do exactly what their name says: they produce ```Signal```s. When you create one, you implement the ```send``` behaviour in a block that gives an ```Observer``` and a ```Disposable``` in. Once created, you use one of the ```start``` methods, which literally create a new ```Signal``` for you to observe. In this way, they're kind of like a factory of ```Signal```s with a specific behavour.
 
 It's important to understand that each time you ```start``` a ```SignalProducer```, you get an entirely new ```Signal```. So in this way, two ```Signal```s from the same ```SignalProducer``` will have totally different ```Event``` streams.
 
 Here's how our contrived ```Signal``` example from the Intro page looks:
 */
do {
    let producer = SignalProducer<Int, NoError> { observer, disposable in
        observer.sendNext(10)
        observer.sendNext(5)
        observer.sendNext(12)
        observer.sendCompleted()
    }
    
    producer.startWithSignal { signal, disposable in
        signal.observeNext { number in
            let x = number
        }
    }
}
/*:
 As you can see, the logic for when different events get sent is contained inside the ```SignalProducer```s ```init``` closure. This forces you to create your producer in a logical order: ```SignalProducer```, ```Signal``` firing logic, ```Event``` observation. 
 
 What's also cool about this is you can define a ```SignalProducer``` that will fire off different ```Event```s for different circumstances, and then use this producer over and over to create new ```Signal```s for different contexts.
 */
do {
    enum DogError: ErrorType {
        case StringContainedADog
    }
    
    let producer = SignalProducer<String, DogError> { observer, disposable in
        // Code goes here
    }
}
/*:
 For convenience, you can ```start``` a ```SignalProducer``` in a few different ways:
 */
do {
    let producer = SignalProducer<Int, NoError> { observer, disposable in
        observer.sendNext(10)
        observer.sendNext(5)
        observer.sendNext(12)
        observer.sendCompleted()
    }
    /*: All in the ```start``` closure */
    producer.startWithSignal { signal, disposable in
        signal.observeNext { number in
            let x = number
        }
    }
    /*: ```Disposable``` as a return value, ```Event```s passed in whole */
    let disposable = producer.start { event in
        switch event {
        case let .Next(number):
            let x = number
        case .Completed:
            let x = "Completed"
        default:
            break
        }
    }
    /*: ```Disposable``` as a return value, with only one ```Event``` type used */
    let disposable2 = producer.startWithNext { number in
        let x = number
    }
}
/*:
 So why would you use them? Well, they're useful for one off things like network requests or computations, where you don't need the ```Signal``` running indefinitely, but just for that one ```Event```. They're also useful when you don't know when the ```Signal``` will start, but you have everything in place to construct the flow between a bunch of objects that will in the future use it. Even UI ```rac_``` ```RACSignal```s need to be converted to ```SignalProducer```s to be used, only after ```start```ing them.
 */
// Code goes here
/*:
## Understanding flatMap
```flatMap``` is one of the more powerful functions of Reactive Cocoa. It enables things like promises, which let you chain all sorts of async code into a synchronous looking structure all in 1 place (and no pyramids of doom).
*/
// Code and more explaination goes here

//: [3] In older RAC speak, a ```Signal``` is a *hot* ```RACSignal``` and a ```SignalProducer``` is a *cold* ```RACSignal```

//: [Next](@next)
