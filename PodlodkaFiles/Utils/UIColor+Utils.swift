import UIKit

extension UIColor {
  var pixel: UIImage {
    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    return UIGraphicsImageRenderer(bounds: rect).image { ctx in
      ctx.cgContext.setFillColor(cgColor)
      ctx.cgContext.fill(rect)
    }
  }
}
