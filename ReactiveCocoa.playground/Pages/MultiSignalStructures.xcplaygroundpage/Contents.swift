//: [Previous](@previous)
import Result
import ReactiveCocoa
import UIKit
import XCPlayground
/*:
 ## Multi Signal Structures
 ### Transforming Values with Operators
 
 ```Value```s from ```Signal```s can transformed with *operator*s for different uses and contexts. In this way, you can form a kind of flow structure, where a signal can be used in many different ways by many different objects. When you transform a ```Signal```, ReactiveCocoa gives you a new ```Signal``` which fires the transformed ```Event```s. With *operator*s, you can set up very simple and very complex decision structures, value transform structures and anything in between, with all parts observable by anything. Woah 🎇
 
 A simple demonstration: Say you have a ```Signal``` that has ```String``` values on it. Now, whenever that ```Signal``` has a ```String``` on it that contains the word "cat", you want to be notified. Well, we can use the ```filter``` *operator* on our original ```Signal``` to filter by the word "cat", and observe *Next* ```Event```s from the ```Signal``` created by this ```filter``` *operator* to notify us.
 */
do {
    let catString = "cat"
    
    let (stringSignal, stringObserver) = Signal<String, NoError>.pipe()
    
    let catSignal = stringSignal.filter { string in
        string.containsString(catString)
    }
    
    catSignal.observeNext { stringContainingCat in
        let x = stringContainingCat
    }
    
    stringObserver.sendNext("I have a dog")
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
}
/*:
 Pretty simple. We can actually make this even more concise by just chaining this all together. Since *operator*s take a ```Signal``` and return a new ```Signal```, we can continue the chain without intermediate steps.
 */
do {
    let catString = "cat"
    
    let (stringSignal, stringObserver) = Signal<String, NoError>.pipe()
    
    stringSignal
        .filter { string in
            string.containsString(catString)
        }
        .observeNext { stringContainingCat in
            let x = stringContainingCat
        }
    
    stringObserver.sendNext("I have a dog")
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
}
/*:
 Notice that by chaining *operator*s we're not affecting anything earlier in the chain. We're just creating new ```Signal```s that fire the transformed ```Value```s. ```Signal```s are immutable. This is what makes Reactive Cocoa ```Signal```s are really easy to reason about.
 
 Not only that, but the return types of *operator*s vs ```observe``` functions force the chain the follow the pattern: create, transform, observe. If you need to observe something in the middle of the chain, then you need to split it, observe the ```Signal``` at the split point, and then explicity continue the chain again.
 
 What if we don't really want to get notified per se, but just want to replace the word "cat" with a 😺 emoji?
 */
do {
    let catString = "cat"
    
    let (stringSignal, stringObserver) = Signal<String, NoError>.pipe()
    stringSignal
        .filter { string in
            string.containsString(catString)
        }
        .map { stringContainingCat in
            (stringContainingCat as NSString).stringByReplacingOccurrencesOfString("cat", withString: "😺")
        }
        .observeNext { catEmojiString in
            let x = catEmojiString
        }
    
    stringObserver.sendNext("I have a dog")
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
}
/*:
 Pretty simple - it turns out ```map``` follows the pattern. So, our ```map``` creates a new ```Signal``` that fires *Next* ```Event```s with the word "cat" replaced with 😺.
 
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
 */

//: [Next](@next)
