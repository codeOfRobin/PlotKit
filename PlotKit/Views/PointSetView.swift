// Copyright © 2015 Venture Media Labs. All rights reserved.
//
// This file is part of PlotKit. The full PlotKit copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

/// PointSetView draws a discrete set of 2D points, optionally connecting them with lines. PointSetView does not draw axes or any other plot decorations, use a `PlotView` for that.
public class PointSetView: DataView {
    public var pointSet: PointSet {
        didSet {
            needsDisplay = true
        }
    }

    public init() {
        pointSet = PointSet()
        super.init(frame: NSRect(x: 0, y: 0, width: 512, height: 512))
    }

    public init(pointSet: PointSet) {
        self.pointSet = pointSet
        super.init(frame: NSRect(x: 0, y: 0, width: 512, height: 512))

        self.xInterval = pointSet.xInterval
        self.yInterval = pointSet.yInterval
    }

    public init(pointSet: PointSet, xInterval: ClosedInterval<Double>, yInterval: ClosedInterval<Double>) {
        self.pointSet = pointSet
        super.init(frame: NSRect(x: 0, y: 0, width: 512, height: 512))

        self.xInterval = xInterval
        self.yInterval = yInterval
    }

    public override func valueAt(location: NSPoint) -> Double? {
        let boundsXInterval = Double(bounds.minX)...Double(bounds.maxX)
        let boundsYInterval = Double(bounds.minY)...Double(bounds.maxY)
        var minDistance = CGFloat.max
        var minValue = Double?()
        for point in pointSet.points {
            let x = CGFloat(mapValue(point.x, fromInterval: xInterval, toInterval: boundsXInterval))
            let y = CGFloat(mapValue(point.y, fromInterval: yInterval, toInterval: boundsYInterval))
            let d = hypot(location.x - x, location.y - y)
            if d < 8 && d < minDistance {
                minDistance = d
                minValue = point.y
            }
        }
        return minValue
    }

    public override func drawRect(rect: CGRect) {
        let context = NSGraphicsContext.currentContext()?.CGContext
        CGContextSetLineWidth(context, pointSet.lineWidth)

        if let color = pointSet.lineColor {
            color.setStroke()
            CGContextAddPath(context, path)
            CGContextStrokePath(context)
        }

        if let color = pointSet.fillColor {
            color.setFill()
            CGContextAddPath(context, closedPath)
            CGContextFillPath(context)
        }

        drawPoints(context)
    }

    var path: CGPath {
        let path = CGPathCreateMutable()
        if pointSet.points.isEmpty {
            return path
        }

        let first = pointSet.points.first!
        let startPoint = convertToView(x: first.x, y: first.y)
        CGPathMoveToPoint(path, nil, startPoint.x, startPoint.y)

        for point in pointSet.points {
            let point = convertToView(x: point.x, y: point.y)
            CGPathAddLineToPoint(path, nil, point.x, point.y)
        }

        return path
    }

    var closedPath: CGPath {
        let path = CGPathCreateMutable()
        if pointSet.points.isEmpty {
            return path
        }

        let first = pointSet.points.first!
        let startPoint = convertToView(x: first.x, y: 0)
        CGPathMoveToPoint(path, nil, startPoint.x, startPoint.y)

        for point in pointSet.points {
            let point = convertToView(x: point.x, y: point.y)
            CGPathAddLineToPoint(path, nil, point.x, point.y)
        }

        let last = pointSet.points.last!
        let endPoint = convertToView(x: last.x, y: 0)
        CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)
        CGPathCloseSubpath(path)

        return path
    }


    // MARK: - Point drawing

    func drawPoints(context: CGContext?) {
        if let color = pointSet.pointColor {
            color.setFill()
        } else if let color = pointSet.lineColor {
            color.setFill()
        } else {
            NSColor.blackColor().setFill()
        }

        for point in pointSet.points {
            let point = convertToView(x: point.x, y: point.y)
            drawPoint(context, center: point)
        }
    }

    func drawPoint(context: CGContext?, center: CGPoint) {
        switch pointSet.pointType {
        case .None:
            break

        case .Ring(let radius):
            self.drawCircle(context, center: center, radius: radius)

        case .Disk(let radius):
            self.drawDisk(context, center: center, radius: radius)

        case .Square(let side):
            self.drawSquare(context, center: center, side: side)

        case .FilledSquare(let side):
            self.drawFilledSquare(context, center: center, side: side)
        }
    }

    func drawCircle(context: CGContextRef?, center: CGPoint, radius: Double) {
        let rect = NSRect(
            x: center.x - CGFloat(radius),
            y: center.y - CGFloat(radius),
            width: 2 * CGFloat(radius),
            height: 2 * CGFloat(radius))
        CGContextStrokeEllipseInRect(context, rect)
    }

    func drawDisk(context: CGContextRef?, center: CGPoint, radius: Double) {
        let rect = NSRect(
            x: center.x - CGFloat(radius),
            y: center.y - CGFloat(radius),
            width: 2 * CGFloat(radius),
            height: 2 * CGFloat(radius))
        CGContextFillEllipseInRect(context, rect)
    }

    func drawSquare(context: CGContextRef?, center: CGPoint, side: Double) {
        let rect = NSRect(
            x: center.x - CGFloat(side/1),
            y: center.y - CGFloat(side/1),
            width: CGFloat(side),
            height: CGFloat(side))
        CGContextStrokeRect(context, rect)
    }

    func drawFilledSquare(context: CGContextRef?, center: CGPoint, side: Double) {
        let rect = NSRect(
            x: center.x - CGFloat(side/1),
            y: center.y - CGFloat(side/1),
            width: CGFloat(side),
            height: CGFloat(side))
        CGContextFillRect(context, rect)
    }

    // MARK: - Helper functions

    func convertToView(x x: Double, y: Double) -> CGPoint {
        let boundsXInterval = Double(bounds.minX)...Double(bounds.maxX)
        let boundsYInterval = Double(bounds.minY)...Double(bounds.maxY)
        return CGPoint(
            x: mapValue(x, fromInterval: xInterval, toInterval: boundsXInterval),
            y: mapValue(y, fromInterval: yInterval, toInterval: boundsYInterval))
    }

    
    // MARK: - NSCoding
    
    public required init?(coder: NSCoder) {
        pointSet = PointSet()
        super.init(coder: coder)
    }
}
