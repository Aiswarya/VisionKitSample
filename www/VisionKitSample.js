var exec = require('cordova/exec');

/**
 * Scan and retreive line occurence of the given text.
 *
 * @param text Text whose lines to be identified in a page
 * @param success Success callback which contains the array of lines.
 * @param error Error callback with error message.
 */
exports.scanAndRetreiveLines = function (success, error, text) {
    if (typeof success != "function") {
        console.log("success must be of type function.");
        return
    }
    if (typeof error != "function") {
        console.log("error must be of type function.");
        return
    }
    try {
        //Error callback is invoked if string validation fails
        var inputText = text.toString();
        if (inputText.trim() == "" || /\n/.test(inputText)){
            error("Please make sure the input is neither empty nor contains newline character.");
        }else{
            exec(success, error, 'VisionKitSample', 'scanAndRetreiveLines', [inputText]);
        }
    }
    catch(err) {
        error("Invalid string.");
    }
};
