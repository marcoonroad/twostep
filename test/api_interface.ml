open Alcotest
module String = Base.String
module TOTP = Twostep.TOTP
module HOTP = Twostep.HOTP

let _drop_spaces text = String.filter ~f:(( != ) ' ') text

let _char_is_base32 char =
  char == 'A'
  || char == 'B'
  || char == 'C'
  || char == 'D'
  || char == 'E'
  || char == 'F'
  || char == 'G'
  || char == 'H'
  || char == 'I'
  || char == 'J'
  || char == 'K'
  || char == 'L'
  || char == 'M'
  || char == 'N'
  || char == 'O'
  || char == 'P'
  || char == 'Q'
  || char == 'R'
  || char == 'S'
  || char == 'T'
  || char == 'U'
  || char == 'V'
  || char == 'W'
  || char == 'X'
  || char == 'Y'
  || char == 'Z'
  || char == '2'
  || char == '3'
  || char == '4'
  || char == '5'
  || char == '6'
  || char == '7'


let _is_base32 data = String.for_all ~f:_char_is_base32 @@ _drop_spaces data

let _char_is_integer char =
  char == '0'
  || char == '1'
  || char == '2'
  || char == '3'
  || char == '4'
  || char == '5'
  || char == '6'
  || char == '7'
  || char == '8'
  || char == '9'


let _is_integer data = String.for_all ~f:_char_is_integer data

let __length_case () =
  let secret = TOTP.secret () in
  let no_spaces = _drop_spaces secret in
  let codeA = TOTP.code ~secret () in
  let codeB = TOTP.code ~secret ~digits:6 () in
  let codeC = TOTP.code ~secret ~digits:8 () in
  check int "secret w/ spaces must have 19 chars" (String.length secret) 19 ;
  check int "secret must contain 16 characters" (String.length no_spaces) 16 ;
  check int "code length must be 6 w/ default params" (String.length codeA) 6 ;
  check int "code length must be 6 w/ param digits=6" (String.length codeB) 6 ;
  check int "code length must be 8 w/ param digits=8" (String.length codeC) 8


let __format_case () =
  let secret = TOTP.secret () in
  let code6 = TOTP.code ~secret ~digits:6 () in
  let code8 = TOTP.code ~secret ~digits:8 () in
  check bool "secret must be under base-32" true @@ _is_base32 secret ;
  check bool "otp code w/ digits=6 must be int" true @@ _is_integer code6 ;
  check bool "otp code w/ digits=8 must be int" true @@ _is_integer code8 ;
  let procedure () = ignore @@ TOTP.code ~hash:"SHA-0" ~secret () in
  let failure = Failure "Invalid hash algorithm: SHA-0" in
  check_raises "otp code fails if hash is invalid" failure procedure ;
  let procedure () = ignore @@ TOTP.code ~secret:"ABCD E9FG H123 4567" () in
  let failure = Failure "Invalid base32 character: 9" in
  check_raises "otp code fails if secret is invalid" failure procedure ;
  ignore @@ TOTP.code ~secret:"ABCD EFGH IJKL MNOP" () ;
  ignore @@ TOTP.code ~secret:"QRST UVWX YZ23 4567" ()


let __secret_case () =
  let secret16 = _drop_spaces @@ TOTP.secret () in
  let secret24 = _drop_spaces @@ TOTP.secret ~bytes:15 () in
  let secret32 = _drop_spaces @@ TOTP.secret ~bytes:20 () in
  check
    int
    "10-bytes secret must contain 16 characters"
    (String.length secret16)
    16 ;
  check
    int
    "15-bytes secret must contain 24 characters"
    (String.length secret24)
    24 ;
  check
    int
    "20-bytes secret must contain 32 characters"
    (String.length secret32)
    32 ;
  let procedure bytes () = ignore @@ TOTP.secret ~bytes () in
  let failureA =
    Failure
      "Invalid amount of bytes (8) for secret, it must be at least 10 and \
       divisible by 5!"
  in
  let failureB =
    Failure
      "Invalid amount of bytes (12) for secret, it must be at least 10 and \
       divisible by 5!"
  in
  let failureC =
    Failure
      "Invalid amount of bytes (19) for secret, it must be at least 10 and \
       divisible by 5!"
  in
  check_raises "secret generation should fail when bytes = 8" failureA
  @@ procedure 8 ;
  check_raises "secret generation should fail when bytes = 12" failureB
  @@ procedure 12 ;
  check_raises "secret generation should fail when bytes = 19" failureC
  @@ procedure 19


let __verification_failure_case () =
  let secretA = TOTP.secret () in
  let secretB = TOTP.secret () in
  (****************************************************************************)
  let codeA0 = TOTP.code ~secret:secretA ~drift:(-3) () in
  let codeB0 = TOTP.code ~secret:secretB ~drift:(-3) () in
  let resultA0 = TOTP.verify ~secret:secretA ~code:codeA0 () in
  let resultB0 = TOTP.verify ~secret:secretB ~code:codeB0 () in
  let result0 = resultA0 || resultB0 in
  check bool "should not authenticate with codes too old" false result0 ;
  (****************************************************************************)
  let codeA1 = TOTP.code ~secret:secretA ~drift:3 () in
  let codeB1 = TOTP.code ~secret:secretB ~drift:3 () in
  let resultA1 = TOTP.verify ~secret:secretA ~code:codeA1 () in
  let resultB1 = TOTP.verify ~secret:secretB ~code:codeB1 () in
  let result1 = resultA1 || resultB1 in
  check bool "shouldn't pass codes on future" false result1 ;
  (****************************************************************************)
  let codeA = TOTP.code ~secret:secretA () in
  let codeB = TOTP.code ~secret:secretB () in
  let resultA = TOTP.verify ~secret:secretA ~code:codeB () in
  let resultB = TOTP.verify ~secret:secretB ~code:codeA () in
  let result = resultA || resultB in
  check bool "shouldn't pass codes from different secrets" false result


let __verification_success_case () =
  let secret = TOTP.secret () in
  let code1 = TOTP.code ~secret ~drift:(-1) () in
  let code2 = TOTP.code ~secret ~drift:0 () in
  let code3 = TOTP.code ~secret ~drift:1 () in
  let result1 = TOTP.verify ~secret ~code:code1 () in
  let result2 = TOTP.verify ~secret ~code:code2 () in
  let result3 = TOTP.verify ~secret ~code:code3 () in
  let result = result1 && result2 && result3 in
  check bool "should authenticate with valid otp codes" true result


let __hotp_resynch_case () =
  let secret = HOTP.secret () in
  let codes = HOTP.codes ~counter:0 ~secret () in
  let codes' = HOTP.codes ~counter:0 ~secret () in
  check (list string) "hotp code generation is deterministic" codes codes' ;
  let result = HOTP.verify ~counter:0 ~secret ~codes () in
  check bool "should pass verification flag with true" true @@ fst result ;
  check int "should increment counter as next one" 1 @@ snd result ;
  let secret = HOTP.secret ~bytes:15 () in
  let result = HOTP.verify ~counter:0 ~secret ~codes () in
  check bool "should fail verification flag with false" false @@ fst result ;
  check int "should not increment counter on failure" 0 @@ snd result ;
  let codes = HOTP.codes ~counter:7 ~amount:3 ~secret () in
  let result = HOTP.verify ~counter:4 ~ahead:6 ~secret ~codes () in
  check bool "should pass verification flag with true" true @@ fst result ;
  check int "should increment counter as next one" 10 @@ snd result ;
  let result = HOTP.verify ~counter:2 ~ahead:4 ~secret ~codes () in
  check bool "should fail verification flag with false" false @@ fst result ;
  check int "should not increment counter on failure" 2 @@ snd result


let suite =
  [ ("secret and otp code length", `Quick, __length_case)
  ; ("secret-only length for custom bytes", `Quick, __secret_case)
  ; ("secret and otp code format", `Quick, __format_case)
  ; ("otp code verification failure", `Quick, __verification_failure_case)
  ; ("otp code verification success", `Quick, __verification_success_case)
  ; ("hotp counter resynchronization", `Quick, __hotp_resynch_case)
  ]


let () =
  Mirage_crypto_rng_unix.initialize (module Mirage_crypto_rng.Fortuna) ;
  run "Twostep tests" [ ("test suite", suite) ]
