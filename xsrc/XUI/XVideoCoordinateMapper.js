.pragma library

function displayRect(viewWidth, viewHeight, videoWidth, videoHeight) {
    if (viewWidth <= 0 || viewHeight <= 0 || videoWidth <= 0 || videoHeight <= 0) {
        return null
    }

    var scale = Math.min(viewWidth / videoWidth, viewHeight / videoHeight)
    var width = videoWidth * scale
    var height = videoHeight * scale
    return {
        "x": (viewWidth - width) / 2,
        "y": (viewHeight - height) / 2,
        "width": width,
        "height": height
    }
}

function mapPoint(mouseX, mouseY, viewWidth, viewHeight, videoWidth, videoHeight) {
    var rect = displayRect(viewWidth, viewHeight, videoWidth, videoHeight)
    if (!rect || mouseX < rect.x || mouseX >= rect.x + rect.width ||
            mouseY < rect.y || mouseY >= rect.y + rect.height) {
        return null
    }

    var epsilon = 1e-7
    return {
        "x": Math.min(videoWidth - 1, Math.floor((mouseX - rect.x) * videoWidth / rect.width + epsilon)),
        "y": Math.min(videoHeight - 1, Math.floor((mouseY - rect.y) * videoHeight / rect.height + epsilon))
    }
}

function mapSelection(startX, startY, endX, endY,
                      viewWidth, viewHeight, videoWidth, videoHeight) {
    var rect = displayRect(viewWidth, viewHeight, videoWidth, videoHeight)
    if (!rect) {
        return null
    }

    var left = Math.max(rect.x, Math.min(startX, endX))
    var top = Math.max(rect.y, Math.min(startY, endY))
    var right = Math.min(rect.x + rect.width, Math.max(startX, endX))
    var bottom = Math.min(rect.y + rect.height, Math.max(startY, endY))
    if (right <= left || bottom <= top) {
        return null
    }

    var epsilon = 1e-7
    var videoLeft = Math.max(0, Math.floor((left - rect.x) * videoWidth / rect.width + epsilon))
    var videoTop = Math.max(0, Math.floor((top - rect.y) * videoHeight / rect.height + epsilon))
    var videoRight = Math.min(videoWidth, Math.ceil((right - rect.x) * videoWidth / rect.width - epsilon))
    var videoBottom = Math.min(videoHeight, Math.ceil((bottom - rect.y) * videoHeight / rect.height - epsilon))
    if (videoRight <= videoLeft || videoBottom <= videoTop) {
        return null
    }

    return {
        "x": videoLeft,
        "y": videoTop,
        "width": videoRight - videoLeft,
        "height": videoBottom - videoTop,
        "displayX": left,
        "displayY": top,
        "displayWidth": right - left,
        "displayHeight": bottom - top
    }
}
