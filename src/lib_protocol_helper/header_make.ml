module MakeHeader (Content : sig
  type t

  val encoding : t Data_encoding.t
end) (ProtocolData : sig
  type t

  val fake_protocol_data : t

  val encoding : t Data_encoding.t
end) =
struct
  type t = {shell : Block_header.shell_header; protocol_data : ProtocolData.t}

  type block_header = t

  type raw = Block_header.t

  type shell_header = Block_header.shell_header

  let raw_encoding = Block_header.encoding

  let shell_header_encoding = Block_header.shell_header_encoding

  let contents_encoding = Content.encoding

  let protocol_data_encoding = ProtocolData.encoding

  let raw {shell; protocol_data} =
    let protocol_data =
      Data_encoding.Binary.to_bytes_exn protocol_data_encoding protocol_data
    in
    {Block_header.shell; protocol_data}

  let unsigned_encoding =
    let open Data_encoding in
    merge_objs Block_header.shell_header_encoding contents_encoding

  let encoding =
    let open Data_encoding in
    def "block_header.alpha.full_header"
    @@ conv
         (fun {shell; protocol_data} -> (shell, protocol_data))
         (fun (shell, protocol_data) -> {shell; protocol_data})
         (merge_objs Block_header.shell_header_encoding protocol_data_encoding)

  let max_header_length =
    (*Change this to actual shell header fake*)
    let fake_shell =
      {
        Block_header.level = 0l;
        proto_level = 0;
        predecessor = Block_hash.zero;
        timestamp = Time.of_seconds 0L;
        validation_passes = 0;
        operations_hash = Operation_list_list_hash.zero;
        fitness = [];
        context = Context_hash.zero;
      }
    in
    Data_encoding.Binary.length
      encoding
      {shell = fake_shell; protocol_data = ProtocolData.fake_protocol_data}

  (** Header parsing entry point  *)

  let hash_raw = Block_header.hash

  let hash {shell; protocol_data} =
    Block_header.hash
      {
        shell;
        protocol_data =
          Data_encoding.Binary.to_bytes_exn protocol_data_encoding protocol_data;
      }

  let to_bytes =
    let open Data_encoding in
    Binary.to_bytes_exn encoding

  let of_bytes =
    let open Data_encoding in
    Binary.of_bytes_opt encoding

  let to_string_json header =
    Format.asprintf
      "%a"
      Data_encoding.Json.pp
      (Data_encoding.Json.construct encoding header)
end
