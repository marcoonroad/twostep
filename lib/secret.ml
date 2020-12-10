let __random_bytes bytes = Mirage_crypto_rng.generate bytes

let generate ~bytes () =
  if bytes >= 10 && bytes mod 5 == 0
  then Base32.string_to_base32 @@ Cstruct.to_string @@ __random_bytes bytes
  else
    failwith
      ( "Invalid amount of bytes ("
      ^ string_of_int bytes
      ^ ") for secret, it must be at least 10 and divisible by 5!" )


let _ = Mirage_crypto_rng_unix.initialize ()
