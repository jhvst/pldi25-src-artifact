open Prims
type pos = Prims.nat
type dim = (pos * pos)
let (rank : dim -> Prims.int) =
  fun d ->
    if (FStar_Pervasives_Native.fst d) > Prims.int_one
    then (Prims.of_int (2))
    else
      if (FStar_Pervasives_Native.snd d) > Prims.int_one
      then Prims.int_one
      else Prims.int_zero
let (scalar : dim) = (Prims.int_one, Prims.int_one)
let (vector : pos -> dim) = fun stride -> (Prims.int_one, stride)
let (matrix : pos -> pos -> dim) = fun rows -> fun stride -> (rows, stride)
let (iota : pos -> dim) = fun len -> vector len