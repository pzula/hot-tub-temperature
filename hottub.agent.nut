#require "IFTTT.class.nut:1.0.0"

const SECRET_KEY = "b0sY88A3ZhhYtjYKnSsObv";
ifttt <- IFTTT(SECRET_KEY);

function tempHandler(tempFarenheight) {
    if (tempFarenheight < 50) {
        sendToIFTTT(tempFarenheight);
        server.log(format("SENT to IFTTT for %3.2f", tempFarenheight));
    } 
    else {
        server.log(format("Not sending IFTTT for %3.2f", tempFarenheight));
    }
}


function sendToIFTTT(data) {
     // Trigger an event with one value and a callback with IFTTT
    ifttt.sendEvent("low_temp_alert", data, function(err, response) {
        if (err) {
           server.error(err);
           return;
        }

        server.log("Success!");
    });    
}

device.on("temp.in.f", tempHandler);
