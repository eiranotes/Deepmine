import SwiftUI

enum ProbePalette {
    // Four pigments, mixed only through opacity: coal, shale, limestone, and lamp brass.
    static let coal = Color(red: 16 / 255, green: 16 / 255, blue: 15 / 255)
    static let shale = Color(red: 55 / 255, green: 54 / 255, blue: 48 / 255)
    static let limestone = Color(red: 231 / 255, green: 224 / 255, blue: 207 / 255)
    static let brass = Color(red: 197 / 255, green: 140 / 255, blue: 57 / 255)

    static let abyss = coal
    static let rockDeep = shale
    static let rockMid = limestone.opacity(0.13)
    static let rockLight = limestone.opacity(0.30)
    static let metal = limestone.opacity(0.52)
    static let highlight = limestone.opacity(0.76)
    static let chalk = limestone
}
