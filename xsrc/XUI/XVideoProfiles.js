// Payload-only presets. Shared slots 0 and 1 are deliberately untouched.
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
