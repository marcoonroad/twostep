let __unix_time () =
  Base.Int64.of_float @@ Base.Float.round_down @@ Unix.time ()


let counter ?(timestep = 30) ?(drift = 0) ?(timestamp = __unix_time) () =
  let now = timestamp () in
  let add = Base.Int64.of_int drift in
  let ctr =
    Base.Int64.( + ) add @@ Base.Int64.( / ) now @@ Base.Int64.of_int timestep
  in
  Cstruct.to_string
  @@ Mirage_crypto_pk.Z_extra.to_cstruct_be ~size:8
  @@ Z.of_int64 ctr
