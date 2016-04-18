//: [Previous](@previous)

/*:
 # Using ReactiveCocoa 4 for PromiseKit style "then" chaining (WIP)
 
 PromiseKit gives you a very easy interface for using promises. Essentially, promises are a way of saying "something could happen, and when it does this object will give a value. In the meantime, this object will represent the possibility of that value, so you can for example use it to construct an easy to follow description of events and how they're handled."
 
 ReactiveCocoa happens to offer this kind of functionality built in, so if you already have ReactiveCocoa in your project you don't necessarily need PromiseKit. But ReactiveCocoa doesn't offer promises with this easy to read syntax - you need to know a bit about how to program with ReactiveCocoa to achieve the same thing. But once you do, the code reads just as easily, just with different terminology and behind the scenes semantics.
 
 This page aims to show how ReactiveCocoa can be used to build super concise promise chains that read as an almost storylike description of execution. The instruction "get the user's current location, convert this into the format needed by OpenWeather, get the weaather from the OpenWeather API and update the UI with the weather returned" will read the same way in code, in about the same number of characters. No nested callbacks, no pyramids of doom, no jumping between methods or files to work out what's going on.
 */
import Result
import ReactiveCocoa
import Foundation
import XCPlayground
/*:
 ## Basic Async SignalProducers
 
 SignalProducers can be used to wrap async functions, so they can be used in serial or concurrent execution chains, with dependencies, and more.
 
 When we create one, we're given an object (```observer```) that we can use to send values (```observer.sendNext```) [1]
 */
func getInt(int: Int) -> SignalProducer<Int, NoError> {
    return SignalProducer<Int, NoError> { observer, disposable in
        executeAfter(seconds: 0.5) {
            observer.sendNext(int)
            observer.sendCompleted()
        }
    }
}
/*:
 In this case, when the ```executeAfter``` delay is finished (or for example, an Alamofire network request has returned), we do a ```sendNext``` to send the value down the stream. Value can be anything: a class, a struct, ```Int```, ```String```, ```Bool``` etc. You can even send a ```Void``` if there's no information needed except the presence of a value. It just has to match the first generic specifier in the function definition.
 
 We also call ```sendCompleted```, since we're only sending 1 value. This sends the 'completed' event, which signifies that this stream is complete If we needed to send more than 1 value, we would set up some kind of structure to fire off ```sendCompleted``` when we're done.
 
 We can also call ```sendError``` if something goes wrong. Error events propogate immediately, stopping the whole chain in it's tracks.
 
 [1] This is actually an ```Observer``` that is set up on a ```Signal``` that is created when any of the ```start``` methods are called on the ```SignalProducer```, (including via ```flatMap```). But that's a lot to wrap your head around at first, so for this context it's easy just to think of ```observer``` as an object we use to send values down the chain.
 
 ## More Async SignalProducers
 */
func getString(forInt int: Int) -> SignalProducer<String, NoError> {
    return SignalProducer<String, NoError> { observer, disposable in
        executeAfter(seconds: 0.5) {
            observer.sendNext("\(int)")
            observer.sendCompleted()
        }
    }
}

func getSentence(forString string: String) -> SignalProducer<String, NoError> {
    return SignalProducer<String, NoError> { observer, disposable in
        executeAfter(seconds: 0.5) {
            observer.sendNext("We have successfully received the string: \(string)")
            observer.sendCompleted()
        }
    }
}
/*:
 ## Chained SignalProducers
 
 ```SignalProducer```s chained with ```flatMap``` like this execute sequentially, taking the value from the last.
 */
func getSentence(fromInt int: Int) -> SignalProducer<String, NoError> {
    return getInt(int)
        .flatMap(.Latest) { int in
            getString(forInt: int)
        }
        .flatMap(.Latest) { string in
            getSentence(forString: string)
        }
}
/*:
```flatMap``` used this way gives you values from the previous ```SignalProducer``` in, and expects a new ```SignalProducer``` in return. This way, we can take a value from the previous producer and use it in a new one to perform a new async function. [2]

So this ```getSentence``` reads like this: get an int, then take that int and get the string for it, then take that string and get the sentence for it. Written in normal swift with closure function params, this would be nested 3 levels deep. In Reactive Cocoa, no matter how many operations there are in the chain, this can never nest into a pyramid of doom.

[2] There is actually a whole lot more going on here, but since we're only sending 1 value and we have a simple serial chain like this one, we don't have to worry about it. And I still don't completely understand it 😄
*/
//-------------------------------------------------------------------------------//
// Using getSentence
//-------------------------------------------------------------------------------//

getSentence(fromInt: 5).startWithNext { sentence in
    print("getSentence: \(sentence)")
}

//  .startWithNext kicks off the chain and gives us the final value in. .startWithNext means "start the chain, and give me the values that comes out of the last SignalProducer". In this context we only send 1 value (we only have 1 observer.sendNext immediately followed by observer.sendCompletion in our producers), so this closure will only get called once.

//  If we sent more than one value (say as multiple UIImages download), we could modify our flatMap's FlatternStrategy (currently set to .Latest) to change when our closure gets called, so that it gets called when each individual UIImage finishes downloading for example.


//-------------------------------------------------------------------------------//
// With synchronous blocks in the chain
//-------------------------------------------------------------------------------//

func getSentenceCharacterCountAsAnUppercaseSentence(fromInt int: Int) -> SignalProducer<String, NoError> {
    return getInt(int)
        .flatMap(.Latest) { int in
            getString(forInt: int)
        }
        .flatMap(.Latest) { string in
            getSentence(forString: string)
        }
        .map { sentence in
            sentence.characters.count
        }
        .flatMap(.Latest) { int in
            getString(forInt: int)
        }
        .flatMap(.Latest) { string in
            getSentence(forString: string)
        }
        .map { sentence in
            sentence.uppercaseString
    }
}

getSentenceCharacterCountAsAnUppercaseSentence(fromInt: 5).startWithNext { sentence in
    print("getSentenceCharacterCountAsAnUppercaseSentence: \(sentence)")
}

//  If we need to change our values for the next operation, or massage them for the final value, we can use the .map function. This gives you the value of the last SignalProducer in and expects a new value in return. It takes this new value and wraps it in a SignalProducer for you, so you can continue the chain.

//: [Next](@next)
