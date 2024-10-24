//
//  ViewController.swift
//  CTLabel
//
//  Created by Kenan Alizadeh on 10/24/2024.
//  Copyright (c) 2024 Kenan Alizadeh. All rights reserved.
//

import UIKit
import CTLabel

final class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let rawString = "Some apps, such as book and magazine readers, text editors, and games, may need to lay out their text in a way that better fits their app style. TextKit provides a set of APIs for these apps to implement a custom text layout. This sample demonstrates how to use the APIs to display text in a circular container and in a two-column container, how to set up an exclusive area for a text container, and how to substitute a glyph without changing the text storage."
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 24
        paragraphStyle.lineHeightMultiple = 1.26
        let font = UIFont.systemFont(ofSize: 16, weight: .regular)
        let attributedString = NSAttributedString(
            string: rawString,
            attributes: [
                .foregroundColor: UIColor.black,
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )
        let attributedTruncationString: NSAttributedString = {
            let ellipsisString = "\u{2026} "
            let attrStr1 = NSAttributedString(string: ellipsisString, attributes: [.foregroundColor: UIColor.black])

            let moreString = "More"
            let attrStr2 = NSAttributedString(string: moreString, attributes: [.foregroundColor: UIColor.red])

            let attributedString = NSMutableAttributedString()
            attributedString.append(attrStr1)
            attributedString.append(attrStr2)
            return attributedString
        }()
        let label = CTLabel()
        label.backgroundColor = .white
        label.setContent(attributedString, truncationString: attributedTruncationString)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 3
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            label.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -32)
        ])
    }
}
