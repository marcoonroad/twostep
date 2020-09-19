module I = Twostep.Internals

let counters = [
  59L;
  1111111109L;
  1111111111L;
  1234567890L;
  2000000000L;
  20000000000L
]

let algorithms = [ "SHA-1"; "SHA-256"; "SHA-512" ]

let sha1_hex_secret = "3132333435363738393031323334353637383930"
let sha1_secret = Cstruct.to_string @@ Cstruct.of_hex sha1_hex_secret

let sha256_hex_secret = "3132333435363738393031323334353637383930" ^
         "313233343536373839303132"
let sha256_secret = Cstruct.to_string @@ Cstruct.of_hex sha256_hex_secret

let sha512_hex_secret = "3132333435363738393031323334353637383930" ^
         "3132333435363738393031323334353637383930" ^
         "3132333435363738393031323334353637383930" ^
         "31323334"
let sha512_secret = Cstruct.to_string @@ Cstruct.of_hex sha512_hex_secret

let counter_padding =
  counters
  |> Core.List.reduce_exn ~f:Core.Int64.max
  |> Core.Int64.to_string
  |> Core.String.length

let get_secret = function
| "SHA-1"   -> sha1_secret
| "SHA-256" -> sha256_secret
| "SHA-512" -> sha512_secret
| hash      -> failwith ("Unknown hash algorithm: " ^ hash)

let _ =
  Core.List.iter counters ~f:(function counter -> begin
    let text_counter = Core.Int64.to_string counter in
    let padded_counter =
      I.pad ~basis:counter_padding ~byte:' ' ~direction:I.padOnRight text_counter
    in
    let payload_counter = I.counter ~timestamp:(function () -> counter) () in
    let hex_counter =
      Core.String.uppercase @@ Hex.show @@ Hex.of_string payload_counter
    in
    Core.List.iter algorithms ~f:(function algorithm -> begin
      let secret = get_secret algorithm in
      let image = I.hmac ~hash:algorithm ~secret payload_counter in
      let code = I.truncate ~image ~digits:8 in
      print_endline (
        padded_counter ^ " | " ^ hex_counter ^ " | " ^ code ^ " | " ^ algorithm
      )
    end)
  end)
