(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Protocol

(** Some global constants. *)

val genesis_history : Dal_slot_repr.Slots_history.t

val genesis_history_cache : Dal_slot_repr.Slots_history.History_cache.t

val level_one : Raw_level_repr.t

val level_ten : Raw_level_repr.t

(** Helper functions. *)

(** Returns an object of type {!Cryptobox.t} from the given DAL paramters. *)
val dal_mk_env : Cryptobox.parameters -> (Cryptobox.t, error trace) result

(** Returns the slot's polynomial from the given slot's data. *)
val dal_mk_polynomial_from_slot :
  Cryptobox.t -> bytes -> (Cryptobox.polynomial, error trace) result

(** Using the given slot's polynomial, this function computes the page proof of
   the page whose ID is provided.  *)
val dal_mk_prove_page :
  Cryptobox.t ->
  Cryptobox.polynomial ->
  Dal_slot_repr.Page.t ->
  (Cryptobox.page_proof, error trace) result

(** Constructs a slot whose ID is defined from the given level and given index,
   and whose data are built using the given fill function. The function returns
   the slot's data, polynomial, and header (in the sense: ID + kate
   commitment). *)
val mk_slot :
  ?level:Raw_level_repr.t ->
  ?index:Dal_slot_repr.slot_index ->
  ?fill_function:(int -> char) ->
  Cryptobox.t ->
  (bytes * Cryptobox.polynomial * Dal_slot_repr.t, error trace) result

(** Constructs a record value of type Page.id. *)
val mk_page_id :
  Raw_level_repr.t -> Dal_slot_repr.slot_index -> int -> Dal_slot_repr.Page.t

val no_data : (default_char:char -> int -> bytes option) option

(** Constructs a page whose level and slot indexes are those of the given slot
   (except if level is redefined via [?level]), and whose page index and data
   are given by arguments [page_index] and [mk_data]. If [mk_data] is set to [No],
   the function returns the pair (None, page_id). Otherwise, the page's [data]
   and [proof] is computed, and the function returns [Some (data, proof),
   page_id]. *)
val mk_page_info :
  ?default_char:char ->
  ?level:Raw_level_repr.t ->
  ?page_index:int ->
  ?custom_data:(default_char:char -> int -> bytes option) option ->
  Cryptobox.t ->
  Dal_slot_repr.t ->
  Cryptobox.polynomial ->
  ( (bytes * Cryptobox.page_proof) option * Dal_slot_repr.Page.t,
    error trace )
  result

(** Returns the char after [c]. Restarts from the char whose code is 0 if [c]'s
   code is 255. *)
val next_char : char -> char

(** Increment the given slot index. Returns zero in case of overflow. *)
val succ_slot_index : Dal_slot_repr.slot_index -> Dal_slot_repr.slot_index

(** Auxiliary test function used by both unit and PBT tests: This function
   produces a proof from the given information and verifies the produced result,
   if any. The result of each step is checked with [check_produce_result] and
    [check_verify_result], respectively. *)
val produce_and_verify_proof :
  check_produce:
    ((Dal_slot_repr.Slots_history.proof * bytes option) tzresult ->
    (bytes * Cryptobox.page_proof) option ->
    (unit, tztrace) result Lwt.t) ->
  ?check_verify:
    (bytes option tzresult ->
    (bytes * Cryptobox.page_proof) option ->
    (unit, tztrace) result Lwt.t) ->
  Cryptobox.t ->
  Dal_slot_repr.Slots_history.t ->
  Dal_slot_repr.Slots_history.History_cache.t ->
  page_info:(bytes * Cryptobox.page_proof) option ->
  page_id:Dal_slot_repr.Page.t ->
  (unit, tztrace) result Lwt.t

(** Check if two page proofs are equal. *)
val eq_page_proof : Cryptobox.page_proof -> Cryptobox.page_proof -> bool

(** Helper for the case where produce_proof is expected to succeed. *)
val successful_check_produce_result :
  __LOC__:string ->
  [`Confirmed | `Unconfirmed] ->
  (Dal_slot_repr.Slots_history.proof * bytes option, tztrace) result ->
  (bytes * 'a) option ->
  (unit, tztrace) result Lwt.t

(** Helper for the case where verify_proof is expected to succeed. *)
val successful_check_verify_result :
  __LOC__:string ->
  [> `Confirmed] ->
  (bytes option, tztrace) result ->
  (bytes * 'a) option ->
  (unit, tztrace) result Lwt.t

(** Helper for the case where produce_proof is expected to fail because the slot
   is confirmed but no page information are provided. *)
val slot_confirmed_but_page_data_not_provided :
  __LOC__:string -> ('a, tztrace) result -> 'b -> unit tzresult Lwt.t

(** Helper for the case where produce_proof is expected to fail because the slot
   is not confirmed but page_info are provided. *)
val slot_not_confirmed_but_page_data_provided :
  __LOC__:string -> ('a, tztrace) result -> 'b -> unit tzresult Lwt.t

(** Helper for the case where produce_proof is expected to fail. *)
val failing_check_produce_result :
  __LOC__:string -> string -> ('a, tztrace) result -> 'b -> unit tzresult Lwt.t