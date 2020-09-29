open Alcotest
module String = Base.String
module TOTP = Twostep.TOTP

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
  check bool "otp code w/ digits=8 must be int" true @@ _is_integer code8


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


let suite =
  [ ("secret and otp code length", `Quick, __length_case)
  ; ("secret and otp code format", `Quick, __format_case)
  ; ("otp code verification failure", `Quick, __verification_failure_case)
  ; ("otp code verification success", `Quick, __verification_success_case)
  ]


let () = run "Twostep tests" [ ("test suite", suite) ]
