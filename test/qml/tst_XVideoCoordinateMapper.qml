import QtQuick 2.15
import QtTest 1.2

import "../../xsrc/XUI/XVideoCoordinateMapper.js" as CoordinateMapper

TestCase {
    name: "XVideoCoordinateMapper"

    function test_letterboxDisplayRect() {
        var rect = CoordinateMapper.displayRect(1000, 1000, 1920, 1080)
        compare(rect.x, 0)
        fuzzyCompare(rect.y, 218.75, 0.001)
        compare(rect.width, 1000)
        fuzzyCompare(rect.height, 562.5, 0.001)
    }

    function test_centerPoint() {
        var point = CoordinateMapper.mapPoint(500, 500, 1000, 1000, 1920, 1080)
        compare(point.x, 960)
        compare(point.y, 540)
    }

    function test_letterboxPointIsRejected() {
        verify(CoordinateMapper.mapPoint(500, 100, 1000, 1000, 1920, 1080) === null)
    }

    function test_sourceResolutionIsNotHardCoded() {
        var point = CoordinateMapper.mapPoint(250, 250, 500, 500, 640, 480)
        compare(point.x, 320)
        compare(point.y, 240)
    }

    function test_reverseSelection() {
        var box = CoordinateMapper.mapSelection(
                    750, 640.625, 250, 359.375,
                    1000, 1000, 1920, 1080)
        compare(box.x, 480)
        compare(box.y, 270)
        compare(box.width, 960)
        compare(box.height, 540)
    }

    function test_selectionIsClippedToVideo() {
        var box = CoordinateMapper.mapSelection(
                    900, 600, 1100, 900,
                    1000, 1000, 1920, 1080)
        compare(box.x, 1728)
        compare(box.y, 732)
        compare(box.width, 192)
        compare(box.height, 348)
    }

    function test_invalidVideoSize() {
        verify(CoordinateMapper.displayRect(1000, 1000, 0, 0) === null)
        verify(CoordinateMapper.mapSelection(0, 0, 10, 10, 1000, 1000, 0, 0) === null)
    }
}
