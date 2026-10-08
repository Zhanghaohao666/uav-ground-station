// Preserve valid shared-camera URLs and manual open/closed choices.
var sharedDefaults = ["rtsp://192.168.2.36:8554/board", "rtsp://192.168.2.36:8554/rgb"];

function repairShared(facts) {
    for (var i = 0; i < 2; ++i) {
        var current = String(facts[i].rawValue || "").trim();
        var match = /^(rtsp:\/\/(?:192\.168\.2\.36|192\.168\.1\.104):8554)\/(board|rgb|algorithm|preview|infrared)\/?$/.exec(current);
        var expected = i === 0 ? "board" : "rgb";
        if (!current) facts[i].rawValue = sharedDefaults[i];
        else if (match && match[2] !== expected) facts[i].rawValue = match[1] + "/" + expected;
    }
}

function resetShared(facts) {
    for (var i = 0; i < 2; ++i) {
        if (facts[i].rawValue !== sharedDefaults[i]) facts[i].rawValue = sharedDefaults[i];
    }
}

// Only the actual tracking input may send point/box commands. A preview URL
// in an algorithm-labelled slot must never redirect clicks to the tracker.
function controlTarget(uri) {
    var match = /^rtsp:\/\/[^\/]+\/(algorithm|gimbal|live\/0)\/?(?:\?.*)?$/.exec(String(uri || "").trim());
    if (!match) return "";
    return match[1] === "algorithm" ? "algorithm" : "gimbal";
}

function profile(mode) {
    if (mode === "algorithm") return {
        titles: ["下视 MIPI", "D455i 彩色", "前视算法", "前视原始预览", "算法板红外", ""],
        urls: ["rtsp://192.168.2.36:8554/algorithm", "rtsp://192.168.2.36:8554/preview", "rtsp://192.168.2.36:8554/infrared", ""],
        count: 5
    };
    if (mode === "gimbal") return {
        titles: ["下视 MIPI", "D455i 彩色", "云台可见光", "云台红外（预览）", "", ""],
        urls: ["rtsp://192.168.2.36:8555/gimbal", "rtsp://192.168.2.36:8556/gimbal_ir", "", ""],
        count: 4
    };
    return null;
}

function apply(mode, manager, facts, updateLayout) {
    var selected = profile(mode);
    if (!selected) return false;
    repairShared(facts);
    // Stop all old payload receivers before touching any URL. VideoManager's
    // asynchronous stop completion restarts only the latest requested URI.
    for (var i = 2; i < 6; ++i) manager.stopVideoStream(i);
    for (var j = 2; j < 6; ++j) facts[j].rawValue = selected.urls[j - 2];
    updateLayout(mode);
    for (var k = 2; k < selected.count; ++k) manager.startVideoStream(k);
    return true;
}

function previewOnly(mode, index) {
    return index === 5 || (mode === "gimbal" && index === 3) ||
           (mode === "algorithm" && index === 4);
}
