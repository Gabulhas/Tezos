(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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
module Commands = Client_proto_commands

let validators_to_string l =
  String.concat ", " (List.map Account_repr.to_b58check l)

let commands : Protocol_client_context.full Tezos_clic.command list =
  let open Tezos_clic in
  let open Client_proto_args in
  let group =
    {name = "Custom_demo"; title = "Commands for protocol custom_demo"}
  in
  [
    command
      ~group
      ~desc:"Shows account balance."
      no_options
      (prefixes ["balance"]
      @@ account_param ~name:"account" ~desc:"Account b58check"
      @@ stop)
      (fun () msg cctxt ->
        Commands.get_balance cctxt msg >>=? fun balance ->
        cctxt#message "Balance: %s" (Tez_repr.to_string balance) >>= fun () ->
        return_unit);
    command
      ~group
      ~desc:"Shows if account is revealed or not."
      no_options
      (prefixes ["revealed"]
      @@ account_param ~name:"account" ~desc:"Account b58check"
      @@ stop)
      (fun () msg cctxt ->
        Commands.is_revealed cctxt msg >>=? fun is_revealed ->
        let r_string = if is_revealed then "YES" else "NO" in
        cctxt#message "Balance: %sꜩ" r_string >>= fun () -> return_unit);
    command
      ~group
      ~desc:"Shows order of validators at a given block level."
      no_options
      (prefixes ["validator_order"]
      @@ level_param ~name:"level" ~desc:"Block level"
      @@ stop)
      (fun () level cctxt ->
        Commands.validator_order_at_level cctxt level >>=? fun validators ->
        (* Assume a function that converts validators to string *)
        let validators_str = validators_to_string validators in
        cctxt#message "Validator Order: %s" validators_str >>= fun () ->
        return_unit);
    command
      ~group
      ~desc:"Shows set of current validators."
      no_options
      (prefixes ["validator_set"] @@ stop)
      (fun () cctxt ->
        Commands.validator_set cctxt >>=? fun validators ->
        let validators_str = validators_to_string validators in
        cctxt#message "Validator Set: %s" validators_str >>= fun () ->
        return_unit);
    command
      ~group
      ~desc:"Shows first validator for next block height."
      no_options
      (prefixes ["first_block_validator"]
      @@ level_param ~name:"level" ~desc:"Block level"
      @@ stop)
      (fun () level cctxt ->
        Commands.first_block_validator cctxt level >>=? fun first_validator ->
        let first_validator_str =
          match first_validator with
          | None -> "NONE"
          | Some a -> Account_repr.to_b58check a
        in
        cctxt#message "First Block Validator: %s" first_validator_str
        >>= fun () -> return_unit);
    command
      ~group
      ~desc:"Transfers Tez from Source to Destination"
      (args1 counter_arg)
      (prefixes ["transfer"]
      @@ tez_param ~name:"amount" ~desc:"Amount Tez"
      @@ prefixes ["from"]
      @@ account_param ~name:"account" ~desc:"Account b58check"
      @@ prefixes ["to"]
      @@ account_param ~name:"account" ~desc:"Account b58check"
      @@ stop)
      (fun counter amount source destination cctxt ->
        Client_keys.get_key cctxt source >>=? fun (_, src_pk, src_sk) ->
        let operation_content =
          Operation_repr.Transaction {amount; destination}
        in
        Commands.build_manager_operation_protocol_data
          cctxt
          src_pk
          src_sk
          operation_content
          counter
        >>=? fun operation -> Commands.inject_op cctxt operation);
    command
      ~group
      ~desc:"Reveals Account Public Key"
      no_options
      (prefixes ["reveal"]
      @@ account_param ~name:"account" ~desc:"Account b58check"
      @@ stop)
      (fun () account cctxt ->
        Client_keys.get_key cctxt account >>=? fun (_, src_pk, src_sk) ->
        let operation_content = Operation_repr.Reveal src_pk in
        Commands.build_manager_operation_protocol_data
          cctxt
          src_pk
          src_sk
          operation_content
          None
        >>=? fun operation -> Commands.inject_op cctxt operation);
  ]

let () =
  let f = Tezos_clic.map_command (new Protocol_client_context.wrap_full) in
  let command_list = List.map f commands in
  Client_commands.register Protocol.hash (fun _network -> command_list)
