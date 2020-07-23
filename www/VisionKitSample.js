var exec = require('cordova/exec');

/**
 * Scan and retreive line occurence of the given text.
 *
 * @param text Text whose lines to be is dentified in a page
 * @param success success callback which contains the array of lines.
 * @param error error callback with error message.
 */
exports.scanAndRetreiveLines = function (text,success, error) {
    exec(success, error, 'VisionKitSample', 'scanAndRetreiveLines', [text]);
};
