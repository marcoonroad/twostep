module S1 = Digestif.SHA1
module S2 = Digestif.SHA256
module S5 = Digestif.SHA512

let hmac_sha1 ~secret payload =
  S1.to_raw_string @@ S1.hmac_string ~key:secret payload

let hmac_sha256 ~secret payload =
  S2.to_raw_string @@ S2.hmac_string ~key:secret payload

let hmac_sha512 ~secret payload =
  S5.to_raw_string @@ S5.hmac_string ~key:secret payload

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

