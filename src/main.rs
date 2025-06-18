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
    let mut right = vec![0; 2];
    let mut left = vec![0; 2];
    pad::minus(&mut b, &mut right, &mut left, l, (), (), ());
    println!("{:?} {:?} {:?}", b, right, left);
}