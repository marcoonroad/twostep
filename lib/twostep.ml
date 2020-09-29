module Internals = struct
  let counter = Time.counter

  let hmac = Hmac.hmac

  let base32_to_string = Base32.base32_to_string

  type padding = Helpers.padding
  let pad = Helpers.pad
  let padOnLeft = Helpers.padOnLeft
  let padOnRight = Helpers.padOnRight

  let truncate ~image ~digits =
    let bytes = Base.List.map ~f:Base.Char.to_int @@ Base.String.to_list image in
    let offset = Base.List.nth_exn bytes (Base.List.length bytes - 1) land 0xf in
    let fst = (Base.List.nth_exn bytes (offset + 0) land 0x7f) lsl 24 in
    let snd = (Base.List.nth_exn bytes (offset + 1) land 0xff) lsl 16 in
    let trd = (Base.List.nth_exn bytes (offset + 2) land 0xff) lsl 8  in
    let fth = (Base.List.nth_exn bytes (offset + 3) land 0xff) lsl 0  in
    let num = (fst lor snd lor trd lor fth) mod (Base.Int.pow 10 digits) in
    Helpers.pad ~basis:digits ~byte:'0' ~direction:Helpers.OnLeft @@ Base.Int.to_string num
end

let secret () = Secret.generate()

let code ?(window=30) ?(drift=0) ?(digits=6) ?(hash="SHA-1") ~secret () =
  assert (digits = 6 || digits = 8);
  let decoded = Base32.base32_to_string secret in
  let counter = Time.counter ~timestep:window ~drift () in
  let image = Hmac.hmac ~hash ~secret:decoded counter in
  Internals.truncate ~image ~digits

let verify ?(window=30) ?(digits=6) ?(hash="SHA-1") ~secret ~code:number () =
  number = code ~secret ~window ~digits ~hash ~drift:(-1) () ||
  number = code ~secret ~window ~digits ~hash ~drift:0 () ||
  number = code ~secret ~window ~digits ~hash ~drift:1 ()
