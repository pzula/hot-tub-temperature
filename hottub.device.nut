function onewireReset() {
    // Configure UART for 1-Wire RESET timing
    ow.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);
    ow.write(0xF0);
    ow.flush();
    local read = ow.read();
    if (read == -1) {
        // No UART data at all
        server.log("No circuit connected to UART.");
        return false;
    } else if (read == 0xF0) {
        // UART RX will read TX if there's no device connected
        server.log("No 1-Wire devices are present.");
        return false;
    } else {
        // Switch UART to 1-Wire data speed timing
        ow.configure(115200, 8, PARITY_NONE, 1, NO_CTSRTS);
        return true;
    }
}
 
function onewireWriteByte(byte) {
    for (local i = 0 ; i < 8 ; i++, byte = byte >> 1) {
        // Run through the bits in the byte, extracting the
        // LSB (bit 0) and sending it to the bus
        onewireBit(byte & 0x01);
    }
} 
 
function onewireReadByte() {
    local byte = 0;
    for (local i = 0 ; i < 8 ; i++) {
        // Build up byte bit by bit, LSB first
        byte = (byte >> 1) + 0x80 * onewireBit(1);
    }
    return byte;
}
 
function onewireBit(bit) {
    bit = bit ? 0xFF : 0x00;
    ow.write(bit);
    ow.flush();
    local returnVal = ow.read() == 0xFF ? 1 : 0;
    return returnVal;
}
 
// Wake up every 900 (15 min) seconds and write to the server
 
function awakeAndGetTemp() {
    local tempLSB = 0;
    local tempMSB = 0;
    local tempCelsius = 0;
    local tempFarenheight = 0;
    
    // Run loop again in 900 seconds
    imp.wakeup(900.0, awakeAndGetTemp);
 
    if (onewireReset()) {
        onewireWriteByte(0xCC);
        onewireWriteByte(0x44);

        // Wait for at least 750ms for data to be collated
        imp.sleep(0.8);

        // Get the data
        onewireReset();
        onewireWriteByte(0xCC);
        onewireWriteByte(0xBE);

        tempLSB = onewireReadByte();
        tempMSB = onewireReadByte();

        // Reset bus to stop sensor sending unwanted data
        onewireReset();
    
        // Log the Celsius temperature
        tempCelsius = ((tempMSB * 256) + tempLSB) / 16.0;
        server.log(format("Temperature: %3.2f degrees C", tempCelsius));
           
        // Log Farenheight from Celsius
        // Multiply by 9, then divide by 5, then add 32
        tempFarenheight = (((tempCelsius * 9) / 5) + 32);
     
        server.log(format("Temperature: %3.2f degrees F", tempFarenheight));
        agent.send("temp.in.f", tempFarenheight);
    }
}
 
// PROGRAM STARTS HERE

ow <- hardware.uart12;
awakeAndGetTemp();
