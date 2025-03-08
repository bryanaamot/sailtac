//
//  SpinnableCompass.swift
//  sail-tac
//
//  Created by Bryan Aamot on 1/11/25.
//


#if SKIP
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import java.lang.Math.toDegrees
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
//import androidx.compose.runtime.getValue
//import androidx.compose.runtime.mutableStateOf
//import androidx.compose.runtime.remember
//import androidx.compose.runtime.saveable.Saver
//import androidx.compose.runtime.saveable.rememberSaveable
//import androidx.compose.runtime.setValue
import androidx.compose.ui.unit.dp

#endif

import SwiftUI
struct SpinnableCompass: View {
    @Binding var wind: Double
    @Environment(\.colorScheme) var colorScheme
    @State var initialWindAngle = 0.0
    @State var accumulatedChange = 0.0
    
    #if SKIP
    @Composable
    func RotatableCircle() {
//        var wind by remember { mutableStateOf(0.0) }
//        var initialWindAngle by remember { mutableStateOf(0.0) }
        let context = LocalContext.current

        Box(
            modifier = Modifier
                .size(200.dp)
                .clip(CircleShape)
                .background(androidx.compose.ui.graphics.Color.Cyan)
                .pointerInput(Unit) {
                    detectTransformGestures { _, pan, zoom, rotation in
                        // Update wind direction based on rotation
                        if (!rotation.isNaN()) {
                            handleIncrementalRotation(rotation.toDouble())
                        }
                    }
                }
        )
    }
    #endif

    func handleIncrementalRotation(_ angle: Double) {
        accumulatedChange = accumulatedChange + angle
        let adjustedDegrees = initialWindAngle + accumulatedChange
        let finalWind = Double((Int(adjustedDegrees) % 360 + 360) % 360)
        wind = finalWind
        logger.debug("Wind: \(finalWind), change: \(accumulatedChange), angle: \(angle)")
    }

    
    func handleRotation(_ angle: Double) {
        let adjustedDegrees = initialWindAngle + angle
        wind = Double((Int(adjustedDegrees) % 360 + 360) % 360)
        logger.debug("Wind: \(wind), change: \(angle)")
    }
    
    var body: some View {
        let foregroundColor = (colorScheme == .dark ? Color.white : Color.black).opacity(0.7)
        let backgroundColor = (colorScheme == .dark ? Color.black : Color.white).opacity(0.4)
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                #if SKIP
                RotatableCircle()
                #else
                // Compass Circle
                Circle()
                    .stroke(foregroundColor, lineWidth: 2)
                    .frame(width: size, height: size)
                    .background(backgroundColor)
                    .cornerRadius(size/2)
                    .contentShape(Circle())
                    .gesture(RotationGesture()
                        .onChanged { value in
                            if !value.degrees.isNaN {
                                handleRotation(value.degrees)
                            }
                        }
                        .onEnded({ value in
                            initialWindAngle = wind
                        })
                    )
                #endif
                
                // Compass Directions
                ForEach(0..<360, id: \.self) { degree in
                    if degree % 30 == 0 {
                        VStack {
                            Text(compassLabel(for: degree))
                                .font(.system(size: 24))
                                .foregroundStyle(foregroundColor)
                                .rotationEffect(.degrees(Double(-degree)))
                            Spacer()
                        }
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(Double(degree)))
                    }
                }

                // Wind Indicator
                Triangle()
                    .fill(foregroundColor)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .rotationEffect(Angle(degrees: wind))
            }
            .onAppear {
                initialWindAngle = wind
            }

        }
    }


    // Helper to map angles to compass labels
    private func compassLabel(for degree: Int) -> String {
        switch degree {
        case 0: return "N"
        case 90: return "E"
        case 180: return "S"
        case 270: return "W"
        default: return ""
        }
    }
}

// Custom Shape for the Wind Indicator (Triangle)
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // Top point
        path.addLine(to: CGPoint(x: rect.midX + rect.width/3, y: rect.maxY)) // Bottom right
        path.addLine(to: CGPoint(x: rect.midX - rect.width/3, y: rect.maxY)) // Bottom left
        path.closeSubpath()
        return path
    }
}

struct SpinnableCompassPreview: PreviewProvider {
    @State static var wind = 0.0
    static var previews: some View {
        SpinnableCompass(wind: $wind)
            .frame(width: 300, height: 300)
            .padding()
    }
}
