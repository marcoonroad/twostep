let __unix_time () = Core.Int64.of_float @@ Core.Float.round_down @@ Unix.time()

let counter ?(timestep=30) ?(drift=0) ?(timestamp=__unix_time) () =
  let now = timestamp () in
  let add = Core.Int64.of_int drift in
  let ctr = Core.Int64.(+) add @@ Core.Int64.(/) now @@ Core.Int64.of_int timestep in
  Cstruct.to_string @@ Nocrypto.Numeric.Z.to_cstruct_be ~size:8 @@ Z.of_int64 ctr
