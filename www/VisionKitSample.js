var exec = require('cordova/exec');

/**
 * Scan and retreive line occurence of the given text.
 *
 * @param text Text whose lines to be identified in a page
 * @param success Success callback which contains the array of lines.
 * @param error Error callback with error message.
 */
exports.scanAndRetreiveLines = function (text,success, error) {
    exec(success, error, 'VisionKitSample', 'scanAndRetreiveLines', [text]);
};
