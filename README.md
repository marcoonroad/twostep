# twostep

HOTP and TOTP algorithms for 2-step verification (for OCaml).

<p>
<style>
a.badge-link {
  text-decoration: none;
}
a.badge-link:hover {
  text-decoration: none;
}
span.badge-separator {
  content: "";
  display: inline-block;
}
</style>
<a target="_blank" class="badge-link" href="https://github.com/marcoonroad/twostep/blob/stable/twostep.opam">
<img src="https://img.shields.io/static/v1?label=OCaml&message=%2Bv4.08.0&color=orange&style=flat-square&logo=ocaml" />
</a><span class="badge-separator"></span>
<a target="_blank" class="badge-link" href="https://github.com/marcoonroad/twostep/actions?query=workflow%3A%22Ubuntu+CI+Workflow%22+branch%3Astable">
<img alt="Ubuntu Workflow Status" src="https://img.shields.io/github/workflow/status/marcoonroad/twostep/Ubuntu%20CI%20Workflow/stable?label=Ubuntu&logo=github&style=flat-square" />
</a><span class="badge-separator"></span>
<a target="_blank" class="badge-link" href="https://github.com/marcoonroad/twostep/actions?query=workflow%3A%22Windows+CI+Workflow%22+branch%3Astable">
<img alt="Windows Workflow Status" src="https://img.shields.io/github/workflow/status/marcoonroad/twostep/Windows%20CI%20Workflow/stable?label=Windows&logo=github&style=flat-square" />
</a><span class="badge-separator"></span>
<a target="_blank" class="badge-link" href="https://github.com/marcoonroad/twostep/actions?query=workflow%3A%22MacOS+CI+Workflow%22+branch%3Astable">
<img alt="MacOS Workflow Status" src="https://img.shields.io/github/workflow/status/marcoonroad/twostep/MacOS%20CI%20Workflow/stable?label=MacOS&logo=github&style=flat-square" />
</a><span class="badge-separator"></span>
<a target="_blank" class="badge-link" href="https://github.com/marcoonroad/twostep/blob/stable/LICENSE">
<img alt="Project License" src="https://img.shields.io/github/license/marcoonroad/twostep?label=License&logo=github&style=flat-square" />
</a>
</p>

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
secret was sent before, you can generate this Base-32 secret
with:

```ocaml
let secret: string = Twostep.TOTP.secret();; (* kinda "A222 BBBB 3333 D5D5" *)
```

As an additional note, the `Twostep.TOTP.secret` function above uses
a cryptographically safe PRNG, that is, a secure source of pseudo
randomness. To generate an OTP code, you can use this function:

```ocaml
let code: string = Twostep.TOTP.code ~secret:secret ();; (* kinda "098123" *)
```

The function above assumes the `SHA-1` hash algorithm, `30` seconds
as timestep/window before refreshed code, `6` digits for output
number code (padded with zeros on left sometimes) and no clock
drifts / not-sync time between server and client (i.e, no
30 seconds on the past or on the future).

To verify one-time codes from the client, use the following
function below:

```ocaml
let valid: bool = Twostep.TOTP.verify ~secret:secret ~code:code ();;
```

This function assumes the same configuration of `Twostep.TOTP.code`,
except for the clock drift, where `Twostep.TOTP.verify` assumes too
past and future 30 seconds (ideal on slow connections or latency
problems). For the full API reference or coverage status, please refer to:
- [Generated API docs](https://www.marcoonroad.dev/twostep/apiref/twostep/Twostep/index.html)
- [Generated API coverage](https://www.marcoonroad.dev/twostep/apicov/index.html)

You can test this library against mobile apps such as Google
Authenticator or Microsoft Authenticator without any problems
(I have tested on both as well). On any doubts to generate
a QR-code for the base-32 secret, please refer to Google
Authenticator's Key Uri Format (for the proper data format
on QR-code encoding/decoding):
- [Key Uri Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)

## Security Concerns

The generated secret must be sent for the
client in a secure channel, such as **HTTPS/TLS**, and must
be stored encrypted in your servers' databases. A good
approach is to encrypt with a KDF on the client password,
after you checking the client password against the strongly
hashed version on database (prefer 256/512-bits hash algorithms
whenever possible, and a KDF in front of this with server's
salt is ideal too). So, in this approach the front app must
send the client password twice, during authentication and
during 2-step verification, and after that, erasing the
password persisted on front (nice UX for the client to not
type twice her own password).

It's recommended for the OTP authentication to be optional on
most cases. The end-user can opt-in this feature some time later,
and on OTP service setup, she needs to _confirm_ that have
configured things properly through the _first-time_ OTP-code
verification. For the first-time, which means no OTP-prompt-prior-login
until customer confirmation of first-time, you could use
a `confirmed` boolean (initially `false`) column aside
`encryptedSecret` on your storage -- so this first-time confirmation
changes `confirmed` to `true` and then all logins would request an
OTP code together. Keep in mind that it's just a design sketch of
implementation, more like an idea than actual RFC recommendation.

Also, you should track valid OTP codes sent from the end user in
a persisted storage (such as databases). This is just to avoid
**replay attacks** once an attacker intercepts a valid OTP code from
the end user. Your tracking of the OTP code should be a pair
`(otpCode, nonce)`, where `nonce` is the current interval / period
(if using TOTP algorithm, otherwise nonce will be a HOTP counter)
and the `otpCode` is verified / checked as valid. Keep in mind that
you should only track valid / verified OTP codes to not waste storage
costs with invalid OTP codes (i.e, codes that can't be exploited by
replay attacks). After such tracked pairs hit OTP expiration and are
not able to be exploited anymore, you can clean them from the
underlying tracklist storage without problems.

---

**Important:** This is a warning / security advice. Implement
such system carefully, and if possible, with audits from external
experts and security teams. As a disclaimer, I'm not responsible
for any damages.

---

## Tips

For stronger / longer secrets, you can use the `~bytes` optional parameter
(the default and minimal value is 10,
_with the invariant that it must be divisible-by / multiple-of 5_):

```ocaml
let secret: string = Twostep.TOTP.secret ~bytes:20 ();;
(* kinda "D3D3 F5F5 A2A2 3B3B GGGG 7K7K 5555 Q2Q2" *)
```

## Remarks

Pull requests are welcome! Happy hacking! Hope this project can
help you to solve problems.
