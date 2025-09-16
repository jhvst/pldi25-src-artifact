mod pad;

ocaml::import! {
    fn rivi() -> ocaml::Int
}

fn main() {
    let gc = ocaml::runtime::init();
    unsafe {
        println!("rivi: {}", rivi(&gc).unwrap());
    }
    let mut a = vec![3, 4, 2, 2, 3, 3];
    let mut b = vec![4, 3, 5, 3, 9, 3];
    let l = a.len();
    pad::minus((), (), &mut a, &mut b, l);
    println!("{:?} {:?}", a, b);
}
