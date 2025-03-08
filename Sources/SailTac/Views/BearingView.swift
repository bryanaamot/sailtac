//
//  BearingView.swift
//  sail-tac
//
//  Created by Bryan Aamot on 2/9/25.
//

import SwiftUI

struct BearingView: View {
    @Binding var showBearing: Bool
    @Binding var marks: [Mark]
    @Binding var selectedMarkIndex: Int
    
    @EnvironmentObject private var appData: AppData
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            VStack {
                HStack {
                    Spacer()
                    Button( action: {
                        showBearing = false
                    }, label: {
                        Text("X")
                            .font(.system(size: 20))
                            .foregroundColor(Color.primary)
                    })
                }
                .padding(.bottom, -30)
                if selectedMarkIndex >= 0 && selectedMarkIndex < marks.count {
                    let mark = marks[selectedMarkIndex]
                    let markBearing = Bearing.bearingToLocation(lat1: appData.location.lat, lon1: appData.location.lon, lat2: mark.latitude, lon2: mark.longitude)
                    let direction = Bearing.minus180To180(markBearing - appData.heading)
                    let meters = Bearing.distanceToLocation(lat1: appData.location.lat, lon1: appData.location.lon, lat2: mark.latitude, lon2: mark.longitude)
                    ZStack {
                        ArrowShape()
                            .stroke(Color.primary, lineWidth: 10)
                            .frame(width: 120, height: 120)
                            .rotationEffect(Angle(degrees: Double(direction)))
                            .animation(.easeInOut(duration: 0.3), value: direction)
                        Text("\(direction)º")
                            .font(.system(size: 24))
                    }
                    .padding()
                    
                    let measurement = Measurement(value: meters, unit: UnitLength.meters)
                    let feet = measurement.converted(to: UnitLength.feet).value
                    let metersText = "\(Int(round(meters))) \(UnitLength.meters.symbol)"
                    let feetText = "\(Int(round(feet))) \(UnitLength.feet.symbol)"
                    Text("\(metersText) (\(feetText))")
                        .font(.system(size: 24))
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.6))
            .cornerRadius(20)
            .padding(24)
        }
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let arrowWidth = rect.width * 1.0
        let arrowHeight = rect.height * 0.666
        let shaftWidth = rect.width * 0.55
        let shaftHeight = rect.height - arrowHeight
        
        let tipY = rect.minY
        let arrowBaseY = tipY + arrowHeight
        let shaftBottomY = tipY + shaftHeight + arrowHeight
        
        // Draw the arrowhead
        path.move(to: CGPoint(x: rect.midX, y: tipY)) // Arrow tip
        path.addLine(to: CGPoint(x: rect.midX + arrowWidth / 2, y: arrowBaseY))
        path.addLine(to: CGPoint(x: rect.midX + shaftWidth / 2, y: arrowBaseY))
        path.addLine(to: CGPoint(x: rect.midX + shaftWidth / 2, y: shaftBottomY))
        path.addLine(to: CGPoint(x: rect.midX - shaftWidth / 2, y: shaftBottomY))
        path.addLine(to: CGPoint(x: rect.midX - shaftWidth / 2, y: arrowBaseY))
        path.addLine(to: CGPoint(x: rect.midX - arrowWidth / 2, y: arrowBaseY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    ArrowShape()
        .stroke(Color.blue, lineWidth: 16)
        .frame(width: 150, height: 150)
        .background(Color.yellow)
}
