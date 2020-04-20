//
//  PopViewController.swift
//  PIxel City
//
//  Created by Chris Mercer on 20/04/2020.
//  Copyright © 2020 Chris Mercer. All rights reserved.
//

import UIKit

class PopViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    var passedImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = passedImage
        addDoubleTapRecogniser()
    }
    
    func loadImage(image: UIImage) {
        self.passedImage = image
    }
    
    func addDoubleTapRecogniser() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(PopViewController.doubleTapped))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        view.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc func doubleTapped() {
        dismiss(animated: true, completion: nil)
    }
}
