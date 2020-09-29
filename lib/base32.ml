let base32_alphabet = [
  "a"; "b"; "c"; "d"; "e"; "f"; "g"; "h"; "i"; "j"; "k"; "l"; "m";
  "n"; "o"; "p"; "q"; "r"; "s"; "t"; "u"; "v"; "w"; "x"; "y"; "z";
  "2"; "3"; "4"; "5"; "6"; "7";
]

let reverse_base32_alphabet = function
  | 'a' -> 0 | 'g' ->  6 | 'm' -> 12 | 's' -> 18 | 'y' -> 24 | '6' -> 30
  | 'b' -> 1 | 'h' ->  7 | 'n' -> 13 | 't' -> 19 | 'z' -> 25 | '7' -> 31
  | 'c' -> 2 | 'i' ->  8 | 'o' -> 14 | 'u' -> 20 | '2' -> 26
  | 'd' -> 3 | 'j' ->  9 | 'p' -> 15 | 'v' -> 21 | '3' -> 27
  | 'e' -> 4 | 'k' -> 10 | 'q' -> 16 | 'w' -> 22 | '4' -> 28
  | 'f' -> 5 | 'l' -> 11 | 'r' -> 17 | 'x' -> 23 | '5' -> 29
  | wat -> failwith ("Invalid base32 character: " ^ Base.String.of_char wat)

let rec enc_loop data ~basis ~alphabet number =
  if number <= 0 then data else
    let remainder = number mod basis in
    let result    = number / basis in
    let digit     = List.nth alphabet remainder in
    enc_loop (digit ^ data) ~basis ~alphabet result

let int_to_base_x ?(basis=32) ?(alphabet=base32_alphabet) number =
  if number < basis then
    List.nth alphabet number
  else
    enc_loop "" ~basis ~alphabet number

let base32_to_string ?(size=10) base32 =
  base32
  |> Base.String.lowercase
  |> Base.String.to_list
  |> Base.List.filter ~f:((!=) ' ')
  |> Base.List.map ~f:reverse_base32_alphabet
  |> Base.List.map ~f:(int_to_base_x ~basis:2 ~alphabet:["0"; "1";])
  |> Base.List.map ~f:(Helpers.pad ~basis:5 ~direction:Helpers.OnLeft ~byte:'0')
  |> Base.List.reduce_exn ~f:(^)
  |> Z.of_string_base 2
  |> Nocrypto.Numeric.Z.to_cstruct_be ~size
  |> Cstruct.to_string

let char_to_bits char =
  char
  |> Base.Char.to_int
  |> int_to_base_x ~basis:2 ~alphabet:["0"; "1";]
  |> Helpers.pad ~basis:8 ~direction:Helpers.OnLeft ~byte:'0'

let bits_to_int bits =
  Z.to_int @@ Z.of_string_base 2 bits

let extract_to_base32 ~pos ~len bits =
  bits
  |> Base.String.sub ~pos ~len
  |> bits_to_int
  |> Base.List.nth_exn base32_alphabet

let bits_to_base32 bits =
  let len = 5 in
  let c1 = extract_to_base32 ~pos:0  ~len bits in
  let c2 = extract_to_base32 ~pos:5  ~len bits in
  let c3 = extract_to_base32 ~pos:10 ~len bits in
  let c4 = extract_to_base32 ~pos:15 ~len bits in
  let c5 = extract_to_base32 ~pos:20 ~len bits in
  let c6 = extract_to_base32 ~pos:25 ~len bits in
  let c7 = extract_to_base32 ~pos:30 ~len bits in
  let c8 = extract_to_base32 ~pos:35 ~len bits in
  c1 ^ c2 ^ c3 ^ c4 ^ " " ^ c5 ^ c6 ^ c7 ^ c8

let rec conv_loop ~idx ~max ~add buffer list =
  if idx >= max then buffer else
  let fst = char_to_bits @@ Base.List.nth_exn list (idx + 0) in
  let snd = char_to_bits @@ Base.List.nth_exn list (idx + 1) in
  let trd = char_to_bits @@ Base.List.nth_exn list (idx + 2) in
  let fth = char_to_bits @@ Base.List.nth_exn list (idx + 3) in
  let fft = char_to_bits @@ Base.List.nth_exn list (idx + 4) in
  let res = bits_to_base32 (fst ^ snd ^ trd ^ fth ^ fft) in
  conv_loop ~idx:(idx + add) ~max ~add (res :: buffer) list

let concat_with_space left right = left ^ " " ^ right

let string_to_base32 data =
  let padded = Helpers.pad ~basis:5 ~direction:Helpers.OnLeft data in
  let length = String.length padded in
  let chars  = Base.String.to_list padded in
  let pieces = conv_loop ~idx:0 ~max:length ~add:5 [] chars in
  pieces
  |> Base.List.rev
  |> Base.List.reduce_exn ~f:concat_with_space
  |> Base.String.uppercase

