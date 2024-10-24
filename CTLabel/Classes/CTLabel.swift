///
//  CTLabel.swift
//
//  Created by Kenan Alizadeh.
//

import UIKit

public final class CTLabel: UIView {
    internal typealias StringAttribute = [NSAttributedString.Key: Any]

    private let layoutManager: NSLayoutManager
    private let textStorage: NSTextStorage
    private let textContainer: NSTextContainer

    private var initialAttributesCache: [(StringAttribute, NSRange)] = []
    private var truncationAttributedString: NSAttributedString?
    private var truncationReplacementGlyphRange: NSRange?
    private var replacementRangeLocationOffset: Int = 0

    public var numberOfLines: Int {
        get { textContainer.maximumNumberOfLines }
        set {
            guard newValue != textContainer.maximumNumberOfLines else { return }
            textContainer.maximumNumberOfLines = newValue
            resetAttributes()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override init(frame: CGRect) {
        self.layoutManager = NSLayoutManager()
        self.textStorage = NSTextStorage()
        self.textContainer = NSTextContainer()
        super.init(frame: frame)

        textContainer.lineFragmentPadding = 0
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
    }

    public override var intrinsicContentSize: CGSize {
        let textStorage = NSTextStorage(attributedString: textStorage)
        textStorage.copyAttributesFrom(textStorage, attributeKeys: [.font, .paragraphStyle])
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.maximumNumberOfLines = numberOfLines
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        return CGSize(width: bounds.width, height: ceil(boundingRect.height))
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        textContainer.size = bounds.size
        layoutManager.ensureLayout(for: textContainer)
    }

    public override func draw(_ rect: CGRect) {
        layoutManager.delegate = self
        textContainer.size = rect.size

        guard let context = UIGraphicsGetCurrentContext()
        else { return }
        context.saveGState()

        layoutManager.drawBackground(forGlyphRange: NSRange(location: 0, length: textStorage.length), at: .zero)
        truncationReplacementGlyphRange = makeTruncationReplacementGlyphRange()
        let fullRange = NSRange(location: 0, length: textStorage.length)

        if let truncationReplacementGlyphRange, let truncationAttributedString, truncationReplacementGlyphRange.isNonZero {
            let tempTextStorage = NSTextStorage(attributedString: truncationAttributedString)
            tempTextStorage.copyAttributesFrom(textStorage, attributeKeys: [.font, .paragraphStyle])
            let tempLayoutManager = NSLayoutManager()
            let tempTextContainer = NSTextContainer(size: textContainer.size)
            tempTextStorage.addLayoutManager(tempLayoutManager)
            tempLayoutManager.addTextContainer(tempTextContainer)

            var loop: Bool = true
            while loop {
                let replacementRange =  tempLayoutManager.glyphRange(for: tempTextContainer)
                let replacementRect = tempLayoutManager.boundingRect(forGlyphRange: replacementRange, in: tempTextContainer)
                let replacedRange = NSRange(
                    location: truncationReplacementGlyphRange.length - truncationAttributedString.length - replacementRangeLocationOffset,
                    length: truncationAttributedString.length + replacementRangeLocationOffset
                )

                let replacedRect = layoutManager.boundingRect(forGlyphRange: replacedRange, in: textContainer)

                if replacementRect.width > replacedRect.width {
                    replacementRangeLocationOffset += 1
                } else {
                    loop = false
                }
            }

            textStorage.beginEditing()
            truncationAttributedString.enumerateAttributes(in: NSMakeRange(0, truncationAttributedString.length)) { attributes, range, _ in
                let range = NSMakeRange(
                    truncationReplacementGlyphRange.length - truncationAttributedString.length + range.location - replacementRangeLocationOffset,
                    range.length
                )
                textStorage.addAttributes(attributes, range: range)
            }
            textStorage.ensureAttributesAreFixed(in: fullRange)
            textStorage.endEditing()
        } else {
            replacementRangeLocationOffset = 0
        }
        layoutManager.invalidateGlyphs(forCharacterRange: fullRange, changeInLength: 0, actualCharacterRange: nil)
        layoutManager.drawGlyphs(forGlyphRange: fullRange, at: .zero)

        context.restoreGState()
    }

    public func setContent(_ attributedString: NSAttributedString, truncationString: NSAttributedString?) {
        initialAttributesCache.removeAll()
        truncationReplacementGlyphRange = nil
        replacementRangeLocationOffset = 0

        truncationAttributedString = truncationString
        textStorage.setAttributedString(attributedString)
        attributedString.enumerateAttributes(
            in: NSRange(location: 0, length: attributedString.length),
            using: { attributes, range, _ in
                initialAttributesCache.append((attributes, range))
            }
        )
        textStorage.ensureAttributesAreFixed(in: NSRange(location: 0, length: textStorage.length))
        layoutManager.ensureLayout(for: textContainer)
        setNeedsLayout()
        setNeedsDisplay()
        invalidateIntrinsicContentSize()
    }

    private func resetAttributes() {
        textStorage.beginEditing()
        textStorage.invalidateAttributes(in: NSRange(location: 0, length: textStorage.length))
        initialAttributesCache.forEach { (attributes, range) in
            textStorage.addAttributes(attributes, range: range)
        }
        textStorage.endEditing()
    }

    private func makeTruncationReplacementGlyphRange() -> NSRange? {
        let totalRange = NSRange(location: 0, length: textStorage.length)
        let glyphRange = layoutManager.glyphRange(forBoundingRect: CGRect(origin: .zero, size: textContainer.size), in: textContainer)
        let truncatesText = NSMaxRange(totalRange) > NSMaxRange(glyphRange)
        return truncatesText ? glyphRange : nil
    }
}

extension CTLabel: NSLayoutManagerDelegate {
    public func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
        properties props: UnsafePointer<NSGlyphProperty>,
        characterIndexes charIndexes: UnsafePointer<Int>,
        font aFont: UIFont,
        forGlyphRange glyphRange: NSRange
    ) -> Int {
        guard let truncationReplacementGlyphRange, let truncationAttributedString else { return 0 }

        let glyphBuffer = UnsafeMutablePointer<CGGlyph>.allocate(capacity: glyphRange.length)
        glyphBuffer.initialize(from: glyphs, count: glyphRange.length)

        let tempTextStorage = NSTextStorage(attributedString: truncationAttributedString)
        tempTextStorage.copyAttributesFrom(textStorage, attributeKeys: [.font, .paragraphStyle])
        let tempLayoutManager = NSLayoutManager()
        let tempTextContainer = NSTextContainer(size: textContainer.size)
        tempTextStorage.addLayoutManager(tempLayoutManager)
        tempLayoutManager.addTextContainer(tempTextContainer)
        let truncationGlyphRange = tempLayoutManager.glyphRange(for: tempTextContainer)

        let rangeOffset = glyphRange.location
        let replacementRange = NSMakeRange(
            NSMaxRange(
                truncationReplacementGlyphRange
            ) - truncationGlyphRange.length - replacementRangeLocationOffset,
            truncationGlyphRange.length
        )
        let intersectionRange = NSIntersectionRange(glyphRange, replacementRange)

        if intersectionRange.isNonZero {
            for idx in intersectionRange.location ..< NSMaxRange(intersectionRange) {
                let replacementGlyph = tempLayoutManager.glyph(at: idx - replacementRange.location)
                glyphBuffer[idx - rangeOffset] = replacementGlyph
            }
        }

        for idx in glyphRange.location ..< NSMaxRange(glyphRange) {
            if replacementRange.isNonZero && idx >= NSMaxRange(replacementRange) {
                glyphBuffer[idx - rangeOffset] = CGGlyph(0)
            }
        }

        layoutManager.setGlyphs(glyphBuffer,
                                properties: props,
                                characterIndexes: charIndexes,
                                font: aFont,
                                forGlyphRange: glyphRange)

        glyphBuffer.deallocate()

        return glyphRange.length
    }
}

extension NSTextStorage {
    func copyAttributesFrom(_ textStorage: NSTextStorage, attributeKeys: [NSAttributedString.Key]) {
        attributeKeys.forEach { key in
            if let val = textStorage.attributes(at: 0, effectiveRange: nil)[key] {
                addAttribute(key, value: val, range: NSMakeRange(0, length))
            }
        }
    }
}

extension NSRange {
    var isNonZero: Bool {
        length != 0 && location >= 0
    }
}
