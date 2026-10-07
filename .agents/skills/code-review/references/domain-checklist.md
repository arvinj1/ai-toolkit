# Domain Review Checklist

Use only checks relevant to the changed behavior. These are prompts for investigation, not a requirement to find a defect.

## Real-time communications

- Are signaling state and media state kept distinct and reconciled after reconnect?
- Are RTP timestamps, sequence numbers, clock rates, RTCP reports, and wall-clock metrics interpreted in the correct domains?
- Are packet loss, reordering, jitter, NACK/PLI/FIR, retransmission, and congestion responses bounded and appropriate?
- Can codec negotiation, payload-type mapping, fmtp, SSRC changes, or renegotiation mismatch between peers?
- Are ICE candidates, TURN credentials, DTLS/SRTP setup, and endpoint changes handled through the actual supported lifecycle?
- Can buffering, resampling, transcoding, or queueing violate the latency budget under load?
- Do shutdown, device change, timeout, and peer loss release sockets, ports, threads, callbacks, and media resources exactly once?

## Modern C++

- Is ownership explicit across asynchronous boundaries? Can a callback outlive its object or capture a dangling reference?
- Are RAII, move semantics, exception guarantees, and error propagation correct on all exits?
- Are shared state, atomics, locks, and condition variables used consistently with the invariant? Check lock order and wakeup predicates.
- Could integer overflow, narrowing, signedness, alignment, aliasing, invalidated iterators, or string/view lifetime cause undefined behavior?
- Are thread-affine objects called on the right executor? Are queues bounded and cancellation-safe?
- Do hot-path cost claims have evidence from measurements or a credible operation-count analysis?

## Distributed systems

- Are writes idempotent across timeout and retry? Can a timeout occur after the remote side committed?
- Are retries bounded, jittered where needed, and prevented from amplifying overload?
- Are deadlines propagated across RPC and queue boundaries?
- What happens during partial failure, duplicate delivery, reordering, stale reads, split brain, or mixed-version rollout?
- Are queues, buffers, caches, and in-flight work bounded under sustained overload?
- Can failover lose, replay, or reorder work? Are recovery and reconciliation explicit?
- Can an operator distinguish dependency failure, overload, and data corruption from metrics, logs, and alerts?

## Verification

For each finding, identify the concrete path and evidence. Prefer a targeted test for the failed invariant. Do not recommend broad rewrites when a narrow correction addresses the risk.
