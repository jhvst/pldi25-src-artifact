let iota = Lang.iota (Z.of_int 4)
let rivi () = Z.to_int (snd iota)
let () = Callback.register "rivi" rivi