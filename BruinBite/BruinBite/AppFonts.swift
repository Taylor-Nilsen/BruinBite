import SwiftUI

extension View {
    func appFont(_ style: Font.TextStyle) -> some View {
        self.font(.system(style, design: .rounded))
    }
    
    func appMonoFont(_ size: CGFloat) -> some View {
        self.font(.system(size: size, weight: .medium, design: .monospaced))
    }
}