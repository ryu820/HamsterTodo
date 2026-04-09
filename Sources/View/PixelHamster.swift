import AppKit

enum PixelHamster {
    enum Frame: Int, CaseIterable {
        case sitting = 0
        case cheeks = 1
        case sleeping = 2
    }

    // 18x18 pixel grid, each row is a string of hex chars
    // Colors: 0=transparent, 1=outline(#4a3728), 2=body(#f5c67a), 3=cheek(#ff9a9a),
    //         4=belly(#fff4d6), 5=eye(#1a1a1a), 6=nose(#d4845a), 7=ear-inner(#ffb6b6)
    private static let palette: [Character: (CGFloat, CGFloat, CGFloat, CGFloat)] = [
        "0": (0, 0, 0, 0),           // transparent
        "1": (0.29, 0.22, 0.16, 1),  // outline brown
        "2": (0.96, 0.78, 0.48, 1),  // body tan
        "3": (1.0, 0.60, 0.60, 1),   // cheek pink
        "4": (1.0, 0.96, 0.84, 1),   // belly cream
        "5": (0.1, 0.1, 0.1, 1),     // eye black
        "6": (0.83, 0.52, 0.35, 1),  // nose brown
        "7": (1.0, 0.71, 0.71, 1),   // ear inner pink
    ]

    // Frame 0: sitting
    private static let sittingPixels: [String] = [
        "000000000000000000",
        "000011000000110000",
        "000172100001721000",
        "001222210012222100",
        "012222221222222210",
        "012252212212522210",
        "012222212212222210",
        "012232162261232210",
        "012232222222232210",
        "001224222222422100",
        "001224444444422100",
        "000124444444421000",
        "000012444444210000",
        "000012222222210000",
        "000011222222110000",
        "000001211112100000",
        "000001100011000000",
        "000000000000000000",
    ]

    // Frame 1: cheeks puffed
    private static let cheeksPixels: [String] = [
        "000000000000000000",
        "000011000000110000",
        "000172100001721000",
        "001222210012222100",
        "012222221222222210",
        "012252212212522210",
        "012222212212222210",
        "013332162261333210",
        "013332222222333210",
        "001334222222433100",
        "001224444444422100",
        "000124444444421000",
        "000012444444210000",
        "000012222222210000",
        "000011222222110000",
        "000001211112100000",
        "000001100011000000",
        "000000000000000000",
    ]

    // Frame 2: sleeping
    private static let sleepingPixels: [String] = [
        "000000000000000000",
        "000011000000110000",
        "000172100001721000",
        "001222210012222100",
        "012222221222222210",
        "012212212212122210",
        "012252212212522210",
        "012232162261232210",
        "012232222222232210",
        "001224222222422100",
        "001224444444422100",
        "000124444444421000",
        "000012444444210000",
        "000012222222210000",
        "000011222222110000",
        "000001211112100000",
        "000001100011000000",
        "000000000000000000",
    ]

    static func makeImage(frame: Frame, size: CGFloat = 18) -> NSImage {
        let pixels: [String]
        switch frame {
        case .sitting: pixels = sittingPixels
        case .cheeks: pixels = cheeksPixels
        case .sleeping: pixels = sleepingPixels
        }

        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        for (row, line) in pixels.enumerated() {
            for (col, char) in line.enumerated() {
                guard let color = palette[char], color.3 > 0 else { continue }
                context.setFillColor(
                    CGColor(red: color.0, green: color.1, blue: color.2, alpha: color.3)
                )
                let rect = CGRect(
                    x: CGFloat(col) * (size / 18.0),
                    y: size - CGFloat(row + 1) * (size / 18.0),
                    width: size / 18.0 + 0.5,
                    height: size / 18.0 + 0.5
                )
                context.fill(rect)
            }
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
