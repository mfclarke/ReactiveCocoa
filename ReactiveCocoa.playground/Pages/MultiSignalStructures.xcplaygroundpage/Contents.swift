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
 
 Something not demonstrated here is the way *Failed* ```Event```s work in these chains. It's very simple though - since *Failed* will stop the ```Signal```, no more *Next* ```Event```s will flow to the next ```Signal``` and the chain stops. But not before propogating the *Failed* ```Event``` through the whole chain first. Nice.
 
 The beauty of all this is that all our flow logic is mapped out in one place, in a compact concise way. We don't need to define other functions or objects to capture or beautify this logic.
 */

//: [Next](@next)
