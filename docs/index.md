# twostep

HOTP and TOTP algorithms for 2-step verification (for OCaml).

This project implements algorithms for 2-step verification,
being the HMAC-based One-Time Password
(see [RFC 4226](https://tools.ietf.org/html/rfc4226)) and the
Time-based One-Time Password
(see [RFC 6238](https://tools.ietf.org/html/rfc6238)).

## Installation

If available on OPAM, try:

```shell
opam install twostep
```

Otherwise, you can install the development version of this
project with OPAM's `pin` command.

## Usage

The authentication of 2-step verification needs prior known
and shared secret between the client and server. If no
secret was send before, you can generate this Base32 secret
with:

```ocaml
let secret: string = Twostep.TOTP.secret();; (* kinda "A222 BBBB 3333 D5D5" *)
```

As an additional note, the `Twostep.TOTP.secret` function above uses
a cryptographically safe PRNG, that is, a secure source of pseudo
randomness. To generate the OTP code, for testing purposes mostly
('cause this one-time code should be generated on client-side -- unless
you use this library on the client's device), you can use this function:

```ocaml
let code: string = Twostep.TOTP.code ~secret:secret ();; (* kinda "098123" *)
```

The function above assumes the `SHA-1` hash algorithm, 30 seconds
as timestep/window before refreshed code, `6` digits for output
number code (padded with zeros on left sometimes) and no clock
drifts / not-sync time between server and client (that is, no
30 seconds on the past or on the future).

To verify one-time codes sent from client-side, use the following
function:

```ocaml
let valid: bool = Twostep.TOTP.verify ~secret:secret ~code:code ();;
```

This function assumes the same configuration of `Twostep.TOTP.code`,
except for the clock drift, where `Twostep.TOTP.verify` assumes too
past and future 30 seconds (ideal on slow connections or latency
problems). For the full API reference or coverage status, please refer to:
- [Generated API docs](https://www.marcoonroad.dev/twostep/apiref/twostep/index.html)
- [Generated API coverage](https://www.marcoonroad.dev/twostep/apicov/index.html)

You can test this library against mobile apps such as Google
Authenticator or Microsoft Authenticator without no problems
(I have tested myself too).

---

**Important**: The generated secret must be sent for the
client in a secure channel, such as **HTTPS/TLS**, and must
be stored encrypted in your servers' databases. A good
approach is to encrypt with a KDF on the client password,
after you checking the client password against the strongly
hashed version on database (prefer 512-bits hash algorithms
whenever possible, and a KDF in front of this with server's
salt is ideal too). So, in this approach the front app must
send the client password twice, during authentication and
during 2-step verification, and after that, erasing the
password persisted on front (nice UX for the client to not
type twice her own password).

This is a warning. Implement such system carefully, and if
possible, with audits from external experts and security
teams. As a disclaimer, I'm not responsible for any damages.

---

## Tips

For stronger/longer secrets, you can use the `~bytes` optional parameter
(the default and minimal value is 10,
_with the invariant that it must be divisible by 5_):

```ocaml
let secret: string = Twostep.TOTP.secret ~bytes:20 ();;
(* kinda "D3D3 F5F5 A2A2 3B3B GGGG 7K7K 5555 Q2Q2" *)
```

## Remarks

Pull requests are welcome! Happy hacking! Hope this project can
help you to solve problems.
