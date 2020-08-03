var exec = require('cordova/exec');

/**
 * Scan and retreive line occurence of the given text.
 *
 * @param success success callback which contains the array of lines.
 * @param error error callback with error message.
 * @param text Text whose lines to be identified in a page
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
