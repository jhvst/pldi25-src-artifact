module Pad

#lang-pulse
open FStar.Seq
open FStar.SizeT
open Pulse.Lib.Pervasives
open Pulse.Lib.Reference
open Pulse.Lib.BoundedIntegers

module V = Pulse.Lib.Vec
module A = Pulse.Lib.Array
module R = Pulse.Lib.Reference
module SZ = FStar.SizeT
module AS = Pulse.Lib.Slice
module Swap = Pulse.Lib.Swap.Slice
module AP = Pulse.Lib.ArrayPtr

fn minus
(#s1: erased (Seq.seq int))
(#s2: erased (Seq.seq int))
(a1: array int)
(a2: array int)
(l: SZ.t { SZ.v l == Seq.length s2 /\ Seq.length s1 == Seq.length s2})
  requires (
    A.pts_to a1 s1 **
    A.pts_to a2 s2
  )
  ensures (
    (exists* s. A.pts_to a1 s) **
    A.pts_to a2 s2
  )
{
  let mut i = 0sz;
  while (
    let vi = !i;
    (vi < l)
  )
  invariant b.
  A.pts_to a2 s2 **
  (exists* vi s. (
    R.pts_to i vi **
    A.pts_to a1 s **
    pure (
      Seq.length s == Seq.length s2 /\
      SZ.v vi <= SZ.v l /\
      (b == (vi <^ l))
    )
  ))
  {
    let vi = !i;
    let src = a2.(vi);
    let dst = a1.(vi);
    a1.(vi) <- (src - dst);
    i := vi +^ 1sz
  }
}