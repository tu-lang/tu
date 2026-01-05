
// async
// reactor at max registered I/O resources
OtherReactorOverMaxIo<i32> = 50397240
// failed to find event loop
OtherFailedFindEvent<i32> = 50397241
// reactor gone
OtherReactorGone<i32> = 50397242
// IO driver has terminated
OtherDriverTerminated<i32> = 50397243
// A async 1.x context was found, but it is being shutdown.
OtherRuntime1XNotFound<i32> = 50397244
// bytes remaining on stream
OtherBytesRemainOnStream<i32> = 50397245
// failed to write frame to transport
WriteZeroFailedWriteFrameTransport<i32> = 50397246
// park error
ParkError<i32> = 50397247
// header decode error
OtherDecodeErr<i32> = 16908352
// only HTTP/1.1 accepted
OtherOnlyHttpV1Accepted<i32> = 16908353
// serde_json error
OtherSerdeJson<i32> = 16908355
// Connection closed normally
ConnectionClosed<i32> = 67371009
// Trying to work with closed connection
AlreadyClosed<i32> = 67371010
/// Type of data frame not recognised.
ProtocolUnknownDataFrameType<i32> = 67502084
/// Received data while waiting for more fragments.
ProtocolExpectedFragment<i32> = 67502085
/// Received a continue frame despite there being nothing to continue.
ProtocolUnexpectedContinueFrame<i32> = 67502086
/// Type of control frame not recognised.
ProtocolUnknownControlFrameType<i32> = 67502087
/// Unsupported HTTP method used - only GET is allowed
ProtocolWrongHttpMethod<i32> = 67502088
/// HTTP version must be 1.1 or higher
ProtocolWrongHttpVersion<i32> = 67502089
/// No "Connection: upgrade" header
ProtocolMissingConnectionUpgradeHeader<i32> = 67502090
/// No "Upgrade: websocket" header
ProtocolMissingUpgradeWebSocketHeader<i32> = 67502091
/// No "Sec-WebSocket-Version: 13" header
ProtocolMissingSecWebSocketVersionHeader<i32> = 67502092
/// No "Sec-WebSocket-Key" header
ProtocolMissingSecWebSocketKey<i32> = 67502093
/// Key mismatch in "Sec-WebSocket-Accept" header
ProtocolSecWebSocketAcceptKeyMismatch<i32> = 67502094
/// Junk after client request
ProtocolJunkAfterRequest<i32> = 67502095
/// Custom response must not be successful
ProtocolCustomResponseSuccessful<i32> = 67502096
/// Missing, duplicated or incorrect header {0}
ProtocolInvalidHeader<i32> = 67502097
/// Handshake not finished
ProtocolHandshakeIncomplete<i32> = 67502098
/// httparse error: {0}
ProtocolHttparseError<i32> = 67502099
/// Sending after closing is not allowed
ProtocolSendAfterClosing<i32> = 67502100
/// Remote sent after having closed
ProtocolReceivedAfterClosing<i32> = 67502101
/// Reserved bits are non-zero
ProtocolNonZeroReservedBits<i32> = 67502102
/// Received an unmasked frame from client
ProtocolUnmaskedFrameFromClient<i32> = 67502103
/// Received a masked frame from server
ProtocolMaskedFrameFromServer<i32> = 67502104
/// Fragmented control frame
ProtocolFragmentedControlFrame<i32> = 67502105
/// Control frame too big (payload must be 125 bytes or less)
ProtocolControlFrameTooBig<i32> = 67502106
/// Connection reset without closing handshake
ProtocolResetWithoutClosingHandshake<i32> = 67502107
/// Encountered invalid opcode: {0}
ProtocolInvalidOpcode<i32> = 67502108
/// Invalid close sequence
ProtocolInvalidCloseSequence<i32> = 67502109
/// Type of control frame not recognised.
ProtocolFrameNotRecognised<i32> = 67502111

/// A text WebSocket message is invalid or failed to be processed
SendQueueFullInvalidText<i32> = 67567648
/// A binary WebSocket message is invalid or failed to be processed
SendQueueFullInvalidBinary<i32> = 67567649
/// Ping message payload length must be < 125 bytes
SendQueueFullPingTooLarge<i32> = 67567650
/// Pong message payload length must be < 125 bytes
SendQueueFullPongTooLarge<i32> = 67567651
/// Failed to construct or process a Close frame
SendQueueFullInvalidCloseFrame<i32> = 67567652
/// Raw frame received in a context where raw frames are not allowed
SendQueueFullUnexpectedRawFrame<i32> = 67567653

// Too many headers provided (see
CapacityErrorTooManyHeaders<i32> = 67633190
/// Message is bigger than the maximum allowed size.
CapacityErrorMessageTooLong<i32> = 67633190

/// TLS is used despite not being compiled with the TLS feature enabled.
UrlTlsFeatureNotEnabled<i32> = 67698727
/// The URL does not include a host name.
UrlNoHostName<i32> = 67698728
/// Failed to connect with this URL.
UrlUnableToConnect<i32> = 67698729
/// Unsupported URL scheme used (only `ws://` or `wss://` may be used).
UrlUnsupportedUrlScheme<i32> = 67698730
/// The URL host name, though included, is empty.
UrlEmptyHostName<i32> = 67698731
/// The URL does not include a path/query.
UrlNoPathOrQuery<i32> = 67698732
// HTTP error.
HttpResponse<i32> = 67371053
// HTTP format error
HttpFormat<i32> = 67371054
// UTF-8 encoding error
ErrUtf8<i32> = 67371055
// other
IOOther<i32> = 67436592
/// Native TLS error.
TlsErrorNative<i32> = 67764273
/// Rustls error.
TlsErrorRustls<i32> = 67764274
/// Webpki error.
TlsErrorWebpki<i32> = 67764275
/// DNS name resolution error.
TlsErrorInvalidDnsName<i32> = 67764276