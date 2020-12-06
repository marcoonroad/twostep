module I = Twostep.Internals

let counters = [ 0L; 1L; 2L; 3L; 4L; 5L; 6L; 7L; 8L; 9L ]

let algorithms = [ "SHA-1" ]

let sha1_hex_secret = "3132333435363738393031323334353637383930"

let sha1_secret = Cstruct.to_string @@ Cstruct.of_hex sha1_hex_secret

let counter_padding =
  counters
  |> Base.List.reduce_exn ~f:Base.Int64.max
  |> Base.Int64.to_string
  |> Base.String.length


let get_secret = function
  | "SHA-1" ->
      sha1_secret
  | hash ->
      failwith ("Unknown hash algorithm: " ^ hash)


let _ =
  Base.List.iter counters ~f:(function counter ->
      let text_counter = Base.Int64.to_string counter in
      let padded_counter =
        I.pad
          ~basis:counter_padding
          ~byte:' '
          ~direction:I.padOnRight
          text_counter
      in
      let payload_counter =
        I.counter ~timestep:1 ~timestamp:(function () -> counter) ()
      in
      Base.List.iter algorithms ~f:(function algorithm ->
          let secret = get_secret algorithm in
          let image = I.hmac ~hash:algorithm ~secret payload_counter in
          let code = I.truncate ~image ~digits:6 in
          print_endline (padded_counter ^ " | " ^ code))) ;
  print_endline "----------" ;
  print_endline
    ( "? | "
    ^ I.truncate
        ~digits:6
        ~image:(Hex.to_string @@ `Hex "1f8698690e02ca16618550ef7f19da8e945b555a")
    )
