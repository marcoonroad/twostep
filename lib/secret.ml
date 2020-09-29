module RngZ = Nocrypto.Rng.Z
module NumZ = Nocrypto.Numeric.Z

let __gen_min bits = "1" ^ Base.String.init (bits - 1) ~f:(function _ -> '0')

let __gen_max bits = Base.String.init bits ~f:(function _ -> '1')

let __max_bits bits = Z.of_string_base 2 @@ __gen_max bits

let __min_bits bits = Z.of_string_base 2 @@ __gen_min bits

let __random_bits bits =
  let _min_random = __min_bits bits in
  let _max_random = __max_bits bits in
  NumZ.to_cstruct_be @@ RngZ.gen_r _min_random _max_random


let generate () =
  Base32.string_to_base32 @@ Cstruct.to_string @@ __random_bits 80


let _ = Nocrypto_entropy_unix.initialize ()
