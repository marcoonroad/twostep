(** HOTP and TOTP algorithms for 2-step verification (for OCaml).
    @author Marco Aurélio da Silva
    @version 1.0.0
*)

(**
  Pay attention that this library doesn't persist any HOTP counters neither tracks
  authenticated/verified valid OTP codes to protect against replay attacks. It's
  all up to you to build such defenses on top of this library with your underlying
  cloud-provided storage (NoSQL, relational databases, shared filesystems, etc).
*)

(** Module for TOTP algorithm. *)
module TOTP : sig
  (**
    This algorithm is useful on contexts of password managers, authenticator mobile
    applications or hardware vaults, that is, where the end-user has full control of
    OTP token generation.
  *)

  val secret : ?bytes:int -> unit -> string
  (**
    Generates a valid Base-32 OTP secret (for both HOTP and TOTP algorithms,
    but don't mix them with the same secret, instead, generate a secret for every kind of usage).
    The optional [bytes] parameter represents the size of underlying binary/blob string
    of the encoded Base-32 secret. Such parameter must be at least [10] and
    {i an integer divisible by 5}.
  *)

  val code :
       ?window:int
    -> ?drift:int
    -> ?digits:int
    -> ?hash:string
    -> secret:string
    -> unit
    -> string
  (**
    Generates an OTP token given valid Base-32 [secret]. The interval to expire the token is configured by
    the [window] optional parameter (defaults to [30] seconds). A clock [drift] of either positive or negative
    integers can be used when the server attempts to verify on past or future too. The [drift] parameter defaults
    to [0], non-zero values are used mostly for custom verification, but it's not recommended that use. Instead, rely
    on [TOTP.verify] operation, which attempts to verify with clock drifts [-1], [0] and [1] (30 seconds on past, now and
    30 seconds on future, assuming that [window] is [30] seconds). Remaining optional parameters [digits] and [hash] are
    used to configure the token size (defaults to [6] characters) and HMAC hash (defaults to ["SHA-1"], ["SHA-256"] and
    ["SHA-512"] are available too), respectively.
  *)

  val verify :
       ?window:int
    -> ?digits:int
    -> ?hash:string
    -> secret:string
    -> code:string
    -> unit
    -> bool
  (**
    Operation to verify TOTP codes. Optional parameters are [window]
    (how much seconds to expire the TOTP code/token, defaults to [30] seconds),
    [digits] (number of code/token characters, defaults to [6]) and [hash]
    (hash algorithm for internal HMAC, defaults to ["SHA-1"], other options are ["SHA-256"] and ["SHA-512"]).
    The required [secret] parameter must be a valid Base-32 string, under the same format of [TOTP.secret()]
    operation. Returns a boolean flag for authentication/proof ([true] for valid token, [false] for invalid one).
  *)
end

(** Module for HOTP algorithm. *)
module HOTP : sig
  (**
    This algorithm is useful on contexts of confirmation/authentication from other linked channels,
    for instance, email inbox messages or the discouraged SMS channel. In other words, where the
    server has full control of OTP token generation and sends it for the end-user through a trusted /
    linked third-party channel. {i Important note:} you must generate a different secret for
    every linked third-party channel. Also, you should limit the window for user authentication once
    the token / code is sent on a third-party channel, something like 5 or 10 minutes to expire regarding
    the third-party channel's delay to receive messages.
  *)

  val secret : ?bytes:int -> unit -> string
  (**
    Generates a valid Base-32 OTP secret (for both HOTP and TOTP algorithms,
    but don't mix them with the same secret, instead, generate a secret for every kind of usage).
    The optional [bytes] parameter represents the size of underlying binary/blob string
    of the encoded Base-32 secret. Such parameter must be at least [10] and
    {i an integer divisible by 5}.
  *)

  val codes :
       ?digits:int
    -> ?hash:string
    -> ?amount:int
    -> counter:int
    -> secret:string
    -> unit
    -> string list
  (**
    Generates a sequence of HOTP tokens/codes with length [amount] (defaults to [1]),
    where every code string has the size of optional parameter [digits] (defaults to [6]).
    The optional parameter [secret] must be a valid Base-32 string and [counter] is
    possibly retrieved from some storage. The default [hash] algorithm is ["SHA-1"], but
    the hashes ["SHA-256"] and ["SHA-512"] also work.
  *)

  val verify :
       ?digits:int
    -> ?hash:string
    -> ?ahead:int
    -> counter:int
    -> secret:string
    -> codes:string list
    -> unit
    -> bool * int
  (**
    Operation to verify a sequence of codes with optional
    look-[ahead] parameter (defaults to [0], a constraint for how much the server's counter can
    differ from client's counter, so it attempts to sync-in by incrementing the counter),
    [digits] of every HOTP string code
    (defaults to [6]) and underlying [hash] algorithm for internal HMAC (defaults to
    ["SHA-1"], values ["SHA-256"] and ["SHA-512"] are also accepted). The [secret] parameter
    must be a valid Base-32 secret. The [counter] is a nonce persisted on storage for given
    end-user. A non-empty list of [codes] provided by the client/end-user is a sequence generated
    with counters applied in an incremental way for every code.
    Returns a pair of verification status ([true] or [false]) and a resynchronized next counter to
    replace the current counter on storage (only if verification is successful with [true], otherwise
    the counter is not updated and returns the same counter of operation input).
  *)
end

(** DON'T USE THAT MODULE, PRONE TO BREAKING CHANGES AND LIKELY UNSAFE/UNSECURE! *)
module Internals : sig
  (** ARE YOU SURE? YOU HAVE BEEN WARNED... I'M NOT RESPONSIBLE BY ANY DAMAGES. *)

  val counter :
    ?timestep:int -> ?drift:int -> ?timestamp:(unit -> int64) -> unit -> string

  val hmac : hash:string -> secret:string -> string -> string

  val base32_to_string : ?size:int -> string -> string

  type padding = Helpers.padding

  val pad : basis:int -> direction:padding -> ?byte:char -> string -> string

  val padOnLeft : padding

  val padOnRight : padding

  val truncate : image:string -> digits:int -> string
end
