// Bounded mpsc Sender / Receiver (sync API; async send/recv via leaf fut deferred).

use runtime
use asyncio.sync as libsync

mem MpscSender {
    Chan* link
}

mem MpscReceiver {
    Chan* link
}

fn mpsc_bounded(cap<u32>) (MpscSender, MpscReceiver) {
    sem_bits<u64> = libsync.batch_sem_new_raw(cap)
    c<Chan> = Chan::new(sem_bits)
    return new MpscSender { link: c }, new MpscReceiver { link: c }
}

MpscSender::clone() MpscSender {
    this.link.inc_tx()
    return new MpscSender { link: this.link }
}

MpscSender::drop_send(){
    this.link.drop_last_sender()
}

MpscSender::try_send(v<i64>) i32 {
    return chan_send_inner(this.link, v)
}

MpscReceiver::try_recv() (i32, i64) {
    code<i32>, data<i64> = chan_recv_inner(this.link)
    return code, data
}

MpscReceiver::shutdown(){
    this.link.close_receiver()
}
