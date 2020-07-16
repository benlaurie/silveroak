(****************************************************************************)
(* Copyright 2020 The Project Oak Authors                                   *)
(*                                                                          *)
(* Licensed under the Apache License, Version 2.0 (the "License")           *)
(* you may not use this file except in compliance with the License.         *)
(* You may obtain a copy of the License at                                  *)
(*                                                                          *)
(*     http://www.apache.org/licenses/LICENSE-2.0                           *)
(*                                                                          *)
(* Unless required by applicable law or agreed to in writing, software      *)
(* distributed under the License is distributed on an "AS IS" BASIS,        *)
(* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *)
(* See the License for the specific language governing permissions and      *)
(* limitations under the License.                                           *)
(****************************************************************************)

From Coq Require Import Arith Eqdep_dec Vector Lia NArith Omega String Ndigits.
From Arrow Require Import Category Arrow.
From Cava Require Import Arrow.ArrowExport BitArithmetic.

From ArrowExamples Require Import Combinators Aes.pkg.

Import VectorNotations.
Import KappaNotation.
Open Scope kind_scope.

(* // Multiplication in GF(2^2), using normal basis [Omega^2, Omega] *)
(* // (see Figure 14 in the technical report) *)
(* function automatic logic [1:0] aes_mul_gf2p2(logic [1:0] g, logic [1:0] d); *)
(*   logic [1:0] f; *)
(*   logic       a, b, c; *)
(*   a    = g[1] & d[1]; *)
(*   b    = (^g) & (^d); *)
(*   c    = g[0] & d[0]; *)
(*   f[1] = a ^ b; *)
(*   f[0] = c ^ b; *)
(*   return f; *)
(* endfunction *)
Definition aes_mul_gf2p2
  : forall cava: Cava, << Vector Bit 2, Vector Bit 2, Unit >> ~> << Vector Bit 2 >> :=
<[ \g d =>
  let a = g[#1] && d[#1] in
  let b = |^g && |^ d in
  let c = g[#0] && d[#0] in
  xor c b :: xor a b :: []
]>.

Section regression_checks.
  Notation aes_mul_gf2p2_eval x y := 
    (bitvec_to_nat (evaluate aes_mul_gf2p2 (ltac:(combinational_obvious)) (N2Bv_sized 2 x, N2Bv_sized 2 y))).
  Notation aes_mul_gf2p2_test x y o := 
    (forall (wf: wf_combinational (aes_mul_gf2p2 _)), 
    evaluate aes_mul_gf2p2 wf (N2Bv_sized 2 x, N2Bv_sized 2 y) = N2Bv_sized 2 o).

  Goal aes_mul_gf2p2_test 0 0 0. auto. Qed.
  Goal aes_mul_gf2p2_test 0 1 0. auto. Qed.
  Goal aes_mul_gf2p2_test 2 0 0. auto. Qed.
  Compute aes_mul_gf2p2_eval 0 0.
  Compute aes_mul_gf2p2_eval 1 1.
  Compute aes_mul_gf2p2_eval 2 2.
  Compute aes_mul_gf2p2_eval 3 3.
End regression_checks.

(* // Scale by Omega^2 = N in GF(2^2), using normal basis [Omega^2, Omega] *)
(* // (see Figure 16 in the technical report) *)
(* function automatic logic [1:0] aes_scale_omega2_gf2p2(logic [1:0] g); *)
(*   logic [1:0] d; *)
(*   d[1] = g[0]; *)
(*   d[0] = g[1] ^ g[0]; *)
(*   return d; *)
(* endfunction *)
Definition aes_scale_omega2_gf2p2
  : forall cava: Cava, << Vector Bit 2, Unit >> ~> << Vector Bit 2 >> :=
<[ \g => xor g[#1] g[#0] :: g[#0] :: [] ]>.

Section regression_checks.
  Notation aes_scale_omega2_gf2p2_eval x := 
    (bitvec_to_nat (evaluate aes_scale_omega2_gf2p2 (ltac:(combinational_obvious)) (N2Bv_sized 2 x))).
  Notation aes_scale_omega2_gf2p2_test x o := 
    (forall (wf: wf_combinational (aes_scale_omega2_gf2p2 _)), 
    evaluate aes_scale_omega2_gf2p2 wf (N2Bv_sized 2 x) = N2Bv_sized 2 o).

  Goal aes_scale_omega2_gf2p2_test 0 0. auto. Qed.
  Goal aes_scale_omega2_gf2p2_test 1 3. auto. Qed.
  Compute aes_scale_omega2_gf2p2_eval 0.
End regression_checks.

(* // Scale by Omega = N^2 in GF(2^2), using normal basis [Omega^2, Omega] *)
(* // (see Figure 15 in the technical report) *)
(* function automatic logic [1:0] aes_scale_omega_gf2p2(logic [1:0] g); *)
(*   logic [1:0] d; *)
(*   d[1] = g[1] ^ g[0]; *)
(*   d[0] = g[1]; *)
(*   return d; *)
(* endfunction *)
Definition aes_scale_omega_gf2p2
  : forall cava: Cava, << Vector Bit 2, Unit >> ~> << Vector Bit 2 >> :=
<[ \g => g[#1] :: xor g[#1] g[#0] :: [] ]>.

(* // Square in GF(2^2), using normal basis [Omega^2, Omega] *)
(* // (see Figures 8 and 10 in the technical report) *)
(* function automatic logic [1:0] aes_square_gf2p2(logic [1:0] g); *)
(*   logic [1:0] d; *)
(*   d[1] = g[0]; *)
(*   d[0] = g[1]; *)
(*   return d; *)
(* endfunction *)
Definition aes_square_gf2p2
  : forall cava: Cava, << Vector Bit 2, Unit >> ~> << Vector Bit 2>> :=
<[ \g => g[#1] :: g[#0] :: [] ]>.

(* // Multiplication in GF(2^4), using normal basis [alpha^8, alpha^2] *)
(* // (see Figure 13 in the technical report) *)
(* function automatic logic [3:0] aes_mul_gf2p4(logic [3:0] gamma, logic [3:0] delta); *)
(*   logic [3:0] theta; *)
(*   logic [1:0] a, b, c; *)
(*   a          = aes_mul_gf2p2(gamma[3:2], delta[3:2]); *)
(*   b          = aes_mul_gf2p2(gamma[3:2] ^ gamma[1:0], delta[3:2] ^ delta[1:0]); *)
(*   c          = aes_mul_gf2p2(gamma[1:0], delta[1:0]); *)
(*   theta[3:2] = a ^ aes_scale_omega2_gf2p2(b); *)
(*   theta[1:0] = c ^ aes_scale_omega2_gf2p2(b); *)
(*   return theta; *)
(* endfunction *)
Program Definition aes_mul_gf2p4
  : forall cava: Cava, << Vector Bit 4, Vector Bit 4, Unit >> ~> << Vector Bit 4>> :=
<[ \gamma delta =>
  let a = !aes_mul_gf2p2 (gamma[:3:2]) (delta[:3:2]) in
  let b = !aes_mul_gf2p2 (gamma[:3:2] ^ gamma[:1:0]) (delta[:3:2] ^ delta[:1:0]) in
  let c = !aes_mul_gf2p2 (gamma[:1:0]) (delta[:1:0]) in
  concat
    (c ^ !aes_scale_omega2_gf2p2 b)
    (a ^ !aes_scale_omega2_gf2p2 b)
]>.

(* // Square and scale by nu in GF(2^4)/GF(2^2), using normal basis [alpha^8, alpha^2] *)
(* // (see Figure 19 as well as Appendix A of the technical report) *)
(* function automatic logic [3:0] aes_square_scale_gf2p4_gf2p2(logic [3:0] gamma); *)
(*   logic [3:0] delta; *)
(*   logic [1:0] a, b; *)
(*   a          = gamma[3:2] ^ gamma[1:0]; *)
(*   b          = aes_square_gf2p2(gamma[1:0]); *)
(*   delta[3:2] = aes_square_gf2p2(a); *)
(*   delta[1:0] = aes_scale_omega_gf2p2(b); *)
(*   return delta; *)
(* endfunction *)
Program Definition aes_square_scale_gf2p4_gf2p2
  : forall cava: Cava, << Vector Bit 4, Unit >> ~> << Vector Bit 4>> :=
<[ \gamma =>
    let a = gamma[:3:2] ^ gamma[:1:0] in
    let b = !aes_square_gf2p2 (gamma[:1:0]) in
    concat
      (!aes_scale_omega_gf2p2 b)
      (!aes_square_gf2p2 a)
]>.

(* // Basis conversion matrices to convert between polynomial basis A, normal basis X *)
(* // and basis S incorporating the bit matrix of the SBox. More specifically, *)
(* // multiplication by X2X performs the transformation from normal basis X into *)
(* // polynomial basis A, followed by the affine transformation (substep 2). Likewise, *)
(* // multiplication by S2X performs the inverse affine transformation followed by the *)
(* // transformation from polynomial basis A to normal basis X. *)
(* // (see Appendix A of the technical report) *)
(* parameter logic [7:0] A2X [8] = '{8'h98, 8'hf3, 8'hf2, 8'h48, 8'h09, 8'h81, 8'ha9, 8'hff}; *)
Definition A2X : forall cava: Cava, Unit ~> (Vector (Vector Bit 8) 8) :=
  <[ #255 (* = Byte.xff, coq doesn't have hex literals? *)
  :: #169 (* 0xa9 *)
  :: #129 (* 0x81 *)
  :: #  9 (* 0x09 *)
  :: # 72 (* 0x48 *)
  :: #242 (* 0xf2 *)
  :: #243 (* 0xf3 *)
  :: #152 (* 0x98 *)
  :: [] ]>.

(* parameter logic [7:0] X2A [8] = '{8'h64, 8'h78, 8'h6e, 8'h8c, 8'h68, 8'h29, 8'hde, 8'h60}; *)
Definition X2A : forall cava: Cava, Unit ~> (Vector (Vector Bit 8) 8) :=
  <[ #  6 (* 0x06 *)
  :: #222 (* 0xde *)
  :: # 41 (* 0x29 *)
  :: #104 (* 0x68 *)
  :: #140 (* 0x8c *)
  :: #110 (* 0x6e *)
  :: #120 (* 0x78 *)
  :: #100 (* 0x64 *)
  :: [] ]>.

(* parameter logic [7:0] X2S [8] = '{8'h58, 8'h2d, 8'h9e, 8'h0b, 8'hdc, 8'h04, 8'h03, 8'h24}; *)
Definition X2S : forall cava: Cava, Unit ~> (Vector (Vector Bit 8) 8) :=
  <[ # 36 (* 0x24 *)
  :: #  3 (* 0x03 *)
  :: #  4 (* 0x04 *)
  :: #220 (* 0xdc *)
  :: # 11 (* 0x0b *)
  :: #158 (* 0x9e *)
  :: # 45 (* 0x2d *)
  :: # 88 (* 0x58 *)
  :: [] ]>.

(* parameter logic [7:0] S2X [8] = '{8'h8c, 8'h79, 8'h05, 8'heb, 8'h12, 8'h04, 8'h51, 8'h53}; *)
Definition S2X : forall cava: Cava, Unit ~> (Vector (Vector Bit 8) 8) :=
  <[ # 83 (* 0x53 *)
  :: # 81 (* 0x51 *)
  :: #  4 (* 0x04 *)
  :: # 18 (* 0x12 *)
  :: #235 (* 0xeb *)
  :: #  5 (* 0x05 *)
  :: #121 (* 0x79 *)
  :: #140 (* 0x8c *)
  :: []
  ]>.

Section regression_checks.
  Definition S2X_indexer: forall cava:Cava, <<Vector Bit 3, Unit>> ~> <<Vector Bit 8>> := 
    <[\x => let vec = !S2X in vec[x] ]>.
  Goal
    (forall wf: wf_combinational (S2X_indexer _), 
      evaluate S2X_indexer wf (N2Bv_sized 3 2) = N2Bv_sized 8 4). 
    auto. Qed.
  Goal
    (forall wf: wf_combinational (S2X_indexer _), 
      evaluate S2X_indexer wf (N2Bv_sized 3 4) = N2Bv_sized 8 235). 
    auto. Qed.
End regression_checks.