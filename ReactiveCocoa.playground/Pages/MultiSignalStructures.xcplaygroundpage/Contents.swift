//: [Previous](@previous)
import Result
import ReactiveCocoa
import UIKit
import XCPlayground
/*:
 ## Multi Signal Structures
 ### Transforming Values with Operators
 
 ```Value```s from ```Signal```s can transformed with *operator*s for different uses and contexts. In this way, you can form a kind of flow structure, where ```Event```s move through different transformation *operator*s to be used different ways and different contexts.
 
 A simple demonstration: Say you have a ```Signal``` that has ```String``` values on it. Now, whenever that ```Signal``` has a ```String``` on it that contains the word "cat", you want to be notified.
 
 Here's the wrong way to do it (but the only way he know how at this stage):
 */
do {
    func stringContainsCat(string: String) {
        string
    }
    
    let (signal, observer) = Signal<String, NoError>.pipe()
    signal.observeNext { string in
        if string.containsString("cat") {
            stringContainsCat(string)
        }
    }
    
    observer.sendNext("I have a dog")
    observer.sendNext("Jim has a cat")
    observer.sendNext("Steve has 2 computers")
}
/*:
 Seems reasonable? Well... no. The first problem with this is that our ```Signal``` now relies on an extenal function. It needs to know about stuff outside of it, which couples it to whatever object contains the function we're calling. We should say "this scenario is happening" and anything interested can go "ok great, I'll do this then", rather than "hey you, yes you specifically, do this now"
 
 The second problem is, by calling an external function we can easily introduce side effects, making our code difficult to reason about. It's so much easier to understand what's going on if everything to do with an action is in one place in a comprehensible order.
 
 Thirdly, how do we notify more than one object that might be interested, without creating a giant flying spaghetti monster?
 
 And last but definitely not least, how can we easily extend this for other scenarios? Do we need a new function for each scenario? What about if we still need the "stringContainsCat" notification, but we also need a "stringContainsCatAndDog" notification for a different object? Here comes that giant flying spaghetti monster again...
 
 What if I told you Reactive Cocoa has your back?
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
 Did we just solve every one of those hairy problems in one go? In the same number of lines?? 😮
 
 Say hello to *operator*s.
 
 Here we're using the ```filter``` *operator*. Generally speaking, this *operator* receives *Next* ```Event```s from the ```Signal``` it's attached to, and filters their ```Value```s by the predicate closure given. So in our case, take the ```String```s that come in from the ```stringSignal``` ```Signal``` and filter them by "contains 'cat'". Notice how this logic moves out of our ```observeNext```.
 
 This isn't the whole picture though. *Operator*s actually return brand new ```Signal```s that fire *Next* ```Event```s using their transform. So in the case of ```filter```, it fires when the predicate returns ```true```.
 
 This is truly awesome for a few reasons, but first of all it means we can observe this new ```Signal``` to be notified when the string contains a cat, but not touch the behaviour of the ```Signal``` we're ```filter``ing. ```Signal```s are immutable, and if we don't introduce any side effects then they **always** do the same thing. Hey look, your code just got way easier to read and understand!

 With *operator*s, you can not only set up very simple flows like the above, but also very complex flows that are still easy to understand. And all parts of the flow are observable by anything. Woah 🎇
 
 In fact, we can actually make this flow even more concise by just chaining it all together. This is the second reason *operator*s are truly awesome: Since they take a ```Signal``` and return a new ```Signal```, we can just chain them together without intermediate steps.
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
 So nice. And because the return types of *operator*s vs ```observe``` functions force the chain the follow the same pattern every time, we can reason about the flow easily. Create, transform, observe. ```Event```s start at the top and flow to the bottom. They don't jump between different objects or files or anything like that.
 
 What about the other problem with the eariler code, where we wanted to extend it to notify something when the string contains a "dog" and a "cat"?
 */
do {
    let catString = "cat"
    let dogString = "dog"
    
    let (stringSignal, stringObserver) = Signal<String, NoError>.pipe()
    
    let catSignal = stringSignal.filter { string in
        string.containsString(catString)
    }
    
    let catAndDogSignal = stringSignal.filter { string in
        string.containsString(catString) && string.containsString(dogString)
    }
    
    catSignal.observeNext { stringContainingCat in
        let x = stringContainingCat
    }
    
    catAndDogSignal.observeNext { stringContainingCatAndDog in
        let x = stringContainingCatAndDog
    }
    
    stringObserver.sendNext("I have a dog")
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
    stringObserver.sendNext("Terry has a dog and a cat and a million computers")
}
/*:
 It's too easy right? No side effects, no coupling, easy extension.
 
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
 Pretty simple - we use the ```map``` *operator* which has the exact same "return a ```Signal``` that fires transformed ```Event```s" characteristic. So, our ```map``` creates a new ```Signal``` that fires *Next* ```Event```s with the word "cat" replaced with 😺. We also just inserted it into our chain.

 What happens if a ```Signal``` sends a *Failed* ```Event```?
 */
do {
    enum DogError: ErrorType {
        case WeHaveADog
    }
    
    let catString = "cat"
    
    let (stringSignal, stringObserver) = Signal<String, DogError>.pipe()
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
    stringObserver.sendFailed(.WeHaveADog)
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
}
/*:
 You can see that the dog ruined all the fun 😾. When chaining, ```Event```s flow through the whole chain, so our *Failed* ```Event``` caused all the ```Signal```s to stop.
 
 Also notice that so our ```Signal``` can throw a ```DogError```, we have to specify this when creating the ```Signal```. Strong typing and all that.
 
 That was kind of a contrived example though - normally we would want to fail on a condition. The string "I have a dog" should automatically throw the ```.WeHaveADog``` *Failed* ```Event``` right? *Operator*s to the rescue:
 */
do {
    enum DogError: ErrorType {
        case StringHasADog
    }
    
    let catString = "cat"
    
    let (stringSignal, stringObserver) = Signal<String, DogError>.pipe()
    stringSignal
        .attempt { string -> Result<(), (DogError)> in
            if string.containsString("dog") {
                return .Failure(.StringHasADog)
            }
            return .Success()
        }
        .filter { string in
            string.containsString(catString)
        }
        .map { stringContainingCat in
            (stringContainingCat as NSString).stringByReplacingOccurrencesOfString("cat", withString: "😺")
        }
        .observe { event in
            switch event {
            case let .Next(string):
                string
            case let .Failed(error):
                error
            default:
                break
            }
        }
    
    stringObserver.sendNext("I have a dog")
    stringObserver.sendNext("Jim has a cat")
    stringObserver.sendNext("Steve has 2 computers")
}
/*:
 We can use the ```attempt``` *operator* to check for the error case and throw if it's met. Even though ```Success``` doesn't pass any value, it indicates that all is well and ```Event```s can continue down the chain untouched. Then it's just business as usual.
 */

//: [Next](@next)
