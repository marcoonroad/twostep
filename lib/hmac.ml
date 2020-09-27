module S1 = Nocrypto.Hash.SHA1
module S2 = Nocrypto.Hash.SHA256
module S5 = Nocrypto.Hash.SHA512

let of_string = Cstruct.of_string
let to_string = Cstruct.to_string

let hmac_sha1 ~secret payload =
  to_string @@ S1.hmac ~key:(of_string secret) @@ of_string payload

let hmac_sha256 ~secret payload =
  to_string @@ S2.hmac ~key:(of_string secret) @@ of_string payload

let hmac_sha512 ~secret payload =
  to_string @@ S5.hmac ~key:(of_string secret) @@ of_string payload

let no_trace char = char != '-'

let hmac ~hash =
  let algorithm =
    hash
    |> Core.String.lowercase
    |> Core.String.to_list
    |> Core.List.filter ~f:no_trace
    |> Core.String.of_char_list
  in
  match algorithm with
  | "sha1"   -> hmac_sha1
  | "sha256" -> hmac_sha256
  | "sha512" -> hmac_sha512
  | _        -> failwith ("Invalid hash algorithm: " ^ hash)
