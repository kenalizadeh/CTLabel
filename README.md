# CTLabel
Custom Trailing Truncation Label with [TextKit](https://developer.apple.com/documentation/appkit/textkit)

# Usage

```swift
let rawString = "long text"
let attributedString = NSAttributedString(
    string: rawString,
    attributes: [
        .foregroundColor: textColor,
        .font: font,
        .paragraphStyle: paragraphStyle,
        ...
    ]
)
let attributedTruncationString: NSAttributedString = {
    let ellipsisString = "\u{2026} "
    let attrStr1 = NSAttributedString(string: ellipsisString, attributes: [.foregroundColor: UIColor.black])

    let moreString = "Read more"
    let attrStr2 = NSAttributedString(string: moreString, attributes: [.foregroundColor: UIColor.red])

    let attributedString = NSMutableAttributedString()
    attributedString.append(attrStr1)
    attributedString.append(attrStr2)
    return attributedString
}()
let label = CTLabel()
label.setContent(attributedString, truncationString: attributedTruncationString)
label.numberOfLines = 3
...
```

![](https://github.com/user-attachments/assets/5eeb1485-9062-470a-9741-bb726824f708)
![](https://github.com/user-attachments/assets/29f343d9-38eb-4181-8efe-395e803b45f3)

## Installation

### CocoaPods
```ruby
pod 'CTLabel'
```

### SPM
```
https://github.com/kenalizadeh/CTLabel
```

## Author

Kenan Alizadeh, kananalizade@gmail.com

## License

CTLabel is available under the MIT license. See the LICENSE file for more info.
