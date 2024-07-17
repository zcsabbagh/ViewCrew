import UIKit
import SwiftUI

class EmojiShowerViewController: UIViewController {
    
    var emoji: String
    var emojiEmitter: CAEmitterLayer?
    
    init(emoji: String) {
        self.emoji = emoji
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        createEmojiShower()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fadeOutEmojiShower()
        }
    }
    
    // Function to create the emoji shower effect
    func createEmojiShower() {
        let emojiEmitter = CAEmitterLayer()
        
        emojiEmitter.emitterPosition = CGPoint(x: view.center.x, y: -50)
        emojiEmitter.emitterShape = .line
        emojiEmitter.emitterSize = CGSize(width: view.frame.size.width, height: 1)
        
        let cell = makeEmojiEmitterCell(emoji: emoji)
        emojiEmitter.emitterCells = [cell]
        
        view.layer.addSublayer(emojiEmitter)
        self.emojiEmitter = emojiEmitter
    }
    
    func fadeOutEmojiShower() {
        guard let emojiEmitter = emojiEmitter else { return }
        
        // Gradually reduce birth rate
        let fadeOutAnimation = CABasicAnimation(keyPath: "birthRate")
        fadeOutAnimation.fromValue = emojiEmitter.birthRate
        fadeOutAnimation.toValue = 0
        fadeOutAnimation.duration = 0.2
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        emojiEmitter.add(fadeOutAnimation, forKey: "fadeOutBirthRate")
        
        // Remove emitter after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            emojiEmitter.removeFromSuperlayer()
            self.emojiEmitter = nil
        }
    }
    
    // Function to create an emitter cell for a specific emoji
    func makeEmojiEmitterCell(emoji: String) -> CAEmitterCell {
        let cell = CAEmitterCell()
        
        cell.birthRate = 10
        cell.lifetime = 3
        cell.lifetimeRange = 0
        
        cell.velocity = CGFloat.random(in: 200...400)
        cell.velocityRange = 100
        
        cell.emissionLongitude = CGFloat.pi
        cell.emissionRange = CGFloat.pi / 4
        
        cell.spin = 2
        cell.spinRange = 3
        cell.scaleRange = 0.5
        cell.scaleSpeed = -0.05
        
        
        // Add alpha speed for fading out individual emojis
        // cell.alphaSpeed = -0.5
        // cell.alphaRange = 0.5
        
        if let emojiImage = imageFrom(emoji: emoji) {
            cell.contents = emojiImage.cgImage
        }
        
        return cell
    }
    
    // Function to create an image from emoji text
    func imageFrom(emoji: String) -> UIImage? {
        let label = UILabel()
        label.text = emoji
        label.font = UIFont.systemFont(ofSize: 30)
        label.sizeToFit()
        
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, UIScreen.main.scale)
        
        if let context = UIGraphicsGetCurrentContext() {
            label.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        
        return nil
    }
}
