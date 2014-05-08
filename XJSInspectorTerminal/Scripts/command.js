var objc = require('xjs/objc');
var log = require('xjs/log');

exports.pwd = function() {
    return objc.NSFileManager.defaultManager().currentDirectoryPath();
}

exports.cd = function(self, path) {
    path = self.stringByExpandingTildeInPath(path);
    var url = objc.NSURL.fileURLWithPath(path);
    if (objc.NSFileManager.defaultManager().changeCurrentDirectoryPath(url.path()))
    {
        return exports.pwd();
    }
    return false;
}

exports.ls = function(self, path) {
    if (path) {
        path = self.stringByExpandingTildeInPath(path);
    } else {
        path = exports.pwd();
    }
    return objc.NSFileManager.defaultManager().contentsOfDirectoryAtPath_error(path, null).join('\n');
}

exports.run = function(self, path) {
    path = self.stringByExpandingTildeInPath(path);
    return self.sendScript(path);
}
