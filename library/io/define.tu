
fn layer_name(layer<i32>) i32* {
    match layer {
        1 : return "STD"
        2 : return "NETIO"
        3 : return "ASYNC_RUNTIME"
        4 : return "WS"
        _ : return "UNKNOWN_LAYER"
    }
}

fn module_name(module<i32>) i32* {
    match module {
        1  : return "OS"
        2  : return "CUSTOM"
        3  : return "IO_SIMPLE"
        4  : return "SIMPLE"
        5  : return "IO"
        6  : return "PROTOCOL"
        7  : return "SEND_QUEUE"
        8  : return "CAPCITY"
        9  : return "URL"
        10 : return "TLS"
        _  : return "UNKNOWN_MODULE"
    }
}

fn error_message(code<i32>) i8*{
    match code {
        /* ================= CUSTOM ================= */
        16908289 : return "An entity was not found, often a file"
        16908290 : return "The operation lacked the necessary privileges to complete"
        16908291 : return "The connection was refused by the remote server"
        16908292 : return "The connection was reset by the remote server"
        16908293 : return "The remote host is not reachable"
        16908294 : return "The network containing the remote host is not reachable"
        16908295 : return "The connection was aborted by the remote server"
        16908296 : return "The network operation failed because it was not connected yet"
        16908297 : return "Socket address already in use"
        16908298 : return "Address not available"
        16908299 : return "The system's networking is down"
        16908300 : return "The operation failed because a pipe was closed"
        16908301 : return "An entity already exists, often a file"
        16908302 : return "Operation would block"
        16908303 : return "Not a directory"
        16908304 : return "Is a directory"
        16908305 : return "Directory not empty"
        16908306 : return "Read-only filesystem"
        16908307 : return "Filesystem loop detected"
        16908308 : return "Stale network file handle"
        16908309 : return "Invalid input"
        16908310 : return "Invalid data"
        16908311 : return "Operation timed out"
        16908312 : return "Failed to write zero bytes"
        16908313 : return "Storage full"
        16908314 : return "Not seekable"
        16908315 : return "Filesystem quota exceeded"
        16908316 : return "File too large"
        16908317 : return "Resource busy"
        16908318 : return "Executable file busy"
        16908319 : return "Deadlock"
        16908320 : return "Cross-device link error"
        16908321 : return "Too many links"
        16908322 : return "Invalid filename"
        16908323 : return "Argument list too long"
        16908324 : return "Interrupted"
        16908325 : return "Unsupported operation"
        16908326 : return "Unexpected end of file"
        16908327 : return "Out of memory"
        16908328 : return "Other error"
        16908329 : return "Uncategorized error"
        16908330 : return "Formatter error"
        16908331 : return "Failed to write whole buffer"
        16908332 : return "Failed to fill whole buffer"
        16908333 : return "Cursor position exceeds maximum"
        16908334 : return "Invalid seek: negative or overflow"
        16908335 : return "Invalid socket address"
        16908336 : return "Invalid port value"
        16908337 : return "Invalid argument"
        16908338 : return "Unexpected NUL byte in input"
        16908339 : return "Could not resolve to any addresses"
        16908340 : return "Path must be shorter than SUN_LEN"
        16908341 : return "Path contains interior NUL byte"
        16908342 : return "No address to send data to"

        /* ================= OS ================= */
        16842807 : return "OS error: EINPROGRESS"

        /* ================= ASYNC ================= */
        50397240 : return "Reactor at max I/O resources"
        50397241 : return "Failed to find event loop"
        50397242 : return "Reactor gone"
        50397243 : return "I/O driver terminated"
        50397244 : return "async 1.x runtime shutting down"
        50397245 : return "Bytes remaining on stream"
        50397246 : return "Failed to write frame to transport"
        50397247 : return "Park error"

        /* ================= SIMPLE ================= */
        67371009 : return "Connection closed normally"
        67371010 : return "Connection already closed"
        67371053 : return "HTTP response error"
        67371054 : return "HTTP format error"
        67371055 : return "UTF-8 encoding error"

        /* ================= PROTOCOL ================= */
        67502084 : return "Unknown data frame type"
        67502085 : return "Expected fragment"
        67502086 : return "Unexpected continue frame"
        67502087 : return "Unknown control frame type"
        67502088 : return "Unsupported HTTP method (only GET allowed)"
        67502089 : return "Wrong HTTP version"
        67502090 : return "Missing Connection: upgrade header"
        67502091 : return "Missing Upgrade: websocket header"
        67502092 : return "Missing Sec-WebSocket-Version header"
        67502093 : return "Missing Sec-WebSocket-Key header"
        67502094 : return "Sec-WebSocket-Accept key mismatch"
        67502095 : return "Junk after request"
        67502096 : return "Custom response must not be successful"
        67502097 : return "Invalid header"
        67502098 : return "Handshake incomplete"
        67502099 : return "httparse error"
        67502100 : return "Send after closing"
        67502101 : return "Received after closing"
        67502102 : return "Non-zero reserved bits"
        67502103 : return "Unmasked frame from client"
        67502104 : return "Masked frame from server"
        67502105 : return "Fragmented control frame"
        67502106 : return "Control frame too big"
        67502107 : return "Reset without closing handshake"
        67502108 : return "Invalid opcode"
        67502109 : return "Invalid close sequence"
        67502111 : return "Frame not recognised"

        /* ================= SEND QUEUE ================= */
        67567648 : return "Invalid text message"
        67567649 : return "Invalid binary message"
        67567650 : return "Ping payload too large"
        67567651 : return "Pong payload too large"
        67567652 : return "Invalid close frame"
        67567653 : return "Unexpected raw frame"

        /* ================= CAPCITY ================= */
        67633190 : return "Too many headers or message too long"

        /* ================= URL ================= */
        67698727 : return "TLS feature not enabled"
        67698728 : return "URL has no host name"
        67698729 : return "Unable to connect URL"
        67698730 : return "Unsupported URL scheme"
        67698731 : return "Empty URL host name"
        67698732 : return "URL missing path or query"

        /* ================= IO ================= */
        67436592 : return "I/O other error"

        /* ================= TLS ================= */
        67764273 : return "Native TLS error"
        67764274 : return "Rustls error"
        67764275 : return "Webpki error"
        67764276 : return "Invalid DNS name"

        _ : return "Unknown error code"
    }
}

